import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'user_data.dart';
import 'cart_model.dart';

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
    _pinAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeOut),
    );
    initializeLocation();
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
    
    cartModel.setDistance(distance);

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
                    tilt: 45, // 3D feel
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
                  styleString: "https://tiles.openfreemap.org/styles/positron", // Clean modern style
                ),
          
          // MODERN SEARCH BAR (FLOATING)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        suffixIcon: _isSearching 
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                            )
                          : const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  
                  // SEARCH RESULTS
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final res = _searchResults[i];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Colors.green),
                            title: Text(
                              res['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectSearchResult(res),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ANIMATED PIN IN CENTER
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinAnimation.value - 20), // -20 to center the tip
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Pin Location",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        size: 45,
                        color: Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // BOTTOM ADDRESS CARD
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Pathao style round card
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "DELIVERY ADDRESS",
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.green, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMoving ? "Moving map..." : currentAddress,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isMoving ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "CONFIRM LOCATION",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MY LOCATION BUTTON (Pathao style)
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
                  debugPrint("Error getting location: $e");
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
