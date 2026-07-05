import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmtech_agridirect/services/location_service.dart';
import 'package:farmtech_agridirect/models/user_data.dart';
import 'package:farmtech_agridirect/models/cart_model.dart';

class FarmOsmScreen extends StatefulWidget {
  const FarmOsmScreen({super.key});

  @override
  State<FarmOsmScreen> createState() => _FarmOsmScreenState();
}

class _FarmOsmScreenState extends State<FarmOsmScreen> with TickerProviderStateMixin {
  MapLibreMapController? mapController;
  final LocationService locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng currentPosition = const LatLng(UserData.hqLat, UserData.hqLng);
  String currentAddress = "Fetching address...";
  bool loading = true;
  bool isMoving = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  late AnimationController _pinController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinAnimation = Tween<double>(begin: 0, end: -15).animate(curvedPinAnimation());
    initializeLocation();
  }

  CurvedAnimation curvedPinAnimation() {
    return CurvedAnimation(parent: _pinController, curve: Curves.easeOut);
  }

  Future<void> initializeLocation() async {
    bool granted = await locationService.requestPermission();
    if (!granted) {
      setState(() => loading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (position.latitude != 0 && position.longitude != 0) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
      setState(() => loading = false);
      _updateAddress(currentPosition);
    } catch (e) {
      debugPrint("Error initializing location: $e");
      setState(() => loading = false);
      _updateAddress(currentPosition);
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    String address = await locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        currentAddress = address;
      });
    }
  }

  void _onCameraIdle() {
    setState(() => isMoving = false);
    _pinController.reverse();
    _updateAddress(currentPosition);
  }

  void _confirmLocation() {
    double distance = locationService.calculateDistance(
      UserData.hqLat,
      UserData.hqLng,
      currentPosition.latitude,
      currentPosition.longitude,
    );
    
    // Check if cartModel is available globally
    try {
       cartModel.setDistance(distance);
    } catch (_) {}

    UserData.setAddress(
      address: currentAddress,
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
    );

    Navigator.pop(context, {
      'address': currentAddress,
      'lat': currentPosition.latitude,
      'lng': currentPosition.longitude,
      'distance': distance,
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await locationService.searchLocation(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    final address = result['display_name'] as String;

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16, tilt: 45),
      ),
    );

    setState(() {
      currentPosition = LatLng(lat, lng);
      currentAddress = address;
      _searchResults = [];
      _searchController.text = "";
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          loading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: currentPosition,
                    zoom: 15,
                    tilt: 45, 
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onCameraMove: (CameraPosition position) {
                    if (!isMoving) {
                      setState(() => isMoving = true);
                      _pinController.forward();
                    }
                    currentPosition = position.target;
                  },
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  styleString: "https://tiles.openfreemap.org/styles/positron", 
                ),
          
          // FLOATING SEARCH BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        suffixIcon: _isSearching 
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                            )
                          : const Icon(Icons.search_rounded, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  
                  // SMOOTH SEARCH RESULTS
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (ctx, i) {
                            final res = _searchResults[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 20),
                              ),
                              title: Text(
                                res['display_name'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D25)),
                              ),
                              onTap: () => _selectSearchResult(res),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // PIN WITH LABEL
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinAnimation.value - 24), 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                        ),
                        child: const Text(
                          "Pin Location",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 50,
                        color: Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // BOTTOM CONFIRMATION CARD
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "DELIVERY ADDRESS",
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_searching_rounded, color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isMoving ? "Updating map position..." : currentAddress,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1D25), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isMoving ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: Colors.green.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        "CONFIRM LOCATION",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MY LOCATION BUTTON
          Positioned(
            bottom: 230,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                try {
                  Position pos = await Geolocator.getCurrentPosition();
                  mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16, tilt: 45),
                    ),
                  );
                } catch (e) {
                  debugPrint("Location button error: $e");
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.my_location_rounded, color: Colors.green, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
