import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'about_us.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xffE8F5E9),
                  ),
                ),
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
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName, // Displays the login name
                            style: const TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text("+977 9812345678", style: TextStyle(
                              color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Orders Section
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Orders", style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward_ios, size: 14,
                            color: Colors.green),
                        label: const Text(
                            "See all", style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      orderStatusItem(
                          Icons.account_balance_wallet_outlined, "To Pay"),
                      orderStatusItem(Icons.local_shipping_outlined, "To Ship"),
                      orderStatusItem(
                          Icons.mark_email_read_outlined, "Delivered"),
                      orderStatusItem(Icons.cancel_outlined, "Cancelled"),
                    ],
                  ),
                ],
              ),
            ),
            // Menu
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  menuItem(Icons.location_on_outlined, "My Addresses"),
                  menuItem(Icons.payment_outlined, "Payment Methods"),
                  menuItem(Icons.favorite_border_rounded, "My Favorites"),
                  menuItem(Icons.notifications_none_rounded, "Notifications"),
                  menuItem(Icons.help_outline_rounded, "Help & Support"),
                  // Inside ProfileScreen, find the menuItem for "About Us"
                  menuItem(Icons.info_outline_rounded, "About Us", isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutUsScreen()),
                        );
                      }),
                ],
              ),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () =>
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()), (
                          r) => false),
              child: Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: Colors.redAccent),
                    SizedBox(width: 15),
                    Text("Logout", style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget orderStatusItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xffF0F4EC),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xff4A6D32), size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget menuItem(IconData icon, String title,
      {bool isLast = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xff4A6D32)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(
              Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 70, color: Color(0xffEEEEEE)),
      ],
    );
  }
}