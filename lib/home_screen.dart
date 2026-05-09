import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.shopping_cart_outlined),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("See all", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// CATEGORIES (FIXED OVERFLOW → HORIZONTAL SCROLL)
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    categoryItem(Icons.eco_outlined, "Vegetables"),
                    categoryItem(Icons.apple, "Fruits"),
                    categoryItem(Icons.local_drink_outlined, "Dairy"),
                    categoryItem(Icons.grass, "Greens"),
                    categoryItem(Icons.energy_savings_leaf, "Organic"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// OFFER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xff7CB342), Color(0xff4CAF50)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fresh Organic\nVegetables",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "20% OFF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text("Shop now"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Image.asset(
                        "assets/images/tomatoes.png",
                        height: 110,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// POPULAR PRODUCTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Popular Products",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("See all", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// PRODUCT GRID (FIXED SCROLL ISSUE)
              GridView.builder(
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final products = [
                    ["assets/images/tomatoes.png", "Fresh Tomatoes", "120", "1kg"],
                    ["assets/images/potato png.png", "Organic Potatoes", "80", "1kg"],
                    ["assets/images/green cabbage.png", "Green Cabbage", "60", "1pc"],
                    ["assets/images/milk png.png", "Farm Fresh Milk", "110", "1L"],
                  ];

                  return productCard(
                    image: products[index][0],
                    title: products[index][1],
                    price: products[index][2],
                    unit: products[index][3],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CATEGORY ITEM
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
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(unit, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rs. $price",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}