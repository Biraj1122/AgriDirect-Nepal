import 'dart:convert';
import 'package:flutter/material.dart';
import '../product.dart';
import 'product_detail_screen.dart';
import '../notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final VoidCallback onCartTap;
  final VoidCallback onFavoritesTap;
  final Function(String) onCategoryTap;
  final List<Map<String, dynamic>> favouriteProducts;
  final Function(Map<String, dynamic>) onFavouriteToggle;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.onCartTap,
    required this.onFavoritesTap,
    required this.onCategoryTap,
    required this.favouriteProducts,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            List<Product> products = [];
            
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              products = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Product(
                  image: data['image'] ?? data['imagePath'] ?? 'assets/images/logo.png',
                  title: data['title'] ?? data['name'] ?? 'No Title',
                  price: data['price']?.toString() ?? '0',
                  unit: data['unit'] ?? '',
                  description: data['description'] ?? '',
                  longDescription: data['longDescription'] ?? data['description'] ?? '',
                );
              }).toList();
            }

            // Products are now fetched exclusively from Firestore. 
            // Local fallbacks have been retired.
            if (products.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No products available in the cloud. Please seed data from the Admin Dashboard."),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $userName",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Good morning",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: onFavoritesTap,
                            icon: const Icon(Icons.favorite_border, color: Colors.red),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_none),
                          ),
                        ],
                      ),
                    ],
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
                        onPressed: () {
                          onCategoryTap("");
                        },
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
                        categoryItem(context, Icons.eco_outlined, "Vegetables"),
                        categoryItem(context, Icons.apple_outlined, "Fruits"),
                        categoryItem(context, Icons.local_drink_outlined, "Dairy"),
                        categoryItem(context, Icons.grass, "Herbs"),
                        categoryItem(context, Icons.energy_savings_leaf, "Organic"),
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
                        colors: [Color(0xff7CB342), Color(0xff4CAF50)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                  snapshot.connectionState == ConnectionState.waiting && products.length <= 1
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          itemCount: products.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isFavorite = favouriteProducts.any((p) => p['name'] == product.title);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                              child: productCard(
                                image: product.image,
                                title: product.title,
                                price: product.price,
                                unit: product.unit,
                                isFavorite: isFavorite,
                                onFavoriteToggle: () {
                                  onFavouriteToggle({
                                    'name': product.title,
                                    'price': product.price,
                                    'unit': product.unit,
                                    'imagePath': product.image,
                                    'description': product.description,
                                    'longDescription': product.longDescription,
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget categoryItem(
      BuildContext context,
      IconData icon,
      String title,
      ) {
    return GestureDetector(
      onTap: () {
        onCategoryTap(title);
      },
      child: Container(
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
              child: Icon(
                icon,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget productCard({
    required String image,
    required String title,
    required String price,
    required String unit,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
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
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: _buildProductImage(image),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: TextStyle(color: Colors.grey.shade600),
          ),
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

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.contain, 
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50));
      } catch (e) {
        return const Icon(Icons.broken_image, size: 50);
      }
    } else {
      String assetPath = imagePath;
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/images/$imagePath';
      }
      return Image.asset(assetPath, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50));
    }
  }
}
