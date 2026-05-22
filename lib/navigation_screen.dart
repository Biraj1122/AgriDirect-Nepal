import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/my_cart.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
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

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onCartTap: () {
          setState(() {
            currentIndex = 2;
          });
        },
        onCategoryTap: (String category) {
          setState(() {
            selectedCategory = category.isEmpty ? "All" : category;
            currentIndex = 1;
          });
        },
      ),

      CategoriesScreen(
        key: ValueKey(selectedCategory),
        initialCategory: selectedCategory,
      ),

      const MyCartScreen(),
      const OrderScreen(),

      ProfileScreen(
        userName: widget.userName,
        favouriteProducts: const [],
        allProducts: const [],
        favouriteNames: const {},
        onFavouriteToggle: null,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      // ✅ MODERN BOTTOM NAV BAR
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
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                fontSize: 11,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}