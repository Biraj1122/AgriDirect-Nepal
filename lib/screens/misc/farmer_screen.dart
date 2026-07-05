import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../Success/shared_widgets.dart';
import 'farm_osm_screen.dart';

class FarmerScreen extends StatefulWidget {
  const FarmerScreen({super.key});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _farmerData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logout();
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        if (doc.exists && doc.data()?['role'] == 'Farmer') {
          setState(() {
            _farmerData = doc.data();
            _loading = false;
          });
        } else {
          _logout();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));

    final String farmerName = _farmerData?['fullName'] ?? _farmerData?['name'] ?? 'Farmer';
    final String farmName = _farmerData?['farmName'] ?? 'AgriDirect Farm';
    final String farmLocation = _farmerData?['farmLocation'] ?? 'Location not set';
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> pages = [
      _FarmerHomeScreen(
        farmerName: farmerName,
        farmName: farmName,
        uid: uid,
        farmerLat: _farmerData?['farmLat'],
        farmerLng: _farmerData?['farmLng'],
      ),
      _FarmerStoreScreen(
        uid: uid,
        farmName: farmName,
        farmerLat: _farmerData?['farmLat'],
        farmerLng: _farmerData?['farmLng'],
      ),
      _FarmerOrdersScreen(uid: uid),
      _FarmerProfileScreen(
        farmerName: farmerName,
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        farmLocation: farmLocation,
        uid: uid,
        profileImageUrl: _farmerData?['profileImageUrl'],
        phone: _farmerData?['phone'] ?? '',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(farmName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1D9E75),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'My Store'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _FarmerHomeScreen extends StatefulWidget {
  final String farmerName, farmName, uid;
  final double? farmerLat, farmerLng;
  const _FarmerHomeScreen({
    required this.farmerName,
    required this.farmName,
    required this.uid,
    this.farmerLat,
    this.farmerLng,
  });

  @override
  State<_FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<_FarmerHomeScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int next = _currentCarouselIndex + 1;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Column(
            children: [
              Text(
                "Namaste, ${widget.farmerName}!",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25), letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                "Hope your harvest is plentiful today.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'Pending Farmer')
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList() ?? [];
            
            return SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentCarouselIndex = i % (docs.isEmpty ? 1 : docs.length)),
                    itemBuilder: (context, i) {
                      if (docs.isEmpty) {
                        return _buildEmptyOrderBanner();
                      }
                      final index = i % docs.length;
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildNewOrderBanner(docs[index].id, data);
                    },
                  ),
                  if (docs.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      right: 25,
                      child: Row(
                        children: List.generate(
                          docs.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: _currentCarouselIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentCarouselIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 35),
        Text(
          "BUSINESS OVERVIEW",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            double totalEarnings = 0;
            int activeTasks = 0;
            List<QueryDocumentSnapshot> deliveredOrders = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['status'] == 'Delivered' || data['status'] == 'Confirm Received') {
                totalEarnings += (data['farmerRevenue'] ?? 0).toDouble();
                deliveredOrders.add(doc);
              } else if (['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'].contains(data['status'])) {
                activeTasks++;
              }
            }

            return Row(
              children: [
                _BusinessCard(
                  title: "Total Revenue",
                  value: "Rs. ${totalEarnings.toStringAsFixed(0)}",
                  icon: Icons.account_balance_wallet_rounded,
                  colors: [const Color(0xFF1D9E75), const Color(0xFF4DB6AC)],
                  onTap: () => _showIncomeDetails(context, deliveredOrders, totalEarnings),
                ),
                const SizedBox(width: 16),
                _BusinessCard(
                  title: "Active Tasks",
                  value: "$activeTasks",
                  icon: Icons.assignment_turned_in_rounded,
                  colors: [const Color(0xFF448AFF), const Color(0xFF2979FF)],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildEmptyOrderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9E75), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No New Orders", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  "Sit back and relax! We'll notify you when new orders arrive in your area.",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.eco_rounded, color: Colors.white.withValues(alpha: 0.2), size: 80),
        ],
      ),
    );
  }

  Widget _buildNewOrderBanner(String orderId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9E75), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1D9E75).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("New Order Available", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                "A new order of ${data['items']?.length ?? 0} items is available for pickup near ${data['deliveryAddress']?.toString().split(',').last.trim() ?? 'you'}...",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _acceptOrder(orderId, data),
                icon: Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.3), size: 70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Order?"),
        content: Text("Total: Rs. ${data['total']}\nItems: ${data['itemsSummary']}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Accept", style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final fresh = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (fresh.data()?['farmerUid'] != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order already accepted by another farm.")));
        return;
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Farmer Accepted',
        'farmerUid': widget.uid,
        'farmName': widget.farmName,
        'farmerLat': widget.farmerLat,
        'farmerLng': widget.farmerLng,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order accepted! Check 'Orders' tab for details.")));
    }
  }

  void _showIncomeDetails(BuildContext context, List<QueryDocumentSnapshot> docs, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Heading(title: "Income Details", subtitle: "Breakdown of your earnings (80% share)"),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final gross = (data['total'] ?? 0).toDouble();
                  final net = (data['farmerRevenue'] ?? 0).toDouble();
                  final commission = gross - net;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Order #${docs[i].id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text("Rs. ${gross.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 32),
                        _detailRow("Gross Sale Amount", gross),
                        const SizedBox(height: 8),
                        _detailRow("App Commission (20%)", -commission, isNegative: true),
                        const Divider(height: 32),
                        _detailRow("Your Earnings", net, isBold: true, color: const Color(0xFF1D9E75)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, double amount, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        Text(
          "${isNegative ? '-' : ''}Rs. ${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, 
            color: color ?? (isNegative ? Colors.redAccent : Colors.black87),
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;
  const _BusinessCard({required this.title, required this.value, required this.icon, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
                ],
              ),
              const SizedBox(height: 20),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerStoreScreen extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;
  const _FarmerStoreScreen({required this.uid, required this.farmName, this.farmerLat, this.farmerLng});

  @override
  State<_FarmerStoreScreen> createState() => _FarmerStoreScreenState();
}

class _FarmerStoreScreenState extends State<_FarmerStoreScreen> {
  void _showAddProduct() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductForm(uid: widget.uid, farmName: widget.farmName, farmerLat: widget.farmerLat, farmerLng: widget.farmerLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProduct,
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("My Products", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
                SizedBox(height: 4),
                Text("Manage your farm products for sale", style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 100, color: Colors.grey.shade100),
                        const SizedBox(height: 16),
                        Text("No products listed yet", style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: data['image'] ?? '',
                              width: 70, height: 70, fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade100),
                              errorWidget: (context, url, error) => Container(color: Colors.green.shade50, child: const Icon(Icons.eco_rounded, color: Color(0xFF1D9E75))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1A1D25))),
                                const SizedBox(height: 4),
                                Text("Rs. ${data['price']} / ${data['unit'] ?? 'kg'}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteProduct(docs[i].id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
    }
  }
}

class _FarmerOrdersScreen extends StatelessWidget {
  final String uid;
  const _FarmerOrdersScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Heading(title: "Orders", subtitle: "Track your outgoing deliveries"),
          const SizedBox(height: 20),
          TabBar(
            labelColor: const Color(0xFF1D9E75),
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: const Color(0xFF1D9E75),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FarmerOrderList(uid: uid, statuses: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived']),
                _FarmerOrderList(uid: uid, statuses: ['Delivered', 'Cancelled', 'Confirm Received']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerOrderList extends StatelessWidget {
  final String uid;
  final List<String> statuses;
  const _FarmerOrderList({required this.uid, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('farmerUid', isEqualTo: uid)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade100),
                const SizedBox(height: 16),
                Text("No orders found", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _DeliveryCard(orderId: docs[i].id, data: data, docRef: docs[i].reference);
          },
        );
      },
    );
  }
}

class _FarmerProfileScreen extends StatefulWidget {
  final String farmerName, email, farmLocation, uid;
  final String? profileImageUrl;
  final String phone;
  const _FarmerProfileScreen({
    required this.farmerName, 
    required this.email, 
    required this.farmLocation, 
    required this.uid,
    this.profileImageUrl,
    required this.phone,
  });

  @override
  State<_FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<_FarmerProfileScreen> {
  bool _isUploading = false;

  Future<void> _updateProfilePhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadImage(img, 'profile_pics');
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'profileImageUrl': url,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showChangePasswordDialog() {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F4E8), // Light natural green tint
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Center(
          child: Text(
            "Change Password",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1A1D25)),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(currentPass, "Current Password", Icons.lock_outline_rounded),
            const SizedBox(height: 12),
            _dialogField(newPass, "New Password", Icons.vpn_key_outlined),
            const SizedBox(height: 12),
            _dialogField(confirmPass, "Confirm New Password", Icons.check_circle_outline_rounded),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (newPass.text != confirmPass.text || newPass.text.length < 6) return;
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPass.text,
                      );
                      
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPass.text);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Future<void> _updateLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final String address = result['address'];
      final double lat = result['lat'];
      final double lng = result['lng'];

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'farmLocation': address,
        'farmLat': lat,
        'farmLng': lng,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Farm location updated successfully!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        const SizedBox(height: 10),
        const Heading(title: "Farm Profile", subtitle: "Manage your professional settings"),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _updateProfilePhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                      backgroundImage: (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(widget.profileImageUrl!) : null,
                      child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
                          ? const Icon(Icons.agriculture_rounded, size: 70, color: Color(0xFF1D9E75)) : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(widget.farmerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
              const SizedBox(height: 4),
              Text(widget.email, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        _ProfileSection(
          title: "FARM LOCATION",
          items: [
            _ProfileItem(
              icon: Icons.location_on_rounded,
              title: "Pickup Address",
              subtitle: widget.farmLocation,
              trailing: const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 30),

        _ProfileSection(
          title: "APP SETTINGS",
          items: [
            _ProfileItem(
              icon: Icons.wb_sunny_rounded,
              title: "Dark Mode",
              trailing: Switch.adaptive(
                value: false,
                onChanged: (v) {},
                activeTrackColor: const Color(0xFF1D9E75),
              ),
              iconColor: Colors.orange.shade300,
              iconBg: Colors.orange.shade50,
            ),
            _ProfileItem(
              icon: Icons.map_rounded,
              title: "Update Farm Location",
              onTap: _updateLocation,
            ),
          ],
        ),
        const SizedBox(height: 30),

        _ProfileSection(
          title: "SECURITY",
          items: [
            _ProfileItem(
              icon: Icons.lock_reset_rounded,
              title: "Change Password",
              onTap: _showChangePasswordDialog,
              iconColor: const Color(0xFF1D9E75),
              iconBg: const Color(0xFFE8F5E9),
            ),
            _ProfileItem(
              icon: Icons.verified_user_rounded,
              title: "Verified Farmer Partner",
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF1D9E75), size: 20),
              iconColor: const Color(0xFF1D9E75),
              iconBg: const Color(0xFFE8F5E9),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor, iconBg;

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg ?? Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF1D9E75), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1D25))),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4)) : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;
  final Map<String, dynamic>? existingProduct;
  final String? productId;

  const _ProductForm({required this.uid, required this.farmName, this.farmerLat, this.farmerLng, this.existingProduct, this.productId});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final name = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final unit = TextEditingController(text: 'kg');
  XFile? selectedImage;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      name.text = widget.existingProduct!['name'] ?? '';
      price.text = widget.existingProduct!['price']?.toString() ?? '';
      stock.text = widget.existingProduct!['stock']?.toString() ?? '100';
      unit.text = widget.existingProduct!['unit'] ?? 'kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingProduct != null;
    String productId = widget.productId ?? '';
    final existingProduct = widget.existingProduct ?? {};

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? "Edit Product" : "Add New Product", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (!isEditing) Center(
              child: GestureDetector(
                onTap: () async {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (img != null) setState(() => selectedImage = img);
                },
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(selectedImage!.path), fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: name, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (Rs.)", border: OutlineInputBorder()))),
                const SizedBox(width: 15),
                Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: "Unit (e.g. kg, bundle)", border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 15),
            TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Stock Quantity", border: OutlineInputBorder())),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
                onPressed: isUploading ? null : () async {
                  if (name.text.isEmpty || price.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
                    return;
                  }

                  final double? priceVal = double.tryParse(price.text);
                  if (priceVal == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid numeric price")));
                    return;
                  }

                  setModalState(() => isUploading = true);

                  try {
                    if (isEditing) {
                      await FirebaseFirestore.instance.collection('price_requests').add({
                        'productId': productId,
                        'productName': name.text,
                        'farmerUid': widget.uid,
                        'farmName': widget.farmName,
                        'oldPrice': double.tryParse(existingProduct['price']?.toString() ?? '0') ?? 0,
                        'newPrice': priceVal,
                        'oldUnit': existingProduct['unit'] ?? 'kg',
                        'newUnit': unit.text,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price update request sent to admin")));
                    } else {
                      if (selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
                        setModalState(() => isUploading = false);
                        return;
                      }

                      String? imageUrl;
                      try {
                        final storageService = StorageService();
                        imageUrl = await storageService.uploadImage(selectedImage!, 'products');
                        if (imageUrl == null) {
                          throw "Upload failed. Please check your internet connection.";
                        }
                      } catch (e) {
                        String errorMsg = "Error uploading image: $e";
                        throw errorMsg;
                      }

                      await FirebaseFirestore.instance.collection('products').add({
                        'name': name.text,
                        'title': name.text, // Added for compatibility with Product model
                        'price': priceVal,
                        'farmerUid': widget.uid,
                        'farmName': widget.farmName,
                        'farmerLat': widget.farmerLat,
                        'farmerLng': widget.farmerLng,
                        'unit': unit.text,
                        'stock': int.tryParse(stock.text) ?? 100,
                        'image': imageUrl,
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': 'pending', // New products need admin approval
                      });
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product listed! Waiting for admin approval.")));
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  } finally {
                    setModalState(() => isUploading = false);
                  }
                },
                child: isUploading ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? "Request Price Update" : "List Product", style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void setModalState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}

class _DeliveryCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final DocumentReference docRef;
  const _DeliveryCard({required this.orderId, required this.data, required this.docRef});

  @override
  Widget build(BuildContext context) {
    String status = data['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'Delivered' || status == 'Confirm Received') statusColor = Colors.green;
    if (status == 'Cancelled') statusColor = Colors.red;

    final isHistory = status == 'Delivered' || status == 'Cancelled' || status == 'Confirm Received';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Order #${orderId.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1A1D25)))),
              _statusChip(status, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(data['itemsSummary'] ?? 'Products ordered', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          if (!isHistory) ...[
            const Divider(height: 32),
            Text("Total: Rs. ${data['total'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D9E75))),
            const SizedBox(height: 16),
            if (status == 'Farmer Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await docRef.update({'status': 'Awaiting Pickup'});

                    final userId = data['userId'];
                    if (userId != null) {
                      await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
                        'title': 'Order Ready for Pickup',
                        'body': 'Your order has been packed and is ready for the delivery person.',
                        'createdAt': FieldValue.serverTimestamp(),
                        'isRead': false,
                        'type': 'delivery_status',
                        'status': 'Awaiting Pickup',
                        'orderId': orderId,
                      });
                    }

                    final ridersSnap = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'Delivery Person')
                        .get();

                    for (var rDoc in ridersSnap.docs) {
                      await FirebaseFirestore.instance.collection('users').doc(rDoc.id).collection('notifications').add({
                        'title': 'New Pickup Available!',
                        'body': 'A package is ready for pickup at ${data['farmName'] ?? 'a nearby farm'}.',
                        'createdAt': FieldValue.serverTimestamp(),
                        'isRead': false,
                        'type': 'pickup_alert',
                        'orderId': orderId,
                      });
                    }
                  },
                  child: const Text("Ready for Pickup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            if (data['deliveryId'] != null && data['deliveryId'] != "") ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _TrackRiderMapScreen(
                          orderId: orderId,
                          riderId: data['deliveryId'],
                          orderData: data,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text("Track Rider"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D9E75),
                    side: const BorderSide(color: Color(0xFF1D9E75)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _TrackRiderMapScreen extends StatefulWidget {
  final String orderId;
  final String riderId;
  final Map<String, dynamic> orderData;

  const _TrackRiderMapScreen({
    required this.orderId,
    required this.riderId,
    required this.orderData,
  });

  @override
  State<_TrackRiderMapScreen> createState() => _TrackRiderMapScreenState();
}

class _TrackRiderMapScreenState extends State<_TrackRiderMapScreen> {
  MapLibreMapController? _mapController;
  LatLng? _riderPos;
  Symbol? _riderSymbol;
  StreamSubscription? _riderSub;

  @override
  void initState() {
    super.initState();
    _listenToRider();
  }

  void _listenToRider() {
    _riderSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.riderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final newPos = LatLng(lat, lng);
          setState(() => _riderPos = newPos);
          _updateRiderMarker();
        }
      }
    });
  }

  void _updateRiderMarker() {
    if (_mapController != null && _riderPos != null) {
      if (_riderSymbol == null) {
        _mapController!.addSymbol(SymbolOptions(
          geometry: _riderPos!,
          iconImage: "airport-15",
          iconRotate: 90,
          iconColor: "#4CAF50",
          iconSize: 2.5,
          textField: "Rider",
          textSize: 10,
          textOffset: const Offset(0, 1.2),
        )).then((s) => _riderSymbol = s);
      } else {
        _mapController!.updateSymbol(_riderSymbol!, SymbolOptions(
          geometry: _riderPos!,
        ));
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;

    // Add Farmer (Self)
    final fLat = (widget.orderData['farmerLat'] as num?)?.toDouble();
    final fLng = (widget.orderData['farmerLng'] as num?)?.toDouble();
    if (fLat != null && fLng != null) {
      await _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(fLat, fLng),
        iconImage: "restaurant-15",
        iconColor: "#FFA000",
        iconSize: 2.0,
        textField: "My Hub",
        textSize: 10,
        textOffset: const Offset(0, 1.2),
      ));
    }

    // Add Customer
    final cLat = (widget.orderData['customerLat'] as num?)?.toDouble() ?? (widget.orderData['lat'] as num?)?.toDouble();
    final cLng = (widget.orderData['customerLng'] as num?)?.toDouble() ?? (widget.orderData['lng'] as num?)?.toDouble();
    if (cLat != null && cLng != null) {
      await _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(cLat, cLng),
        iconImage: "marker-15",
        iconColor: "#FF5252",
        iconSize: 2.0,
        textField: "Customer",
        textSize: 10,
        textOffset: const Offset(0, 1.2),
      ));
    }

    _updateRiderMarker();
  }

  @override
  void dispose() {
    _riderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Rider Location", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _riderPos ?? const LatLng(27.7172, 85.3240),
              zoom: 13,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            styleString: "https://tiles.openfreemap.org/styles/positron",
          ),
          if (_riderPos == null)
            const Center(child: CircularProgressIndicator(color: Colors.green)),
        ],
      ),
    );
  }
}
