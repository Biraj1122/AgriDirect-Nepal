import 'package:flutter/material.dart';
import '../farm_osm_screen.dart';
import '../user_data.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  String _savedAddress = "Select your address";

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();

    if (UserData.defaultAddress != null) {
      _savedAddress = UserData.defaultAddress!;
      _lat = UserData.defaultLat;
      _lng = UserData.defaultLng;
    }
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result == null || result['address'] == null) return;

    final String address = result['address'].toString();
    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();

    setState(() {
      _savedAddress = address;
      _lat = lat;
      _lng = lng;
    });

    if (lat != null && lng != null) {
      UserData.setAddress(
        address: address,
        latitude: lat,
        longitude: lng,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Address",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.home, color: Colors.green),
                      SizedBox(width: 10),
                      Text("Home Address",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_savedAddress),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickAddress,
                      icon: const Icon(Icons.map),
                      label: const Text("Select Address"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (UserData.hasAddress)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      UserData.clearAddress();
                      _savedAddress = "Select your address";
                      _lat = null;
                      _lng = null;
                    });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Remove Address", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}