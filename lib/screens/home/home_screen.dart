import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmtech_agridirect/models/product.dart';
import 'package:farmtech_agridirect/screens/shop/product_detail_screen.dart';
import 'package:farmtech_agridirect/screens/profile/notifications_screen.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmtech_agridirect/viewmodels/shop_viewmodel.dart';
import 'package:farmtech_agridirect/Success/shared_widgets.dart';
import 'package:farmtech_agridirect/Success/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onCartTap;
  final VoidCallback onFavoritesTap;
  final Function(String) onCategoryTap;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.onCartTap,
    required this.onFavoritesTap,
    required this.onCategoryTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _featuredPageController = PageController();
  int _currentFeaturedIndex = 0;
  Timer? _featuredTimer;
  int _featuredCount = 0;

  @override
  void initState() {
    super.initState();
    _startFeaturedTimer();
  }

  void _startFeaturedTimer() {
    _featuredTimer?.cancel();
    _featuredTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_featuredPageController.hasClients && _featuredCount > 1) {
        int nextIndex = (_currentFeaturedIndex + 1) % _featuredCount;
        _featuredPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _featuredTimer?.cancel();
    _featuredPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final vm = context.watch<ShopViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 15),
                _buildActiveOrderBanner(user),
                const SizedBox(height: 25),
                const Text("Featured Items", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1A1D25))),
                const SizedBox(height: 12),
                _buildFeaturedSection(vm),
                const SizedBox(height: 30),
                const Text("Promos & Offers", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1A1D25))),
                const SizedBox(height: 12),
                _buildPromoSection(),
                const SizedBox(height: 30),
                _buildCategoriesHeader(),
                const SizedBox(height: 12),
                _buildCategoriesSection(vm),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Namaste, ${widget.userName}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25)),
            ),
            const SizedBox(height: 2),
            Text(_getTimeBasedGreeting(), style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: widget.onFavoritesTap,
              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              style: IconButton.styleFrom(backgroundColor: Colors.white),
            ),
            _buildNotificationIcon(user),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationIcon(User? user) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          icon: const Icon(Icons.notifications_rounded, color: Colors.amber),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      "${snapshot.data!.docs.length}",
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
      ],
    );
  }

  Widget _buildActiveOrderBanner(User? user) {
    if (user == null) return const SizedBox();
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['Pending Farmer', 'Farmer Accepted', 'Picked Up', 'On the way', 'Arrived'])
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

        final orderDoc = snapshot.data!.docs.first;
        final order = orderDoc.data() as Map<String, dynamic>;
        final status = order['status'] ?? 'Pending';

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(orderId: orderDoc.id, onBackToHome: () => Navigator.pop(context)))),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D9E75), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF1D9E75).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Track Your Delivery", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 17)),
                      Text(_getStatusMessage(status), style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSection(ShopViewModel vm) {
    if (vm.loading) return const SkeletonLoader(height: 200, borderRadius: 28);
    final products = vm.filteredProducts.take(6).toList();
    if (products.isEmpty) return const SizedBox();

    if (_featuredCount != products.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _featuredCount = products.length);
      });
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _featuredPageController,
        onPageChanged: (idx) => setState(() => _currentFeaturedIndex = idx),
        itemCount: products.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => _buildFeaturedCard(context, vm, products[index]),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, ShopViewModel vm, Product product) {
    final isFavourite = vm.isFavourite(product);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
          product: product, 
          isFavourite: isFavourite, 
          onToggleFavourite: (p) => vm.toggleFavourite(Product.fromMap(p))
        )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(child: Hero(tag: product.id ?? product.title, child: SafeProductImage(imageUrl: product.image))),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8)]),
                      child: const Text("ORGANIC", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text(product.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Row(
                      children: [
                        Text("Rs. ${product.price}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(" / ${product.unit}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20, right: 20,
                child: GestureDetector(
                  onTap: () => vm.toggleFavourite(product),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.redAccent, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPromoCard("10% OFF", "On organic vegetables", Colors.orange, Icons.percent_rounded),
          _buildPromoCard("FREE DELIVERY", "Orders above Rs. 2000", Colors.blue, Icons.local_shipping_rounded),
          _buildPromoCard("COMBO DEALS", "Gifts on Rs. 5000+", Colors.purple, Icons.card_giftcard_rounded),
        ],
      ),
    );
  }

  Widget _buildPromoCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 36),
        ],
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Categories", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1A1D25))),
        TextButton(
          onPressed: () => widget.onCategoryTap("All"),
          child: const Text("See all", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ShopViewModel vm) {
    return StreamBuilder<List<String>>(
      stream: vm.getCategories(),
      builder: (context, snap) {
        final categories = snap.data ?? ["Vegetables", "Fruits", "Grains", "Dairy", "Pulses"];
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) => _categoryItem(categories[index]),
          ),
        );
      },
    );
  }

  Widget _categoryItem(String title) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap(title),
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(_getCategoryIcon(title), color: Colors.green, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D25))),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'vegetables': return Icons.eco_rounded;
      case 'fruits': return Icons.apple_rounded;
      case 'grains': return Icons.grain_rounded;
      case 'dairy': return Icons.water_drop_rounded;
      case 'pulses': return Icons.lens_blur;
      default: return Icons.category_rounded;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Pending Farmer': return "Waiting for farm confirmation...";
      case 'Farmer Accepted': return "Farm is packing your order...";
      case 'Picked Up': return "Rider has collected your items";
      case 'On the way': return "Rider is heading your way!";
      case 'Arrived': return "Rider has arrived at your location";
      default: return "Processing your order...";
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Hope you're having a great morning!";
    if (hour < 17) return "How is your afternoon going?";
    return "Ready for a fresh dinner tonight?";
  }
}
