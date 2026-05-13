import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final Set<String> _cartItems = {};
  final Set<String> _favoriteItems = {};
  late final List<Map<String, dynamic>> _allProducts;

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
    return _allProducts.where((product) {
      final matchesCategory = selectedCategory == 'All' || product['category'] == selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _allProducts = [
      {'name': 'Fresh Tomato (गोलभेंडा)', 'price': 130, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Kavre Organic Farm', 'badge': '100% Organic', 'badgeColor': Colors.green, 'rating': 4.8, 'reviews': 129, 'imagePath': 'tomato.png', 'discount': null},
      {'name': 'Organic Potato (आलु)', 'price': 60, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Himalayan Farms', 'badge': 'Pesticide Free', 'badgeColor': Colors.blue, 'rating': 4.5, 'reviews': 98, 'imagePath': 'potato.png', 'discount': null},
      {'name': 'Green Cabbage (बन्दा गोभी)', 'price': 80, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Bhaktapur Fresh Farm', 'badge': 'Fresh Picked', 'badgeColor': Colors.orange, 'rating': 4.3, 'reviews': 76, 'imagePath': 'green cabbage.png', 'discount': null},
      {'name': 'Fresh Spinach (पालुङ्गो)', 'price': 45, 'unit': 'bunch', 'category': 'Vegetables', 'farm': 'Green Valley Organics', 'badge': '100% Organic', 'badgeColor': Colors.green, 'rating': 4.6, 'reviews': 54, 'imagePath': 'spinach.png', 'discount': null},
      {'name': 'Fresh Cucumber (काक्रो)', 'price': 40, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Terai Produce Co-op', 'badge': 'Fresh Harvest', 'badgeColor': Colors.teal, 'rating': 4.4, 'reviews': 58, 'imagePath': 'tomato.png', 'discount': 5},
      {'name': 'Eggplant (भण्टा)', 'price': 65, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Dhading Vegetable Growers', 'badge': 'Organic', 'badgeColor': Colors.purple, 'rating': 4.2, 'reviews': 41, 'imagePath': 'eggplant.png', 'discount': null},
      {'name': 'Bitter Gourd (करेला)', 'price': 55, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Hetauda Green Farms', 'badge': 'Pesticide-Free', 'badgeColor': Colors.blue, 'rating': 4.1, 'reviews': 37, 'imagePath': 'bitter gourd.png', 'discount': null},
      {'name': 'Fresh Radish (मुला)', 'price': 48, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Kavre Root Vegetable Co-op', 'badge': 'Organic', 'badgeColor': Colors.green, 'rating': 4.5, 'reviews': 61, 'imagePath': 'Radish.png', 'discount': 10},
      {'name': 'Okra (भिन्डी)', 'price': 70, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Sindhuli Organic Farms', 'badge': 'Fresh', 'badgeColor': Colors.orange, 'rating': 4.3, 'reviews': 44, 'imagePath': 'okra.png', 'discount': null},
      {'name': 'French Beans (सेम)', 'price': 85, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Nuwakot Green Harvest', 'badge': 'Pesticide-Free', 'badgeColor': Colors.blue, 'rating': 4.6, 'reviews': 72, 'imagePath': 'french beans.png', 'discount': 5},
      {'name': 'Carrot (गाजर)', 'price': 95, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Chitwan Farm Market', 'badge': 'Fresh', 'badgeColor': Colors.deepOrange, 'rating': 4.4, 'reviews': 84, 'imagePath': 'carrot.png', 'discount': null},
      {'name': 'Pumpkin (फर्सी)', 'price': 50, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Lalitpur Organic Farm', 'badge': 'Seasonal', 'badgeColor': Colors.amber, 'rating': 4.2, 'reviews': 39, 'imagePath': 'pumpkin.png', 'discount': null},
      {'name': 'Ripe Mango (आम)', 'price': 200, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Terai Fruit Gardens', 'badge': 'Seasonal', 'badgeColor': Colors.amber, 'rating': 4.7, 'reviews': 143, 'imagePath': 'mango.png', 'discount': null},
      {'name': 'Banana (केरा)', 'price': 80, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Chitwan Banana Farm', 'badge': 'Fresh', 'badgeColor': Colors.orange, 'rating': 4.8, 'reviews': 189, 'imagePath': 'banana.png', 'discount': null},
      {'name': 'Apple (स्याउ)', 'price': 160, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Mustang Orchards', 'badge': 'Himalayan', 'badgeColor': Colors.red, 'rating': 4.9, 'reviews': 210, 'imagePath': 'apple.png', 'discount': 10},
      {'name': 'Papaya (मेवा)', 'price': 70, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Narayangarh Fruit Growers', 'badge': 'Local', 'badgeColor': Colors.amber, 'rating': 4.4, 'reviews': 57, 'imagePath': 'papaya.png', 'discount': null},
      {'name': 'Farm Fresh Milk (दूध)', 'price': 90, 'unit': 'litre', 'category': 'Dairy', 'farm': 'Sunrise Dairy Farm', 'badge': 'A2 Milk', 'badgeColor': Colors.teal, 'rating': 4.9, 'reviews': 210, 'imagePath': 'milk.png', 'discount': 10},
      {'name': 'Curd (दही)', 'price': 120, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Sunrise Dairy Farm', 'badge': 'Farm Fresh', 'badgeColor': Colors.teal, 'rating': 4.6, 'reviews': 112, 'imagePath': 'curd.png', 'discount': null},
      {'name': 'Fresh Yogurt (दही)', 'price': 135, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Yogurt Co-op', 'badge': 'Probiotic', 'badgeColor': Colors.teal, 'rating': 4.7, 'reviews': 98, 'imagePath': 'fresh yogurt.png', 'discount': 5},
      {'name': 'Fresh Butter (मखन)', 'price': 420, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Dairy', 'badge': 'Desi', 'badgeColor': Colors.teal, 'rating': 4.8, 'reviews': 87, 'imagePath': 'fresh butter.png', 'discount': null},
      {'name': 'Fresh Ghee (घिउ)', 'price': 850, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Ghee Factory', 'badge': 'Pure', 'badgeColor': Colors.teal, 'rating': 4.9, 'reviews': 142, 'imagePath': 'fresh ghee.png', 'discount': null},
      {'name': 'Brown Rice (चामल)', 'price': 180, 'unit': 'kg', 'category': 'Grains', 'farm': 'Chitwan Agro Farm', 'badge': 'Whole Grain', 'badgeColor': Colors.brown, 'rating': 4.4, 'reviews': 67, 'imagePath': 'brown rice.png', 'discount': 5},
      {'name': 'Millet (कोदो)', 'price': 190, 'unit': 'kg', 'category': 'Grains', 'farm': 'Himalayan Millet Co-op', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.5, 'reviews': 52, 'imagePath': 'millet.png', 'discount': null},
      {'name': 'Wheat (गेहुँ)', 'price': 110, 'unit': 'kg', 'category': 'Grains', 'farm': 'Narayangarh Grain Store', 'badge': 'Local', 'badgeColor': Colors.brown, 'rating': 4.3, 'reviews': 48, 'imagePath': 'wheat.png', 'discount': null},
      {'name': 'Maize (मकै)', 'price': 45, 'unit': 'kg', 'category': 'Grains', 'farm': 'Terai Maize Growers', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.2, 'reviews': 40, 'imagePath': 'maize.png', 'discount': null},
      {'name': 'Soybean (सोयाबिन)', 'price': 160, 'unit': 'kg', 'category': 'Grains', 'farm': 'Kavre Soy Growers', 'badge': 'Protein-Rich', 'badgeColor': Colors.brown, 'rating': 4.4, 'reviews': 55, 'imagePath': 'soyabean.png', 'discount': null},
      {'name': 'Himalayan Honey (शहद)', 'price': 850, 'unit': '500g', 'category': 'Organic', 'farm': 'Mountain Bee Farm', 'badge': 'Pure & Raw', 'badgeColor': Colors.brown, 'rating': 4.9, 'reviews': 312, 'imagePath': 'himalayan honey.png', 'discount': null},
      {'name': 'Fresh Ginger (अदुवा)', 'price': 120, 'unit': 'kg', 'category': 'Herbs', 'farm': 'Gorkha Spice Farm', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.6, 'reviews': 78, 'imagePath': 'ginger.png', 'discount': null},
      {'name': 'Fresh Turmeric (बेसार)', 'price': 210, 'unit': 'kg', 'category': 'Herbs', 'farm': 'Gorkha Spice Farm', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.8, 'reviews': 92, 'imagePath': 'fresh turmeric.png', 'discount': 5},
    ];
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

  void _toggleFavorite(Map<String, dynamic> product) {
    setState(() {
      final name = product['name'].toString();
      if (_favoriteItems.contains(name)) {
        _favoriteItems.remove(name);
      } else {
        _favoriteItems.add(name);
      }
    });
  }

  void _openFavoritesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesPage(
          favoriteItems: _favoriteItems,
          allProducts: _allProducts,
          onFavoriteToggle: _toggleFavorite,
        ),
      ),
    );
  }

  // ─── CATEGORY ROW (shown prominently at the top) ───────────────────────────
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
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 26,
                    color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                  ),
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

  // ─── SEARCH BAR (filter button removed) ────────────────────────────────────
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
            // ✅ suffixIcon (filter button) REMOVED
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
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_cartItems.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    final isFavorite = _favoriteItems.contains(name);

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
                    child: Image.asset(
                      'assets/images/${product['imagePath']}',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (product['badgeColor'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(product['badge'].toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: product['badgeColor'] as Color)),
                  ),
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
                if (product['discount'] != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: Text('${product['discount']}% OFF', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 2),
                  Text(product['farm'].toString(), style: const TextStyle(fontSize: 9.5, color: Color(0xFF757575)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text('${product['rating']} (${product['reviews']})', style: const TextStyle(fontSize: 9.5, color: Color(0xFF757575))),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(child: Text('Rs.${product['price']}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                          Text('/${product['unit']}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF757575))),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
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
          Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFB0BEC5)),
          SizedBox(height: 12),
          Text('No products found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Try a different category or search term', style: TextStyle(fontSize: 13, color: Color(0xFF78909C))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              leading: const Icon(Icons.favorite_rounded),
              title: Text('Favorites (${_favoriteItems.length})'),
              onTap: () { Navigator.pop(context); _openFavoritesPage(); },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_rounded),
              title: Text('Cart (${_cartItems.length})'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Search Bar (no filter button)
            _buildSearchBar(),

            const SizedBox(height: 8),

            // ✅ Category row shown prominently here
            _buildCategoryRow(),

            const SizedBox(height: 8),

            // Product count label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategoryIndex == 0 ? 'All Products' : _categories[_selectedCategoryIndex]['name'].toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  Text('${_filteredProducts.length} items', style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Product grid
            Expanded(
              child: _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favorites Page ───────────────────────────────────────────────────────────
class FavoritesPage extends StatelessWidget {
  final Set<String> favoriteItems;
  final List<Map<String, dynamic>> allProducts;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  const FavoritesPage({super.key, required this.favoriteItems, required this.allProducts, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = allProducts.where((p) => favoriteItems.contains(p['name'].toString())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites'), backgroundColor: const Color(0xFF2E7D32)),
      body: favoriteProducts.isEmpty
          ? const Center(child: Text('No favorite items yet', style: TextStyle(fontSize: 18)))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) => _buildFavoriteCard(favoriteProducts[index], context),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> product, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Image.asset(
                'assets/images/${product['imagePath']}',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 60),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs.${product['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      IconButton(icon: const Icon(Icons.favorite_rounded, color: Colors.red), onPressed: () => onFavoriteToggle(product)),
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
}