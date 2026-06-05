import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';
import 'screens/my_cart.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'my_favourites.dart';

class NavigationScreen extends StatefulWidget {
  final String userName;

  const NavigationScreen({
    super.key,
    required this.userName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentIndex = 0;
  String selectedCategory = "All";

  List<Map<String, dynamic>> _favouriteProducts = [];
  StreamSubscription? _favSubscription;

  @override
  void initState() {
    super.initState();
    _listenToFavorites();
  }

  void _listenToFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _favouriteProducts = snapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    super.dispose();
  }

  void _toggleFavourite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Use injected docId if available, fallback to name/title
    final String favId = (product['docId'] ?? product['name'] ?? product['title'] ?? '').toString().trim();
    if (favId.isEmpty) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(favId);

    try {
      final doc = await favRef.get();
      if (doc.exists) {
        await favRef.delete();
      } else {
        // Convert to Firestore-friendly map (Colors -> int)
        final Map<String, dynamic> favData = Map.from(product);
        if (favData['badgeColor'] is Color) {
          favData['badgeColor'] = (favData['badgeColor'] as Color).value;
        }
        await favRef.set(favData);
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        userName: widget.userName,
        onCartTap: () => changeTab(2),
        onFavoritesTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyFavouritesScreen(
                onFavouriteToggle: _toggleFavourite,
              ),
            ),
          );
        },
        onCategoryTap: (String category) {
          setState(() {
            selectedCategory = category.isEmpty ? "All" : category;
            currentIndex = 1;
          });
        },
        favouriteProducts: _favouriteProducts,
        onFavouriteToggle: _toggleFavourite,
      ),

      CategoriesScreen(
        key: ValueKey(selectedCategory),
        initialCategory: selectedCategory,
        externalFavouriteProducts: _favouriteProducts,
        onExternalFavouriteToggle: _toggleFavourite,
        onBackToHome: () => changeTab(0),
      ),

      CartScreen(
        onBackTap: () => changeTab(0),
      ),

      OrderScreen(
        onBackToHome: () => changeTab(0),
      ),

      ProfileScreen(
        userName: widget.userName,
        onBackToHome: () => changeTab(0),
        favouriteProducts: _favouriteProducts,
        allProducts: const [],
        favouriteNames:
        _favouriteProducts.map((p) => (p['name'] ?? p['title'] ?? '').toString()).toSet(),
        onFavouriteToggle: _toggleFavourite,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_rounded, "Home", 0),
              navItem(Icons.grid_view_rounded, "Categories", 1),
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

    return GestureDetector(
      onTap: () => changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.green : Colors.grey,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}