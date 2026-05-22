import 'package:flutter/material.dart';
import '../farm_osm_screen.dart';
import 'dart:math';

class OrderItemModel {
  final String image;
  final String title;
  final String unit;
  final double price;
  int qty;

  OrderItemModel({
    required this.image,
    required this.title,
    required this.unit,
    required this.price,
    required this.qty,
  });
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // STORE LOCATION (fixed)
  final double storeLat = 27.7000;
  final double storeLng = 85.3000;

  // USER LOCATION
  double? userLat;
  double? userLng;

  String _displayAddress = "Select delivery location";

  // CART (dynamic now)
  List<OrderItemModel> cartItems = [
    OrderItemModel(
      image: "assets/images/tomatoes.png",
      title: "Fresh Tomatoes",
      unit: "1 kg",
      price: 120,
      qty: 2,
    ),
    OrderItemModel(
      image: "assets/images/potato png.png",
      title: "Organic Potatoes",
      unit: "1 kg",
      price: 80,
      qty: 1,
    ),
    OrderItemModel(
      image: "assets/images/milk png.png",
      title: "Farm Fresh Milk",
      unit: "1 L",
      price: 110,
      qty: 1,
    ),
  ];

  /// MAP PICKER
  Future<void> _selectNewLocation() async {
    final Map<String, dynamic>? selectedData =
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmOsmScreen(),
      ),
    );

    if (selectedData != null) {
      setState(() {
        _displayAddress = selectedData['address'] ?? _displayAddress;
        userLat = selectedData['lat'];
        userLng = selectedData['lng'];
      });
    }
  }

  /// DISTANCE CALC (Haversine formula)
  double calculateDistanceKm() {
    if (userLat == null || userLng == null) return 0;

    const earthRadius = 6371;

    double dLat = _degToRad(userLat! - storeLat);
    double dLng = _degToRad(userLng! - storeLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(storeLat)) *
            cos(_degToRad(userLat!)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  /// SUBTOTAL
  double get subtotal {
    return cartItems.fold(
      0,
          (sum, item) => sum + (item.price * item.qty),
    );
  }

  /// DELIVERY FEE (Rs 15/km)
  double get deliveryFee {
    return calculateDistanceKm() * 15;
  }


  double get total {
    return subtotal + deliveryFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Order",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ADDRESS
            const Text(
              "Delivery Address",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: _selectNewLocation,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_displayAddress)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// ORDER ITEMS (REAL DYNAMIC)
            const Text(
              "Order Items",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 12),

            ...cartItems.map((item) => orderItem(item)),

            const SizedBox(height: 25),

            /// SUMMARY (REAL)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  summaryRow("Subtotal", "Rs ${subtotal.toStringAsFixed(0)}"),
                  const SizedBox(height: 10),
                  summaryRow(
                    "Delivery Fee",
                    "Rs ${deliveryFee.toStringAsFixed(0)} (${calculateDistanceKm().toStringAsFixed(2)} km)",
                  ),
                  const Divider(height: 30),
                  summaryRow("Total", "Rs ${total.toStringAsFixed(0)}"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Place Order"),
            ),
          ],
        ),
      ),
    );
  }

  Widget orderItem(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Image.asset(item.image, height: 60, width: 60),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item.unit),
                Text("Rs ${item.price}",
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (item.qty > 1) item.qty--;
                  });
                },
                icon: const Icon(Icons.remove),
              ),
              Text("${item.qty}"),
              IconButton(
                onPressed: () {
                  setState(() {
                    item.qty++;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}