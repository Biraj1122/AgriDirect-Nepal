import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_detail_screen.dart';
import '../../models/cart_model.dart';
import '../../models/product.dart';
import '../../viewmodels/shop_viewmodel.dart';
import '../profile/my_favourites.dart';
import '../../Success/shared_widgets.dart';
import '../../Success/skeleton_loader.dart';

class CategoriesScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const CategoriesScreen({
    super.key,
    this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShopViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, vm),
            _buildSearchBar(vm),
            _buildCategoryRow(vm),
            Expanded(
              child: vm.loading
                  ? _buildLoadingGrid()
                  : _buildProductGrid(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ShopViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: onBackToHome ?? () => Navigator.pop(context),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Marketplace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyFavouritesScreen(onFavouriteToggle: (p) => vm.toggleFavourite(Product.fromMap(p))))),
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ShopViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          onChanged: vm.setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search fresh produce...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.green),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(ShopViewModel vm) {
    return StreamBuilder<List<String>>(
      stream: vm.getCategories(),
      builder: (context, snap) {
        final categories = ['All', ...(snap.data ?? [])];
        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = vm.selectedCategory == cat;
              return GestureDetector(
                onTap: () => vm.setSelectedCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 85,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03), 
                        blurRadius: 10, 
                        offset: const Offset(0, 4)
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getCategoryIcon(cat), color: isSelected ? Colors.white : Colors.green, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        cat, 
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonLoader(borderRadius: 24),
    );
  }

  Widget _buildProductGrid(BuildContext context, ShopViewModel vm) {
    final products = vm.filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text("No products found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(context, vm, products[index]),
    );
  }

  Widget _buildProductCard(BuildContext context, ShopViewModel vm, Product product) {
    final isFavorite = vm.isFavourite(product);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
          product: product, 
          isFavourite: isFavorite, 
          onToggleFavourite: (p) => vm.toggleFavourite(Product.fromMap(p))
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Hero(tag: product.id ?? product.title, child: SafeProductImage(imageUrl: product.image, fit: BoxFit.cover)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => vm.toggleFavourite(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1D25)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs.${product.price}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 15)),
                      GestureDetector(
                        onTap: () {
                          cartModel.add(product);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart"), duration: Duration(milliseconds: 500), behavior: SnackBarBehavior.floating));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'vegetables': return Icons.eco_rounded;
      case 'fruits': return Icons.apple_rounded;
      case 'dairy': return Icons.water_drop_rounded;
      case 'grains': return Icons.grain_rounded;
      case 'pulses': return Icons.lens_blur;
      default: return Icons.category_rounded;
    }
  }
}
