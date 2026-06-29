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
    String fallback = "Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})";
    
    try {
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
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty) return [];
    try {
      final url = "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1";
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'AgriDirect-Nepal/1.0'
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lng': double.parse(item['lon']),
        }).toList();
      }
    } catch (e) {
      debugPrint("Search Location Error: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> getRouteData(double startLat, double startLng, double endLat, double endLng) async {
    try {
      final url = "https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          return {
            'points': coordinates.map((c) => [c[1] as double, c[0] as double]).toList(),
            'distance': route['distance'] as num, // in meters
            'duration': route['duration'] as num, // in seconds
          };
        }
      }
    } catch (e) {
      debugPrint("OSRM Routing Error: $e");
    }
    return {
      'points': [[startLat, startLng], [endLat, endLng]],
      'distance': Geolocator.distanceBetween(startLat, startLng, endLat, endLng),
      'duration': 0,
    };
  }
}