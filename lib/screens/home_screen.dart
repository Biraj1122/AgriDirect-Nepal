import 'package:flutter/material.dart';

import '../product.dart';
import '../product_detail_screen.dart';
import '../notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onCartTap;

  const HomeScreen({
    super.key,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        image: "assets/images/tomatoes.png",
        title: "Fresh Tomatoes",
        price: "120",
        unit: "1kg",
        description: "Fresh organic tomatoes directly from local farms.",
        longDescription:
        "Fresh tomatoes grown naturally without chemicals in local farms. Rich in vitamins, antioxidants and perfect for daily cooking.",
      ),
      Product(
        image: "assets/images/potato png.png",
        title: "Organic Potatoes",
        price: "80",
        unit: "1kg",
        description: "Naturally grown potatoes rich in nutrients.",
        longDescription:
        "Organic potatoes grown without pesticides. High in fiber and perfect for curries, fries, and traditional meals.",
      ),
      Product(
        image: "assets/images/green cabbage.png",
        title: "Green Cabbage",
        price: "60",
        unit: "1kg",
        description: "Healthy green cabbage freshly harvested.",
        longDescription:
        "Fresh cabbage packed with nutrients, good for digestion and immunity support.",
      ),
      Product(
        image: "assets/images/milk png.png",
        title: "Farm Fresh Milk",
        price: "110",
        unit: "1L",
        description: "Pure farm fresh milk from healthy cows.",
        longDescription:
        "Pure milk collected daily from hygienic farms, rich in calcium and protein.",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Biraj",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Good morning",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      // ✅ NOTIFICATION ICON (FIXED NAVIGATION)
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Search vegetables, fruits...",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// CATEGORY TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Categories",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// CATEGORY LIST
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    categoryItem(Icons.eco_outlined, "Vegetables"),
                    categoryItem(Icons.apple_outlined, "Fruits"),
                    categoryItem(Icons.local_drink_outlined, "Dairy"),
                    categoryItem(Icons.grass, "Greens"),
                    categoryItem(Icons.energy_savings_leaf, "Organic"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff7CB342),
                      Color(0xff4CAF50),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fresh Organic\nVegetables",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "20% OFF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      "assets/images/tomatoes.png",
                      height: 110,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// PRODUCT GRID
              GridView.builder(
                itemCount: products.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: products[index],
                          ),
                        ),
                      );
                    },
                    child: productCard(
                      image: products[index].image,
                      title: products[index].title,
                      price: products[index].price,
                      unit: products[index].unit,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CATEGORY WIDGET
  Widget categoryItem(IconData icon, String title) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xffEEF5E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.green, size: 28),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// PRODUCT CARD
  Widget productCard({
    required String image,
    required String title,
    required String price,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: Image.asset(image))),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(unit, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            "Rs. $price",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}