import 'package:flutter/material.dart';
import '../product.dart';
import 'product_detail_screen.dart';
import '../notifications_screen.dart';
import 'orders_screen.dart';           // ← Added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final VoidCallback onCartTap;
  final VoidCallback onFavoritesTap;
  final Function(String) onCategoryTap;
  final List<Map<String, dynamic>> favouriteProducts;
  final Function(Map<String, dynamic>) onFavouriteToggle;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.onCartTap,
    required this.onFavoritesTap,
    required this.onCategoryTap,
    required this.favouriteProducts,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER (Slightly Modified - Added Active Order Notification)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $userName",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text("Good morning", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  /// NOTIFICATION & FAVOURITE BUTTONS
                  Row(
                    children: [
                      IconButton(
                        onPressed: onFavoritesTap,
                        icon: const Icon(Icons.favorite_border, color: Colors.red),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                            icon: const Icon(Icons.notifications_none),
                          ),
                          // Small red dot if active order exists
                          StreamBuilder<QuerySnapshot>(
                            stream: user != null
                                ? FirebaseFirestore.instance
                                .collection('orders')
                                .where('userId', isEqualTo: user.uid)
                                .where('status', whereIn: ['Picked Up', 'On the way', 'Arrived'])
                                .snapshots()
                                : null,
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                return Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(" ", style: TextStyle(fontSize: 10)),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              /// ✅ NEW: Active Order Status Card (Minimal & Clean)
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', whereIn: ['Picked Up', 'On the way', 'Arrived'])
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final order = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final status = order['status'] ?? 'Pending';
                    final orderId = snapshot.data!.docs.first.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderScreen(
                              orderId: orderId,
                              onBackToHome: () {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.green, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Your Order is Moving!", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    _getStatusMessage(status),
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 25),

              // ... Rest of your original code (Categories, Banner, Products) remains 100% same
              /// CATEGORY TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  TextButton(
                    onPressed: () => onCategoryTap(""),
                    child: const Text("See all", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),

              // ... (All your category list, banner, product grid code stays exactly same)
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    categoryItem(context, Icons.eco_outlined, "Vegetables"),
                    categoryItem(context, Icons.apple_outlined, "Fruits"),
                    categoryItem(context, Icons.local_drink_outlined, "Dairy"),
                    categoryItem(context, Icons.grass, "Herbs"),
                    categoryItem(context, Icons.energy_savings_leaf, "Organic"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Banner and Product Grid (unchanged)
              // ... paste your original banner and GridView here ...
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Picked Up':
        return "Rider picked up from farmer";
      case 'On the way':
        return "Rider is on the way to you";
      case 'Arrived':
        return "Order almost delivered!";
      default:
        return "Order in progress";
    }
  }
  // Add this method inside HomeScreen class
  Widget categoryItem(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () => onCategoryTap(title),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.green, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}