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

class _FarmOsmScreenState extends State<FarmOsmScreen> {
  MapLibreMapController? mapController;
  final LocationService locationService = LocationService();
  
  LatLng currentPosition = const LatLng(UserData.hqLat, UserData.hqLng);
  String currentAddress = "Fetching address...";
  bool loading = true;
  bool isMoving = false;

  @override
  void initState() {
    super.initState();
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
      // Only update if we got a valid non-zero position
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
      _updateAddress(currentPosition); // Use default HQ position
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    String address = await locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    setState(() {
      currentAddress = address;
    });
  }

  void _onCameraIdle() {
    setState(() => isMoving = false);
    _updateAddress(currentPosition);
  }

  void _confirmLocation() {
    double distance = locationService.calculateDistance(
      UserData.hqLat,
      UserData.hqLng,
      currentPosition.latitude,
      currentPosition.longitude,
    );
    
    // Update delivery fee distance
    cartModel.setDistance(distance);

    // Persist address globally
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          loading
              ? const Center(child: CircularProgressIndicator())
              : MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: currentPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onCameraMove: (CameraPosition position) {
                    setState(() {
                      isMoving = true;
                      currentPosition = position.target;
                    });
                  },
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  styleString: "https://tiles.openfreemap.org/styles/liberty",
                ),
          
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on,
                size: 45,
                color: isMoving ? Colors.green.withValues(alpha: 0.7) : Colors.green,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Set Delivery Location",
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentAddress,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isMoving ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 220,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () async {
                try {
                  Position pos = await Geolocator.getCurrentPosition();
                  mapController?.animateCamera(
                    CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
                  );
                } catch (e) {
                  debugPrint("Error getting location: $e");
                }
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
