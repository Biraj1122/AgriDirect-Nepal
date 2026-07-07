import 'dart:async';
import 'package:flutter/material.dart';
import 'package:farmtech_agridirect/models/product.dart';
import 'package:farmtech_agridirect/screens/shop/product_detail_screen.dart';
import 'package:farmtech_agridirect/screens/profile/notifications_screen.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmtech_agridirect/Success/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
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

    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 15),
                _buildActiveOrderBanner(user),
                const SizedBox(height: 20),
                const Text("Featured Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                _buildFeaturedSection(),
                const SizedBox(height: 25),
                const Text("Promos & Offers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                _buildPromoSection(),
                const SizedBox(height: 25),
                _buildCategoriesHeader(),
                const SizedBox(height: 12),
                _buildCategoriesSection(),
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
              "Hello, ${widget.userName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(_getTimeBasedGreeting(), style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: widget.onFavoritesTap,
              icon: const Icon(Icons.favorite_border, color: Colors.red),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_none_outlined),
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
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final orderDoc = snapshot.data!.docs.first;
        final order = orderDoc.data() as Map<String, dynamic>;
        final status = order['status'] ?? 'Pending';
        final orderId = orderDoc.id;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderScreen(
                  orderId: orderId,
                  onBackToHome: () => Navigator.pop(context),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Track Your Delivery",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        _getStatusMessage(status),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSection() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('master_catalog').limit(6).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          List<DocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : [];
          
          if (docs.isEmpty) {
            // Fallback to products collection if master_catalog is empty
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').limit(6).snapshots(),
              builder: (context, prodSnapshot) {
                if (prodSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                final pDocs = prodSnapshot.hasData ? prodSnapshot.data!.docs : <DocumentSnapshot>[];
                if (pDocs.isEmpty) return _buildDefaultFeatured();
                return _buildFeaturedPager(pDocs.cast<DocumentSnapshot>());
              },
            );
          }
          
          return _buildFeaturedPager(docs);
        },
      ),
    );
  }

  Widget _buildFeaturedPager(List<DocumentSnapshot> docs) {
    if (_featuredCount != docs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _featuredCount = docs.length);
      });
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _featuredTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _startFeaturedTimer();
        }
        return false;
      },
      child: PageView.builder(
        controller: _featuredPageController,
        onPageChanged: (idx) => _currentFeaturedIndex = idx,
        itemCount: docs.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final product = Product.fromMap(data, docId: docs[index].id);
          return _buildFeaturedCard(context, product);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Product product) {
    bool isFavourite = widget.favouriteProducts.any((p) =>
        (p['name'] == product.title || p['title'] == product.title) ||
        (product.id != null && (p['docId'] == product.id || p['id'] == product.id))
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              isFavourite: isFavourite,
              onToggleFavourite: widget.onFavouriteToggle,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(child: SafeProductImage(imageUrl: product.image)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Text("FEATURED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),
                    Text(product.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Rs. ${product.price}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    final productMap = product.toMap();
                    productMap['badge'] = 'Featured';
                    productMap['badgeColor'] = Colors.green.toARGB32();
                    productMap['farm'] = product.farmName ?? 'Local Farm';
                    productMap['rating'] = 4.8;
                    widget.onFavouriteToggle(productMap);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    radius: 18,
                    child: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultFeatured() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, color: Colors.white, size: 50),
            SizedBox(height: 10),
            Text("Fresh Produce Daily", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
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
          _buildPromoCard("10% OFF", "On all organic vegetables", Colors.orange, Icons.percent),
          _buildPromoCard("FREE DELIVERY", "Orders above Rs. 2000", Colors.blue, Icons.local_shipping),
          _buildPromoCard("COMBO DEALS", "Get freebies on every purchase over Rs.5000", Colors.purple, Icons.card_giftcard),
        ],
      ),
    );
  }

  Widget _buildPromoCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: () => widget.onCategoryTap(""),
          child: const Text("See all", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                categoryItem(Icons.grid_view_rounded, "All"),
                categoryItem(Icons.eco_outlined, "Vegetables"),
                categoryItem(Icons.apple_outlined, "Fruits"),
                categoryItem(Icons.grain, "Grains"),
                categoryItem(Icons.local_drink_outlined, "Dairy"),
                categoryItem(Icons.lens_blur, "Pulses"),
              ],
            );
          }

          final fetched = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['name'] ?? 'Category';
          }).toList();

          // Sort categories: Vegetables first, then Fruits, then others
          fetched.sort((a, b) {
            final nameA = a.toString().toLowerCase();
            final nameB = b.toString().toLowerCase();
            
            if (nameA == 'vegetables') return -1;
            if (nameB == 'vegetables') return 1;
            if (nameA == 'fruits') return -1;
            if (nameB == 'fruits') return 1;
            
            return nameA.compareTo(nameB);
          });

          final displayCategories = ["All", ...fetched];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final name = displayCategories[index];
              final displayIcon = _getCategoryIcon(name);
              return categoryItem(displayIcon, name);
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'all': return Icons.grid_view_rounded;
      case 'vegetables': return Icons.eco_outlined;
      case 'fruits': return Icons.apple_outlined;
      case 'grains': return Icons.grain;
      case 'dairy': return Icons.local_drink_outlined;
      case 'pulses': return Icons.lens_blur;
      default: return Icons.category_rounded;
    }
  }

  Widget categoryItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap(title),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.green, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }
}
