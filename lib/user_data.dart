class UserData {
  static String? defaultAddress;
  static double? defaultLat;
  static double? defaultLng;

  static List<Map<String, dynamic>> savedAddresses = [];


  static void setDefaultAddress({
    required String address,
    required double lat,
    required double lng,
  }) {
    defaultAddress = address;
    defaultLat = lat;
    defaultLng = lng;

    savedAddresses.add({
      "address": address,
      "lat": lat,
      "lng": lng,
    });
  }


  static void setAddress({
    required String address,
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) return;

    setDefaultAddress(
      address: address,
      lat: latitude,
      lng: longitude,
    );
  }


  static bool get hasAddress => defaultAddress != null;
}