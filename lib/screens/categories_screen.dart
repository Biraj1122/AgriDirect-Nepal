import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final Set<String> favouriteNames;
  final Function(Map<String, dynamic>) onFavouriteToggle;

  const CategoriesScreen({
    super.key,
    required this.allProducts,
    required this.favouriteNames,
    required this.onFavouriteToggle,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final Set<String> _cartItems = {};

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

  List<Map<String, dynamic>> get _filteredProducts {
    final selectedCategory = _categories[_selectedCategoryIndex]['name'];
    return widget.allProducts.where((product) {
      final matchesCategory =
          selectedCategory == 'All' || product['category'] == selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() => _cartItems.add(product['name'].toString()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product['name']} added to cart'),
      backgroundColor: const Color(0xFF2E7D32),
      duration: const Duration(seconds: 1),
    ));
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
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                isSelected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
                    : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 26,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category['name'].toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF616161),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search for vegetables, fruits...',
            hintStyle:
            const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFF9E9E9E), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Color(0xFF9E9E9E), size: 20),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
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
                Text('Categories',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                Text('Fresh from local farms',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_cartItems.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'].toString();
    // ── Uses shared favouriteNames from parent ──
    final isFavourite = widget.favouriteNames.contains(name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
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
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    child: Image.asset(
                      'assets/images/${product['imagePath']}',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey));
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (product['badgeColor'] as Color)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(product['badge'].toString(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: product['badgeColor'] as Color)),
                  ),
                ),

                // ── HEART BUTTON — calls parent toggle ──────────────────
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => widget.onFavouriteToggle(product),
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: isFavourite
                            ? Colors.red
                            : const Color(0xFF757575),
                      ),
                    ),
                  ),
                ),

                if (product['discount'] != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${product['discount']}% OFF',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 2),
                  Text(product['farm'].toString(),
                      style: const TextStyle(
                          fontSize: 9.5, color: Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text(
                          '${product['rating']} (${product['reviews']})',
                          style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF757575))),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                              child: Text('Rs.${product['price']}',
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color:
                                      Color(0xFF2E7D32)))),
                          Text('/${product['unit']}',
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF757575))),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius:
                              BorderRadius.circular(9)),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Color(0xFFB0BEC5)),
          SizedBox(height: 12),
          Text('No products found',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Try a different category or search term',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF78909C))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildCategoryRow(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategoryIndex == 0
                        ? 'All Products'
                        : _categories[_selectedCategoryIndex]['name']
                        .toString(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  Text('${_filteredProducts.length} items',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF757575))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) =>
                    _buildProductCard(_filteredProducts[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}