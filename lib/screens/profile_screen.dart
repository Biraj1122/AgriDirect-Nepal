import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../help_support.dart';
import 'about_us.dart';
import '../login_screen.dart';
import '../my_favourites.dart';
import 'my_addresses_screen.dart';
import 'order_history_screen.dart';
import '../notifications_screen.dart';
import '../payment_methods_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onBackToHome;

  final List<Map<String, dynamic>> favouriteProducts;
  final List<Map<String, dynamic>> allProducts;
  final Set<String> favouriteNames;
  final Function(Map<String, dynamic>)? onFavouriteToggle;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.onBackToHome,
    this.favouriteProducts = const [],
    this.allProducts = const [],
    this.favouriteNames = const {},
    this.onFavouriteToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? phone;
  String? fullName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          fullName = doc.data()?['fullName'];
          phone = doc.data()?['phone'];
        });
      }
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
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
                    // Back Button
                    Positioned(
                      top: 50,
                      left: 15,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () => _handleBack(context),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                currentName: fullName ?? widget.userName,
                                currentPhone: phone ?? "+977 98XXXXXXXX",
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchUserData();
                          }
                        },
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
                                fullName ?? widget.userName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(phone ?? "+977 98XXXXXXXX"),
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
                      Icons.history,
                      "Order History",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
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
                              onFavouriteToggle:
                              widget.onFavouriteToggle ?? (item) {},
                            ),
                          ),
                        );
                      },
                    ),

                    /// 🔔 FIXED NOTIFICATIONS BUTTON
                    menuItem(
                      Icons.notifications,
                      "Notifications",
                      badgeStream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('notifications')
                          .snapshots(),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),

                    menuItem(
                      Icons.info_outline,
                      "About Us",
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutUsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// LOGOUT
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    );
                  }
                },
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
      ),
    );
  }

  Widget menuItem(
      IconData icon,
      String title, {
        VoidCallback? onTap,
        bool isLast = false,
        Stream<QuerySnapshot>? badgeStream,
      }) {

    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeStream != null)
                StreamBuilder<QuerySnapshot>(
                  stream: badgeStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${snapshot.data!.docs.length}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
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
