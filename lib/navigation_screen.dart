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
  int notificationCount = 3; // Active notification badge count state variable

  // Dynamic list constructor to pass real-time notification states
  List<Widget> get screens => [
    HomeScreen(onCartTap: () => changeTab(2)),
    CategoriesScreen(
      allProducts: const [],
      favouriteNames: const {},
      onFavouriteToggle: (product) {},
    ),
    const CartScreen(),
    const OrderScreen(),
    ProfileScreen(
      userName: widget.userName,
      allProducts: const [],
      favouriteNames: const {},
      favouriteProducts: const [],
      onFavouriteToggle: (product) {},
    ),
  ];

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
              navItem(
                icon: Icons.home_rounded,
                label: "Home",
                index: 0,
              ),
              navItem(
                icon: Icons.grid_view_rounded,
                label: "Categories",
                index: 1,
              ),
              navItem(
                icon: Icons.shopping_cart_rounded,
                label: "Cart",
                index: 2,
              ),
              navItem(
                icon: Icons.receipt_long_rounded,
                label: "Orders",
                index: 3,
              ),

              // PROFILE NAVIGATION ITEM EQUIPPED WITH LIVE BADGE OVERLAY
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => changeTab(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: currentIndex == 4
                        ? const Color.fromARGB(30, 76, 175, 80)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none, // Fixed typo from ':' to '.'
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: currentIndex == 4 ? Colors.green : Colors.grey,
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 12,
                          color: currentIndex == 4 ? Colors.green : Colors.grey,
                          fontWeight: currentIndex == 4
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
    );
  }
}