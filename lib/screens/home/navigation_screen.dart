import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/screens/home/home_screen.dart';
import 'package:farmtech_agridirect/screens/my_cart.dart';
import 'package:farmtech_agridirect/screens/shop/categories_screen.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';
import 'package:farmtech_agridirect/screens/profile/profile_screen.dart';
import 'package:farmtech_agridirect/viewmodels/shop_viewmodel.dart';
import '../profile/edit_profile_screen.dart';
import '../misc/farmer_screen.dart';
import '../delivery_person_screen.dart';
import '../auth/login_screen.dart';

class NavigationScreen extends StatefulWidget {
  final String userName;
  final int initialTabIndex;

  const NavigationScreen({
    super.key,
    required this.userName,
    this.initialTabIndex = 0,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const Color primaryTeal = Color(0xFF1D9E75);
  
  late int currentIndex;
  bool _isCheckingRole = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialTabIndex;
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logout();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));
          
      final role = doc.data()?['role'];

      if (mounted) {
        if (role != 'Customer' && role != null && role != 'Admin') {
          final profileImg = doc.data()?['profileImageUrl'];
          if (profileImg == null || profileImg.toString().isEmpty) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => EditProfileScreen(
                currentName: doc.data()?['fullName'] ?? user.displayName ?? "Partner",
                currentPhone: doc.data()?['phone'] ?? "Not set",
                mandatoryPhoto: true,
              ))
            );
            return;
          }

          Widget target;
          if (role == 'Farmer') target = const FarmerScreen();
          else if (role == 'Delivery Person') target = const DeliveryPersonScreen();
          else {
            setState(() => _isCheckingRole = false);
            return;
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
          return;
        }
        setState(() => _isCheckingRole = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingRole = false);
    }
  }

  void _logout() {
    if (mounted) {
      FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
    if (index == 0 || index == 3 || index == 4) {
      _markNotificationsAsRead();
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('notifications')
          .where('isRead', isEqualTo: false).get();

      if (query.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryTeal),
              SizedBox(height: 15),
              Text("Securing session...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final vm = context.read<ShopViewModel>();

    final List<Widget> screens = [
      HomeScreen(
        userName: widget.userName,
        onCartTap: () => changeTab(2),
        onFavoritesTap: () => changeTab(1), // Open catalog for now or create specific favorites screen
        onCategoryTap: (String category) {
          vm.setSelectedCategory(category);
          changeTab(1);
        },
      ),
      const CategoriesScreen(),
      CartScreen(onBackTap: () => changeTab(0)),
      OrderScreen(onBackToHome: () => changeTab(0)),
      ProfileScreen(
        userName: widget.userName,
        onBackToHome: () => changeTab(0),
        favouriteProducts: const [], // Handled by ViewModel now
        allProducts: const [],
        favouriteNames: const {},
        onFavouriteToggle: (_) {},
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: screens[currentIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_rounded, "Home", 0),
              navItem(Icons.grid_view_rounded, "Catalog", 1),
              navItem(Icons.shopping_cart_rounded, "Cart", 2),
              navItem(Icons.receipt_long_rounded, "Orders", 3),
              navItem(Icons.person_rounded, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: isSelected ? primaryTeal : Colors.grey.shade400),
                if (!isSelected && (index == 0 || index == 3 || index == 4) && user != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users').doc(user.uid).collection('notifications')
                        .where('isRead', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return Positioned(
                          right: -4, top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text("${snapshot.data!.docs.length}", style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: primaryTeal, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}
