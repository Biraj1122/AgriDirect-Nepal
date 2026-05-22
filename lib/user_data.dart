class UserData {
  static String? defaultAddress;
  static double? defaultLat;
  static double? defaultLng;

  /// ✅ Save selected address globally
  static void setAddress({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    defaultAddress = address;
    defaultLat = latitude;
    defaultLng = longitude;
  }

  /// ✅ Clear address (optional use for logout/reset)
  static void clearAddress() {
    defaultAddress = null;
    defaultLat = null;
    defaultLng = null;
  }

  /// ✅ Check if address exists
  static bool get hasAddress =>
      defaultAddress != null &&
          defaultLat != null &&
          defaultLng != null;
}