import 'package:flutter/material.dart';
import 'farm_osm_screen.dart';
import 'payment_methods_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  String _savedAddress = "Baneshwor, Kathmandu, Nepal";

  // Captures picked coordinates and forwards them to the dynamic distance matrix layer
  Future<void> _trackOrUpdateLocation() async {
    final Map<String, dynamic>? selectedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmOsmScreen(),
      ),
    );

    if (selectedData != null && selectedData['address'] != null) {
      setState(() {
        _savedAddress = selectedData['address'];
      });

      // Automatically route straight to the active payment calculator panel using your newly captured coordinates
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodsScreen(
            subtotal: 430.0, // Example context amount parameters
            isCheckoutMode: true,
            selectedLat: selectedData['lat'] ?? 27.7172,
            selectedLng: selectedData['lng'] ?? 85.3240,
          ),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Addresses",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xffEEF5E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home, color: Colors.green),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Home Address",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _savedAddress,
                    style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  ),
                  const Divider(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _trackOrUpdateLocation,
                      icon: const Icon(Icons.map_outlined, color: Colors.white),
                      label: const Text(
                        "Track Your Order",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}