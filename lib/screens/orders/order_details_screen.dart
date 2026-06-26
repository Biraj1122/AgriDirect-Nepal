import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final date = (order['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    final status = order['status']?.toString() ?? 'Pending';
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final riderName = order['deliveryName'] ?? "Not assigned";
    final address = order['deliveryAddress'] ?? "No address";

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _infoRow("Status", status, color: Colors.green, bold: true),
                  const Divider(height: 30),
                  _infoRow("Order Date", DateFormat('MMM d, yyyy • hh:mm a').format(date)),
                  const SizedBox(height: 12),
                  _infoRow("Rider", riderName),
                  const SizedBox(height: 12),
                  _infoRow("Delivery Address", address, isSmall: true),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Items Ordered", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Items List
            ...items.map((item) => _buildItemTile(item as Map<String, dynamic>)),

            const SizedBox(height: 25),
            const Text("Payment Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Billing Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow("Subtotal", "Rs. ${subtotal.toStringAsFixed(0)}"),
                  const SizedBox(height: 12),
                  _infoRow("Delivery Fee", "Rs. ${deliveryFee.toStringAsFixed(0)}"),
                  const Divider(height: 30),
                  _infoRow("Total Amount", "Rs. ${total.toStringAsFixed(0)}", color: Colors.green, bold: true, fontSize: 18),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color, bool bold = false, double fontSize = 14, bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: isSmall ? 12 : fontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xffF7F8F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildProductImage(item['image']?.toString() ?? ''),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${item['unit'] ?? ''} x ${item['quantity'] ?? 1}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text("Rs. ${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.image_not_supported);
      }
    } else {
      String assetPath = imagePath;
      if (assetPath.isNotEmpty && !assetPath.startsWith('assets/')) {
        assetPath = 'assets/images/$imagePath';
      }
      return Image.asset(assetPath.isEmpty ? 'assets/images/logo.png' : assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
    }
  }
}