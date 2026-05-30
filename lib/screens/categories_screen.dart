import 'dart:convert';
import 'package:flutter/material.dart';
import '../cart_model.dart';
import '../product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'Vegetables', 'icon': Icons.eco_rounded},
    {'name': 'Fruits', 'icon': Icons.apple_rounded},
    {'name': 'Dairy', 'icon': Icons.water_drop_rounded},
    {'name': 'Grains', 'icon': Icons.grain_rounded},
    {'name': 'Herbs', 'icon': Icons.local_florist_rounded},
    {'name': 'Organic', 'icon': Icons.spa_rounded},
    {'name': 'Seasonal', 'icon': Icons.wb_sunny_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final categoryIndex = _categories.indexWhere(
      (category) => category['name'] == widget.initialCategory,
    );
    if (categoryIndex != -1) {
      _selectedCategoryIndex = categoryIndex;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    final image = product['imagePath'] ?? product['image'] ?? 'assets/images/logo.png';
    final name = (product['name'] ?? product['title'] ?? 'No Name').toString();
    final newProduct = Product(
      title: name,
      price: product['price']?.toString() ?? '0',
      unit: product['unit']?.toString() ?? '',
      image: image,
      description: name,
      longDescription: product['description'] ?? "$name from local farm. Fresh and high quality produce.",
    );

    cartModel.add(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name added to cart'),
      backgroundColor: const Color(0xFF2E7D32),
      duration: const Duration(seconds: 1),
    ));
  }

  void _toggleFavorite(Map<String, dynamic> product) {
    widget.onExternalFavouriteToggle(product);
  }

  Widget _loadProductImage(String? path) {
    if (path == null || path.isEmpty) return const Icon(Icons.image, size: 50);
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50));
    } else if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(base64Decode(base64String),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50));
      } catch (e) {
        return const Icon(Icons.broken_image, size: 50);
      }
    }
    final fullPath = path.startsWith('assets/') ? path : 'assets/images/$path';
    return Image.asset(fullPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
      return Image.asset(path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50));
    });
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                Text('Fresh from local farms', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search for vegetables, fruits...',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final category = _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0)),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category['icon'] as IconData, size: 26, color: isSelected ? Colors.white : const Color(0xFF2E7D32)),
                  const SizedBox(height: 5),
                  Text(
                    category['name'].toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = (product['name'] ?? product['title'] ?? 'No Name').toString();
    final isFavorite = widget.externalFavouriteProducts.any((p) => (p['name'] ?? p['title']) == name);
    final image = product['imagePath'] ?? product['image'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.18,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: _loadProductImage(image),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: product['badge'] != null ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product['badge'].toString(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ) : const SizedBox.shrink(),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(product),
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: isFavorite ? Colors.red : const Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rs.${product['price']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('/${product['unit']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBackToHome != null) widget.onBackToHome!();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF2E7D32)),
                child: Text('AgriDirect Nepal', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onBackToHome?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.red),
                title: Text('My Favorites (${widget.externalFavouriteProducts.length})'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildCategoryRow(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    final selectedCategory = _categories[_selectedCategoryIndex]['name'];
                    List<Map<String, dynamic>> products = [];

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      products = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      }).toList();
                    }

                    // Products are now fetched exclusively from Firestore.
                    // Local fallbacks have been retired to ensure a dynamic inventory.
                    if (products.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No products found in this category.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final filteredProducts = products.where((product) {
                      final matchesCategory = selectedCategory == 'All' || product['category'] == selectedCategory;
                      final name = (product['name'] ?? product['title'] ?? '').toString().toLowerCase();
                      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
                      return matchesCategory && matchesSearch;
                    }).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedCategory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('${filteredProducts.length} items', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(child: Text("No products found"))
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
