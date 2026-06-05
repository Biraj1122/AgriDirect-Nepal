import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    // Return a basic fallback immediately so we don't show "Fetching..." forever
    String fallback = "Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})";
    
    try {
      // Nominatim requires a User-Agent. Adding a timeout for reliability.
      final url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1";
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'AgriDirect-Nepal/1.0'
      }).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
         final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }

    if (kIsWeb) return fallback;

    // Standard geocoding fallback for Mobile (can be more reliable offline)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.name ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }
    } catch (e) {
      return fallback;
    }
    return fallback;
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // in km
  }
}
