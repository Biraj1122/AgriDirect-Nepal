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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello, Sam",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "Good Morning",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                        ),
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SEARCH BAR
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                          "Search vegetables, fruits...",
                          hintStyle: TextStyle(
                            color:
                            Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.tune,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// CATEGORY TITLE
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// CATEGORIES
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  categoryItem(
                    Icons.eco_outlined,
                    "Vegetables",
                  ),

                  categoryItem(
                    Icons.apple,
                    "Fruits",
                  ),

                  categoryItem(
                    Icons.local_drink_outlined,
                    "Dairy",
                  ),

                  categoryItem(
                    Icons.grass,
                    "Greens",
                  ),

                  categoryItem(
                    Icons.energy_savings_leaf,
                    "Organic",
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// OFFER CARD (FIXED OVERFLOW)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(22),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff7CB342),
                      Color(0xff4CAF50),
                    ],
                  ),
                ),

                child: Row(
                  children: [

                    /// LEFT SIDE
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [

                          const Text(
                            "Fresh Organic\nVegetables",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            "20% OFF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            height: 45,

                            child: ElevatedButton(
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.white,
                                foregroundColor:
                                Colors.green,
                                elevation: 0,

                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      12),
                                ),
                              ),

                              onPressed: () {},

                              child: const Text(
                                "Shop now",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// RIGHT IMAGE
                    Expanded(
                      flex: 1,
                      child: Image.asset(
                        "assets/images/tomato.png",
                        fit: BoxFit.contain,
                        height: 130,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// POPULAR PRODUCTS
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Popular Products",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all",
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// PRODUCT GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,

                children: [

                  /// PRODUCT 1
                  productCard(
                    image:
                    "assets/images/tomato.png",
                    title: "Fresh Tomatoes",
                    price: "120",
                    unit: "1kg",
                  ),

                  /// PRODUCT 2
                  productCard(
                    image:
                    "assets/images/potato.png",
                    title: "Organic Potatoes",
                    price: "80",
                    unit: "1kg",
                  ),

                  /// PRODUCT 3
                  productCard(
                    image:
                    "assets/images/cabbage.png",
                    title: "Green Cabbage",
                    price: "60",
                    unit: "1pc",
                  ),

                  /// PRODUCT 4
                  productCard(
                    image:
                    "assets/images/milk.png",
                    title: "Farm Fresh Milk",
                    price: "110",
                    unit: "1L",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CATEGORY ITEM
  Widget categoryItem(
      IconData icon,
      String title,
      ) {
    return Column(
      children: [

        Container(
          height: 62,
          width: 62,

          decoration: BoxDecoration(
            color: const Color(0xffEEF5E8),
            borderRadius:
            BorderRadius.circular(18),
          ),

          child: Icon(
            icon,
            color: Colors.green,
            size: 30,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
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
        borderRadius:
        BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          /// PRODUCT IMAGE
          Expanded(
            child: Center(
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// TITLE
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 4),

          /// UNIT
          Text(
            unit,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          /// PRICE + BUTTON
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "Rs. $price",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              Container(
                height: 36,
                width: 36,

                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}