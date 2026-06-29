import 'dart:async';
import 'package:flutter/material.dart';
import 'package:farmtech_agridirect/models/product.dart';
import 'package:farmtech_agridirect/screens/shop/product_detail_screen.dart';
import 'package:farmtech_agridirect/screens/profile/notifications_screen.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  int _itemCount = 0;

  int _featuredCount = 0;

  @override
  void initState() {
    super.initState();
    _startFeaturedTimer();
  }

  void _startFeaturedTimer() {
    _featuredTimer?.cancel();
    _featuredTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_featuredPageController.hasClients && _itemCount > 1) {
        int nextIndex = (_currentFeaturedIndex + 1) % _itemCount;
      if (_featuredPageController.hasClients && _featuredCount > 0) {
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
      backgroundColor: const Color(0xffF7F8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Text(_getTimeBasedGreeting(), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onFavoritesTap,
                        icon: const Icon(Icons.favorite_border, color: Colors.red),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                            icon: const Icon(Icons.notifications_none),
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
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "${snapshot.data!.docs.length}",
                                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', whereIn: ['Pending Farmer', 'Farmer Accepted', 'Picked Up', 'On the way', 'Arrived'])
                      // Removed orderBy to avoid index requirement
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("Firestore Order Stream Error: ${snapshot.error}");
                      return const SizedBox();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    // Sort in memory
                    final docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                      final aTime = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      final bTime = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      return bTime.compareTo(aTime);
                    });

                    final order = docs.first.data() as Map<String, dynamic>;
                    final status = order['status'] ?? 'Pending';
                    final orderId = docs.first.id;

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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.green, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Your Order is Moving!", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    _getStatusMessage(status),
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              const Text("Featured Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: StreamBuilder<QuerySnapshot>(
                  // Try master_catalog first, then fall back to products if empty
                  stream: FirebaseFirestore.instance.collection('master_catalog').limit(6).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(fontSize: 12)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(child: Text("No featured items available", style: TextStyle(color: Colors.grey))),
                      );
                    }
                    final products = snapshot.data!.docs;
                    _itemCount = products.length;

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
                        itemCount: products.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final data = products[index].data() as Map<String, dynamic>;
                          final product = Product.fromMap(data, docId: products[index].id);
                          return _buildFeaturedCard(context, product);
                        },
                      ),
                    );
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      // Fallback to regular products if master_catalog is empty
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('products').limit(6).snapshots(),
                        builder: (context, prodSnapshot) {
                          if (!prodSnapshot.hasData || prodSnapshot.data!.docs.isEmpty) {
                            return _buildDefaultFeatured();
                          }
                          return _buildFeaturedPager(prodSnapshot.data!.docs);
                        },
                      );
                    }
                    
                    return _buildFeaturedPager(snapshot.data!.docs);
                  },
                ),
              ),

              const SizedBox(height: 25),

              const Text("Promos & Offers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPromoCard("10% OFF", "On all organic vegetables", Colors.orange, Icons.percent),
                    _buildPromoCard("FREE DELIVERY", "Orders above Rs. 2000", Colors.blue, Icons.local_shipping),
                    _buildPromoCard("COMBO DEALS", "Get freebies on every purchase", Colors.purple, Icons.card_giftcard),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  TextButton(
                    onPressed: () => widget.onCategoryTap(""),
                    child: const Text("See all", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }
                    
                    final List<Map<String, dynamic>> fallbackCategories = [
                      {"name": "Vegetables", "icon": Icons.eco_outlined},
                      {"name": "Fruits", "icon": Icons.apple_outlined},
                      {"name": "Grains", "icon": Icons.grain},
                      {"name": "Dairy", "icon": Icons.local_drink_outlined},
                      {"name": "Pulses", "icon": Icons.lens_blur},
                      {"name": "Mushrooms", "icon": Icons.spa},
                      {"name": "Tea & Coffee", "icon": Icons.local_cafe_outlined},
                      {"name": "Spices", "icon": Icons.flare},
                      {"name": "Specialty", "icon": Icons.star_border},
                    ];

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fallbackCategories.length,
                        itemBuilder: (context, index) => categoryItem(
                          context, 
                          fallbackCategories[index]['icon'] as IconData, 
                          fallbackCategories[index]['name']
                        ),
                       return const Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2));
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          categoryItem(context, Icons.eco_outlined, "Vegetables"),
                          categoryItem(context, Icons.apple_outlined, "Fruits"),
                          categoryItem(context, Icons.grain, "Grains"),
                          categoryItem(context, Icons.local_drink_outlined, "Dairy"),
                          categoryItem(context, Icons.lens_blur, "Pulses"),
                        ],
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final cat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final name = cat['name'] ?? 'Category';
                        final iconCode = cat['iconCode'] as int?;

                        final displayIcon = iconCode != null
                            ? IconData(iconCode, fontFamily: 'MaterialIcons')
                            : Icons.category_rounded;

                        return categoryItem(context, displayIcon, name);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedPager(List<DocumentSnapshot> docs) {
    if (_featuredCount != docs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _featuredCount = docs.length);
      });
    }

    return PageView.builder(
      controller: _featuredPageController,
      onPageChanged: (idx) => setState(() => _currentFeaturedIndex = idx),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final product = Product.fromMap(data, docId: docs[index].id);
        return _buildFeaturedCard(context, product);
      },
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
          color: Colors.grey.shade200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: product.image.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                        errorWidget: (context, url, error) => Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
                      )
                    : Image.asset(
                        product.image.isNotEmpty ? product.image : 'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
              _buildSafeFeaturedImage(product.image),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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

                    // Add feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavourite ? "Removed from Favourites" : "Added to Favourites"),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: isFavourite ? Colors.black87 : Colors.redAccent,
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildSafeFeaturedImage(String image) {
    if (image.isEmpty) {
      return Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.image, color: Colors.white, size: 40)));
    }
    
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 40)),
        ),
      );
    }
    
    String assetPath = image;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$image';
    }
    
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.green.shade100,
        child: const Center(child: Icon(Icons.eco, color: Colors.green, size: 40)),
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

  Widget _buildPromoCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Pending Farmer':
        return "Routing to nearest farm...";
      case 'Farmer Accepted':
        return "Farm is preparing items...";
      case 'Picked Up':
        return "Rider picked up from farm";
      case 'On the way':
        return "Rider is on the way to you";
      case 'Arrived':
        return "Order almost delivered!";
      default:
        return "Order in progress";
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning";
    } else if (hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  Widget categoryItem(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap(title),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, color: Colors.green, size: 28),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
