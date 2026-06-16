import 'package:farmtech_agridirect/user_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/orders_screen.dart';
import 'cart_model.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double? selectedLat;
  final double? selectedLng;

  const PaymentMethodsScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.selectedLat,
    this.selectedLng,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isProcessing = false;
  String _selectedMethod = 'COD'; // Default to Cash on Delivery

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Scan to Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=AgriDirectPay",
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2, size: 200),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Amount: Rs. ", style: TextStyle(fontSize: 16)),
              Text("Rs. ${widget.total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("I have Paid", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String? orderId;
      if (user != null) {
        // Fetch user phone from Firestore profile
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userPhone = userDoc.data()?['phone'] ?? "No Number";

        // Save Order to Firestore
        final docRef = await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'userName': user.displayName ?? "User",
          'userPhone': userPhone,
          'subtotal': widget.subtotal,
          'deliveryFee': widget.deliveryFee,
          'total': widget.total,
          'lat': widget.selectedLat ?? UserData.defaultLat,
          'lng': widget.selectedLng ?? UserData.defaultLng,
          'deliveryAddress': UserData.defaultAddress ?? 'No Address Data',
          'status': 'Processing',
          'paymentMethod': _selectedMethod,
          'paymentStatus': _selectedMethod == 'COD' ? 'Pending' : 'Paid',
          'createdAt': FieldValue.serverTimestamp(),
          'items': cartModel.items.map((item) => {
            'title': item.title,
            'price': item.price,
            'image': item.image,
            'unit': item.unit,
          }).toList(),
          'itemsSummary': cartModel.items.map((e) => e.title).join(", "),
        });
        orderId = docRef.id;
      }

      if (mounted) {
        cartModel.clear();
        _success(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _success(String? orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 60),
              const SizedBox(height: 15),
              const Text(
                "Order Placed Successfully",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(orderId: orderId),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Track Order", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box("Total Payable", widget.total, highlight: true),

            const SizedBox(height: 25),
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            _methodTile("COD", "Cash On Delivery", Icons.payments),
            _methodTile("QR", "QR Payment", Icons.qr_code_scanner),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () {
                  if (_selectedMethod == 'QR') {
                    _showQRCode();
                  } else {
                    _processPayment();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_selectedMethod == 'COD' ? "Confirm Order" : "Pay with QR", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_selectedMethod == 'QR')
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: TextButton(
                  onPressed: _processPayment,
                  child: const Center(child: Text("Already Paid? Confirm Order", style: TextStyle(color: Colors.green))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String value, String title, IconData icon) {
    bool isSel = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? Colors.green : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.green : Colors.grey),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSel) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, double value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "Rs. ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}