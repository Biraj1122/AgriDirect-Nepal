import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class UserData {
  static String? defaultAddress;
  static double? defaultLat;
  static double? defaultLng;

  // AgriDirect HQ (Kathmandu Center)
  static const double hqLat = 27.7172;
  static const double hqLng = 85.3240;

  /// Initialize from storage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      defaultAddress = prefs.getString('defaultAddress');
      defaultLat = prefs.getDouble('defaultLat');
      defaultLng = prefs.getDouble('defaultLng');
    } catch (e) {
      debugPrint("UserData Init Error: $e");
    }
  }

  /// Calculate distance to HQ
  static double get distanceToHq {
    if (defaultLat == null || defaultLng == null) return 0;
    return Geolocator.distanceBetween(hqLat, hqLng, defaultLat!, defaultLng!) / 1000;
  }

  /// Save selected address globally and persist it
  static void setAddress({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    defaultAddress = address;
    defaultLat = latitude;
    defaultLng = longitude;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultAddress', address);
    await prefs.setDouble('defaultLat', latitude);
    await prefs.setDouble('defaultLng', longitude);
  }

  /// Clear address
  static void clearAddress() async {
    defaultAddress = null;
    defaultLat = null;
    defaultLng = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('defaultAddress');
    await prefs.remove('defaultLat');
    await prefs.remove('defaultLng');
  }

  /// Check if address exists
  static bool get hasAddress =>
      defaultAddress != null &&
          defaultLat != null &&
          defaultLng != null;
}
