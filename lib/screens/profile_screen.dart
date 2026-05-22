import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../my_favourites.dart';
import 'my_addresses_screen.dart';
import '../notifications_screen.dart';
import '../payment_methods_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;

  final List<Map<String, dynamic>> favouriteProducts;
  final List<Map<String, dynamic>> allProducts;
  final Set<String> favouriteNames;
  final Function(Map<String, dynamic>)? onFavouriteToggle;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.favouriteProducts = const [],
    this.allProducts = const [],
    this.favouriteNames = const {},
    this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xffE8F5E9),
              child: Stack(
                children: [
                  Positioned(
                    top: 50,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 25,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          child: Icon(Icons.person, size: 50),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text("+977 9812345678"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// MENU
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  menuItem(
                    Icons.location_on_outlined,
                    "My Addresses",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAddressesScreen(),
                        ),
                      );
                    },
                  ),

                  menuItem(
                    Icons.payment_outlined,
                    "Payment Methods",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentMethodsScreen(
                            subtotal: 0,
                            deliveryFee: 0,
                            total: 0,
                          ),
                        ),
                      );
                    },
                  ),

                  menuItem(
                    Icons.favorite_border,
                    "My Favorites",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyFavouritesScreen(
                            favouriteProducts: favouriteProducts,
                            onFavouriteToggle:
                            onFavouriteToggle ?? (item) {},
                          ),
                        ),
                      );
                    },
                  ),

                  /// 🔔 FIXED NOTIFICATIONS BUTTON
                  menuItem(
                    Icons.notifications,
                    "Notifications",
                    badgeText: "3",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  menuItem(
                    Icons.help_outline,
                    "Help & Support",
                    onTap: () {},
                  ),

                  menuItem(
                    Icons.info_outline,
                    "About Us",
                    isLast: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// LOGOUT
            GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(
      IconData icon,
      String title, {
        VoidCallback? onTap,
        bool isLast = false,
        String? badgeText,
      }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badgeText),
                ),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}