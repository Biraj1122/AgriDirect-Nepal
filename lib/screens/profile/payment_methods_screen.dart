import 'package:farmtech_agridirect/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../orders/orders_screen.dart';
import '../home/navigation_screen.dart';
import '../../models/cart_model.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double? selectedLat;
  final double? selectedLng;
  final bool isCheckout;

  const PaymentMethodsScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.selectedLat,
    this.selectedLng,
    this.isCheckout = false,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isProcessing = false;
  final String _selectedMethod = 'COD'; // Fixed to Cash on Delivery

  Future<void> _processPayment() async {
    // Show Confirmation Dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to place this order with Cash on Delivery?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Yes, Place Order", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    // ... rest of the logic remains the same
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? orderId;
      if (user != null) {
        // Fetch user phone from Firestore profile
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userPhone = userDoc.data()?['phone'] ?? "No Number";

        final customerLat = widget.selectedLat ?? UserData.defaultLat;
        final customerLng = widget.selectedLng ?? UserData.defaultLng;

        // Calculate revenue sharing (20% cut for Admin)
        final adminRevenue = (widget.subtotal * 0.20) + (widget.deliveryFee * 0.20);
        final farmerRevenue = widget.subtotal * 0.80;
        final deliveryRevenue = widget.deliveryFee * 0.80;

        // Save Order to Firestore
        final docRef = await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'userName': user.displayName ?? "User",
          'userPhone': userPhone,
          'farmerUid': null, 
          'deliveryId': null, 
          'farmName': "Waiting for assignment",
          'subtotal': widget.subtotal,
          'deliveryFee': widget.deliveryFee,
          'total': widget.total,
          'adminRevenue': adminRevenue,
          'farmerRevenue': farmerRevenue,
          'deliveryRevenue': deliveryRevenue,
          'lat': customerLat ?? UserData.defaultLat,
          'lng': customerLng ?? UserData.defaultLng,
          'customerLat': customerLat ?? UserData.defaultLat,
          'customerLng': customerLng ?? UserData.defaultLng,
          'deliveryAddress': UserData.defaultAddress ?? 'No Address Data',
          'status': 'Pending Farmer', 
          'paymentMethod': _selectedMethod,
          'paymentStatus': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          'items': cartModel.items.map((item) => {
            'title': item.product.title,
            'price': item.product.price,
            'image': item.product.image,
            'unit': item.product.unit,
            'quantity': item.quantity,
          }).toList(),
          'itemsSummary': cartModel.items.map((e) => "${e.quantity}x ${e.product.title}").join(", "),
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
                  final user = FirebaseAuth.instance.currentUser;
                  // First, go to Home (NavigationScreen) and clear stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        userName: user?.displayName ?? "User",
                        initialTabIndex: 0, // Go to home first
                      ),
                    ),
                    (route) => false,
                  );
                  // Then push the Order Tracking screen on top
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(orderId: orderId),
                    ),
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
        title: const Text("Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            _methodTile("Cash On Delivery", Icons.payments),
            
            const SizedBox(height: 15),
            
            // Coming Soon Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Other payment methods (eSewa, Khalti) coming soon!",
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (widget.isCheckout)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm Order", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }


}
