import 'dart:convert';
import 'package:flutter/material.dart';
import '../product.dart';
import '../cart_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final Function(Map<String, dynamic>) onToggleFavourite;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final map = product.toMap();
              map['badge'] = 'Fresh';
              map['badgeColor'] = Colors.green.toARGB32();
              map['farm'] = product.farmName ?? 'Local Farm';
              map['rating'] = 4.5;
              onToggleFavourite(map);
            },
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(                                      // ✅ wrap in Column
        children: [
          Expanded(
            child: SingleChildScrollView(               // ✅ content scrolls
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: _buildProductImage(product.image),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Rs. ${product.price}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    product.unit,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(product.description),

                  const SizedBox(height: 15),

                  const Text(
                    "About this product",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    product.longDescription,
                    style: const TextStyle(height: 1.4),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ✅ button pinned at bottom, never overflows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  cartModel.add(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Added to cart"),
                    ),
                  );
                },
                child: const Text(
                  "Add to Cart",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
          imagePath,
          key: ValueKey(imagePath), // Forces reload when URL changes
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), height: 220, fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100));
      } catch (e) {
        return const Icon(Icons.broken_image, size: 100);
      }
    } else {
      String assetPath = imagePath;
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/images/$imagePath';
      }
      return Image.asset(assetPath, height: 220, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100));
    }
  }
}
