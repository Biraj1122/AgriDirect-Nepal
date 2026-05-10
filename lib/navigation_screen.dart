import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_cart.dart';
import 'login_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() =>
      _NavigationScreenState();
}

class _NavigationScreenState
    extends State<NavigationScreen> {

  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// BODY
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceAround,

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

            navItem(
              icon: Icons.person_rounded,
              label: "Profile",
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {

    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },

      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(.12)
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(18),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? Colors.green
                  : Colors.grey,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.green
                    : Colors.grey,

                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,

                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================
/// CATEGORIES SCREEN
/// =======================================

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> categories = [
      {
        "icon": Icons.eco,
        "title": "Vegetables",
      },
      {
        "icon": Icons.apple,
        "title": "Fruits",
      },
      {
        "icon": Icons.local_drink,
        "title": "Dairy",
      },
      {
        "icon": Icons.grass,
        "title": "Greens",
      },
      {
        "icon": Icons.spa,
        "title": "Organic",
      },
      {
        "icon": Icons.set_meal,
        "title": "Seeds",
      },
    ];

    return Scaffold(
      backgroundColor:
      const Color(0xffF7F8F3),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          "Categories",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: GridView.builder(
          itemCount: categories.length,

          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: .95,
          ),

          itemBuilder: (context, index) {

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: InkWell(
                borderRadius:
                BorderRadius.circular(24),

                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      backgroundColor:
                      Colors.green,

                      content: Text(
                        "${categories[index]["title"]} clicked",
                      ),
                    ),
                  );
                },

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    Container(
                      height: 75,
                      width: 75,

                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(.12),

                        borderRadius:
                        BorderRadius.circular(20),
                      ),

                      child: Icon(
                        categories[index]["icon"],
                        size: 38,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      categories[index]["title"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// =======================================
/// ORDERS SCREEN
/// =======================================

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xffF7F8F3),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [

          orderCard(
            orderId: "#AGD1021",
            status: "Delivered",
            amount: "Rs. 410",
            color: Colors.green,
          ),

          orderCard(
            orderId: "#AGD1022",
            status: "Pending",
            amount: "Rs. 620",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget orderCard({
    required String orderId,
    required String status,
    required String amount,
    required Color color,
  }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children: [

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                amount,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius:
              BorderRadius.circular(20),
            ),

            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================
/// PROFILE SCREEN
/// =======================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> menu = [
      {
        "icon": Icons.location_on_outlined,
        "title": "My Address",
      },
      {
        "icon": Icons.payment_outlined,
        "title": "Payment Methods",
      },
      {
        "icon": Icons.favorite_border,
        "title": "Favorites",
      },
      {
        "icon": Icons.notifications_none,
        "title": "Notifications",
      },
      {
        "icon": Icons.help_outline,
        "title": "Help & Support",
      },
      {
        "icon": Icons.info_outline,
        "title": "About Us",
      },
    ];

    return Scaffold(
      backgroundColor:
      const Color(0xffF7F8F3),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            children: [

              /// PROFILE HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xffDDEACF),
                      Color(0xffF5F8F1),
                    ],
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      height: 75,
                      width: 75,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(50),
                      ),

                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Biraj Sharma",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "+977 9812345678",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ...List.generate(menu.length, (index) {

                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 12),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: ListTile(
                    leading: Icon(
                      menu[index]["icon"],
                      color: Colors.green,
                    ),

                    title: Text(
                      menu[index]["title"],
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),

                    onTap: () {},
                  ),
                );
              }),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.red.shade50,

                    elevation: 0,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),
                  ),

                  onPressed: () {

                    Navigator.pushReplacement(
                      context,

                      MaterialPageRoute(
                        builder: (context) =>
                        const LoginScreen(),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),

                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}