import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/cart_model.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final map = product.toMap();
              map['badge'] = 'Fresh';
              map['badgeColor'] = Colors.green.toARGB32();
              map['farm'] = product.farmName ?? 'Local Farm';
              map['rating'] = 4.5;
              onToggleFavourite(map);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavourite ? "Removed from Favourites" : "Added to Favourites"),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isFavourite ? Colors.black87 : Colors.redAccent,
                ),
              );
            },
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xffF7F8F3),
                      ),
                      child: Hero(
                        tag: product.id ?? product.title,
                        child: _buildProductImage(product.image),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Rs. ${product.price}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.unit,
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "About product",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.longDescription,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (product.farmName != null)
                          _infoRow(Icons.agriculture, "Source", product.farmName!),
                        if (product.season != null)
                          _infoRow(Icons.wb_sunny_outlined, "Best Season", product.season!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  cartModel.add(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Add to cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.image_not_supported,
          size: 100,
          color: Colors.grey,
        ),
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
        );
      } catch (e) {
        return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
      }
    } else {
      String assetPath = imagePath;
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/images/$imagePath';
      }
      return Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, size: 100, color: Colors.green),
      );
    }
  }
}