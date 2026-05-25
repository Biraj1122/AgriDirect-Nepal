import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String _apiKey = "AIzaSyCiJof1JmzJHhIUSF5SD6iywrY6IFcVQr8";

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
    if (kIsWeb) {
      // Use Google Maps Geocoding API for Web
      try {
        final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            return data['results'][0]['formatted_address'];
          }
        }
      } catch (e) {
        debugPrint("Web Geocoding Error: $e");
      }
      return "Location selected";
    }

    // Standard geocoding for Mobile
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.name}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      return "Unknown Address";
    }
    return "Unknown Address";
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // in km
  }
}
