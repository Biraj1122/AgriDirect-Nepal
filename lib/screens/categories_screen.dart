import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import '../cart_model.dart';
import '../product.dart';
import '../my_favourites.dart';

class CategoriesScreen extends StatefulWidget {
  final String initialCategory;
  final List<Map<String, dynamic>> externalFavouriteProducts;
  final Function(Map<String, dynamic>) onExternalFavouriteToggle;
  final VoidCallback? onBackToHome;

  const CategoriesScreen({
    super.key,
    this.initialCategory = 'All',
    required this.externalFavouriteProducts,
    required this.onExternalFavouriteToggle,
    this.onBackToHome,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        final fetched = snapshot.docs.map((doc) {
          final data = doc.data();
          final iconCode = data['iconCode'] as int?;
          return {
            'name': data['name'] ?? 'Category',
            'icon': iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.category,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _categories = [{'name': 'All', 'icon': Icons.apps_rounded}, ...fetched];
            _isLoadingCategories = false;
            
            // Set initial category index
            final categoryIndex = _categories.indexWhere(
              (category) => category['name'] == widget.initialCategory,
            );
            if (categoryIndex != -1) {
              _selectedCategoryIndex = categoryIndex;
            }
          });
        }
      } else {
        // Fallback
        if (mounted) {
          setState(() {
            _categories = [
              {'name': 'All', 'icon': Icons.apps_rounded},
              {'name': 'Vegetables', 'icon': Icons.eco_rounded},
              {'name': 'Fruits', 'icon': Icons.apple_rounded},
              {'name': 'Dairy', 'icon': Icons.water_drop_rounded},
              {'name': 'Grains', 'icon': Icons.grain_rounded},
              {'name': 'Pulses', 'icon': Icons.lens_blur},
              {'name': 'Mushrooms', 'icon': Icons.spa},
              {'name': 'Tea & Coffee', 'icon': Icons.local_cafe_outlined},
              {'name': 'Spices', 'icon': Icons.flare},
            ];
            _isLoadingCategories = false;

            final categoryIndex = _categories.indexWhere(
              (category) => category['name'] == widget.initialCategory,
            );
            if (categoryIndex != -1) {
              _selectedCategoryIndex = categoryIndex;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProducts(List<Map<String, dynamic>> liveProducts) {
    final selectedCategory = _categories[_selectedCategoryIndex]['name'];
    return liveProducts.where((product) {
      final matchesCategory = selectedCategory == 'All' || product['category'] == selectedCategory;
      final name = (product['name'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    final newProduct = Product.fromMap(product, docId: product['id']);

    cartModel.add(newProduct);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${newProduct.title} added to cart'),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 1),
    ));
  }

  void _openFavoritesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyFavouritesScreen(
          onFavouriteToggle: widget.onExternalFavouriteToggle,
        ),
      ),
    );
  }

  Widget _buildAppBar(List<Map<String, dynamic>> currentProducts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: widget.onBackToHome ?? () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Fresh from local farms', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: _openFavoritesPage,
            icon: const Icon(Icons.favorite_border, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    if (_isLoadingCategories) {
      return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_categories[index]['icon'], color: isSelected ? Colors.white : Colors.green),
                  Text(_categories[index]['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = (product['name'] ?? product['title'] ?? 'Product').toString();
    final productId = product['id']?.toString();
    
    final isFavorite = widget.externalFavouriteProducts.any((p) =>
      (productId != null && (p['id'] == productId || p['docId'] == productId)) ||
      (p['name'] ?? p['title']) == name
    );

    final productObj = Product.fromMap(product, docId: productId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: productObj,
              isFavourite: isFavorite,
              onToggleFavourite: widget.onExternalFavouriteToggle,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildProductImage(productObj.image),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => widget.onExternalFavouriteToggle(product),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Rs.${product['price']} / ${product['unit']}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.green),
                      onPressed: () => _addToCart(product),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String image) {
    if (image.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        key: ValueKey(image), // Forces reload when the URL changes in Firestore
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.green.withValues(alpha: 0.5),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    } else if (image.startsWith('data:image')) {
      try {
        final base64String = image.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      }
    }

    String assetPath = image;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$image';
    }

    return Image.asset(
      assetPath,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.eco, color: Colors.green)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No products found."));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            List<Map<String, dynamic>> allProducts = [];
            if (snapshot.hasData) {
              allProducts = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();
            }

            final filteredProducts = _getFilteredProducts(allProducts);

            return Column(
              children: [
                _buildAppBar(allProducts),
                _buildSearchBar(),
                _buildCategoryRow(),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator(color: Colors.green))
                      : (filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                            )),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
