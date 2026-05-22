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
  int notificationCount = 3;
  String _selectedCategory = 'All'; // ← CHANGED: added this line

  final List<Map<String, dynamic>> _emptyProducts = [];
  final Set<String> _emptyFavNames = {};

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void handleCategoryTap(String category) {
    setState(() {
      _selectedCategory = category.isEmpty ? 'All' : category; // ← CHANGED
      currentIndex = 1; // ← CHANGED: was 0, now goes to Categories tab
    });
  }

  List<Widget> get screens => [
    HomeScreen(
      onCartTap: () => changeTab(2),
      onCategoryTap: handleCategoryTap,
    ),
    CategoriesScreen(
      key: ValueKey(_selectedCategory),
      initialCategory: _selectedCategory,
    ),
    const CartScreen(),
    const OrderScreen(),
    ProfileScreen(
      userName: widget.userName,
      favouriteProducts: const [],
      allProducts: _emptyProducts,
      favouriteNames: _emptyFavNames,
      onFavouriteToggle: (product) {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 82,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(15, 0, 0, 0),
              blurRadius: 15,
              offset: Offset(0, -2),
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
              InkWell(
                onTap: () => changeTab(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 26,
                      color: currentIndex == 4 ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 12,
                        color: currentIndex == 4 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}