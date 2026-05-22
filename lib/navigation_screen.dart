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

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onCartTap: () => setState(() => currentIndex = 2),
        onCategoryTap: (cat) {
          setState(() {
            selectedCategory = cat.isEmpty ? "All" : cat;
            currentIndex = 1;
          });
        },
      ),

      CategoriesScreen(
        key: ValueKey(selectedCategory),
        initialCategory: selectedCategory,
      ),

      const MyCartScreen(), // ✅ FIXED HERE

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Cat"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}