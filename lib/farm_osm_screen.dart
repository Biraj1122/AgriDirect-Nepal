import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class FarmOsmScreen extends StatefulWidget {
  const FarmOsmScreen({super.key});

  @override
  State<FarmOsmScreen> createState() => _FarmOsmScreenState();
}

class _FarmOsmScreenState extends State<FarmOsmScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? currentPosition;
  LatLng? selectedPosition;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// GET CURRENT LOCATION
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      selectedPosition = currentPosition;
      isLoading = false;
    });
  }

  /// 🔥 FIXED: REAL ADDRESS CONVERSION
  Future<void> _confirmLocation() async {
    if (selectedPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        selectedPosition!.latitude,
        selectedPosition!.longitude,
      );

      final place = placemarks.first;

      final String fullAddress =
          "${place.name ?? ''}, "
          "${place.subLocality ?? ''}, "
          "${place.locality ?? ''}, "
          "${place.country ?? ''}";

      Navigator.pop(context, {
        "address": fullAddress.trim(),
        "lat": selectedPosition!.latitude,
        "lng": selectedPosition!.longitude,
      });
    } catch (e) {
      // fallback if geocoding fails
      Navigator.pop(context, {
        "address": "Selected Location",
        "lat": selectedPosition!.latitude,
        "lng": selectedPosition!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Address"),
        backgroundColor: Colors.green,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          /// GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,

            onMapCreated: (controller) {
              _controller.complete(controller);
            },

            onTap: (LatLng position) {
              setState(() {
                selectedPosition = position;
              });
            },

            markers: selectedPosition == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId("selected"),
                position: selectedPosition!,
                draggable: true,
                onDragEnd: (newPos) {
                  setState(() {
                    selectedPosition = newPos;
                  });
                },
              )
            },
          ),

          /// CONFIRM BUTTON
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
              ),
              child: const Text(
                "Confirm Location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}