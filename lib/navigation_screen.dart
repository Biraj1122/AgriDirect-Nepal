import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/my_cart.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_screen.dart';

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

  final List<Map<String, dynamic>> _favouriteProducts = [];
  bool _isLoadingFavorites = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingFavorites = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      setState(() {
        _favouriteProducts.clear();
        for (var doc in snapshot.docs) {
          _favouriteProducts.add(doc.data());
        }
        _isLoadingFavorites = false;
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _toggleFavourite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final productName = product['name'] ?? product['title'];
    final docId = productName.toString().replaceAll(' ', '_').toLowerCase();

    setState(() {
      final index = _favouriteProducts.indexWhere(
        (p) => (p['name'] ?? p['title']) == productName,
      );

      if (index >= 0) {
        _favouriteProducts.removeAt(index);
      } else {
        _favouriteProducts.add(product);
      }
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(docId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set(product);
      }
    } catch (e) {
      debugPrint("Error toggling favorite in Firestore: $e");
    }
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        userName: widget.userName,
        onCartTap: () => changeTab(2),
        onFavoritesTap: () => changeTab(4),
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

      const OrderHistoryScreen(),

      ProfileScreen(
        userName: widget.userName,
        onBackToHome: () => changeTab(0),
        favouriteProducts: _favouriteProducts,
        allProducts: const [],
        favouriteNames: _favouriteProducts
            .map((p) => (p['name'] ?? p['title'] ?? 'No Name').toString())
            .toSet(),
        onFavouriteToggle: _toggleFavourite,
      ),
    ];
  }

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.12)
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