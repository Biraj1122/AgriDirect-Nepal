import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cart_model.dart';
import '../../models/product.dart';

class MyFavouritesScreen extends StatelessWidget {
  final Function(Map<String, dynamic>) onFavouriteToggle;

  const MyFavouritesScreen({
    super.key,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Favourites',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please login to see favourites"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Fallback if orderBy fails due to missing index
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('favorites')
                        .snapshots(),
                    builder: (context, snapshotNoOrder) {
                      if (snapshotNoOrder.hasError) return Center(child: Text("Error: ${snapshotNoOrder.error}"));
                      if (snapshotNoOrder.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      return _buildGrid(context, snapshotNoOrder.data?.docs ?? []);
                    },
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                return _buildGrid(context, snapshot.data?.docs ?? []);
              },
            ),
    );
  }

  Widget _buildGrid(BuildContext context, List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return _buildEmptyState(context);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        data['docId'] = docs[index].id;
        return _buildFavouriteCard(context, data);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Favourites Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Tap the ♡ on products to save them.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Go Shopping", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteCard(BuildContext context, Map<String, dynamic> product) {
    final String name = (product['name'] ?? product['title'] ?? 'Product').toString();
    final String image = (product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '').toString();
    final String price = (product['price'] ?? '0').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Hero(
                      tag: 'fav_${product['docId'] ?? name}',
                      child: _buildImage(image),
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      onPressed: () => onFavouriteToggle(product),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("Rs. $price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final p = Product.fromMap(product, docId: product['docId']);
                      cartModel.add(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$name added to cart"), 
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty || path == 'null') return const Icon(Icons.image_not_supported, color: Colors.grey);
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      );
    }
    return Image.asset(
      path.startsWith('assets/') ? path : 'assets/images/$path',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}
