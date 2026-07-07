import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';
import 'package:farmtech_agridirect/viewmodels/farmer_viewmodel.dart';
import 'package:farmtech_agridirect/models/order_model.dart';
import 'package:farmtech_agridirect/models/product.dart';
import 'package:farmtech_agridirect/Success/skeleton_loader.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Success/exit_wrapper.dart';
import '../../Success/shared_widgets.dart';
import 'farm_osm_screen.dart';

const Color primaryTeal = Color(0xFF1D9E75);

class FarmerScreen extends StatelessWidget {
  const FarmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmerViewModel>();

    if (vm.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    final String farmName = vm.farmerData?['farmName'] ?? 'AgriDirect Farm';

    final List<Widget> pages = [
      const _FarmerHomeScreen(),
      const _FarmerStoreScreen(),
      const _FarmerOrdersScreen(),
      const _FarmerProfileScreen(),
    ];

    return DoubleBackExitWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            farmName,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () => vm.logout(context, const LoginScreen()),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[vm.currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: vm.currentIndex,
            onTap: (i) => vm.setCurrentIndex(i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: primaryTeal,
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
      ),
    );
  }
}

class _FarmerHomeScreen extends StatefulWidget {
  const _FarmerHomeScreen();

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
        int nextIndex = _currentCarouselIndex + 1;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FarmerViewModel>();
    final farmerName = vm.farmerData?['fullName'] ?? vm.farmerData?['name'] ?? 'Farmer';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 15),
        Center(
          child: Column(
            children: [
              Text(
                "Namaste, $farmerName!",
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25), letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  "Hope your harvest is plentiful today.",
                  style: TextStyle(color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "NEW ORDERS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade400,
                letterSpacing: 1.5,
              ),
            ),
            StreamBuilder<List<OrderModel>>(
              stream: vm.getNewOrders(),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                if (count == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                  child: Text("$count ACTIVE", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<OrderModel>>(
          stream: vm.getNewOrders(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SkeletonLoader(height: 250, borderRadius: 32);
            }
            final docs = snap.data ?? [];
            
            return SizedBox(
              height: 250,
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
                      return _buildNewOrderBanner(docs[index]);
                    },
                  ),
                  if (docs.isNotEmpty)
                    Positioned(
                      bottom: 25,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          docs.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(left: 6),
                            width: _currentCarouselIndex == index ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentCarouselIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
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

        const SizedBox(height: 40),
        Text(
          "BUSINESS OVERVIEW",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<List<OrderModel>>(
          stream: vm.getFarmerOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(
                children: [
                  Expanded(child: SkeletonLoader(height: 140, borderRadius: 32)),
                  SizedBox(width: 16),
                  Expanded(child: SkeletonLoader(height: 140, borderRadius: 32)),
                ],
              );
            }
            final orders = snapshot.data ?? [];
            double totalEarnings = 0;
            int activeTasks = 0;
            List<OrderModel> deliveredOrders = [];

            for (var order in orders) {
              if (order.status == 'Delivered' || order.status == 'Confirm Received') {
                totalEarnings += order.farmerRevenue ?? 0;
                deliveredOrders.add(order);
              } else if (['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'].contains(order.status)) {
                activeTasks++;
              }
            }

            return Row(
              children: [
                _BusinessCard(
                  title: "Total Revenue",
                  value: "Rs. ${totalEarnings.toStringAsFixed(0)}",
                  icon: Icons.account_balance_wallet_rounded,
                  colors: [primaryTeal, const Color(0xFF4DB6AC)],
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No New Orders", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(
                  "Sit back and relax! We'll notify you when new orders arrive in your area.",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.eco_rounded, color: Colors.white.withValues(alpha: 0.1), size: 100),
        ],
      ),
    );
  }

  Widget _buildNewOrderBanner(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("New Order!", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                "Order for pickup near ${order.deliveryAddress.split(',').last.trim()}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => _acceptOrderDialog(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("View & Accept", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.shopping_basket_rounded, color: Colors.white.withValues(alpha: 0.1), size: 120),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrderDialog(BuildContext context, OrderModel order) async {
    final vm = context.read<FarmerViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Order?"),
        content: Text("Total Items: ${order.items.length}\nItems: ${order.itemsSummary}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Accept", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final farmName = vm.farmerData?['farmName'] ?? 'AgriDirect Farm';
      final double? fLat = (vm.farmerData?['farmLat'] as num?)?.toDouble();
      final double? fLng = (vm.farmerData?['farmLng'] as num?)?.toDouble();

      await vm.acceptOrder(order.id, fLat, fLng, farmName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order accepted! Check 'Orders' tab for details.")),
        );
      }
    }
  }

  void _showIncomeDetails(BuildContext context, List<OrderModel> docs, double total) {
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
                  final order = docs[i];
                  final gross = order.total;
                  final net = order.farmerRevenue ?? 0;
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
                            Text("Order #${order.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text("Rs. ${gross.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 32),
                        _detailRow("Gross Sale Amount", gross),
                        const SizedBox(height: 8),
                        _detailRow("App Commission (20%)", -commission, isNegative: true),
                        const Divider(height: 32),
                        _detailRow("Your Earnings", net, isBold: true, color: primaryTeal),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.1), 
                blurRadius: 20, 
                offset: const Offset(0, 10)
              ),
            ],
            border: Border.all(color: Colors.grey.shade50),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 24),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerStoreScreen extends StatelessWidget {
  const _FarmerStoreScreen();

  void _showAddProduct(BuildContext context) {
    final vm = context.read<FarmerViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductForm(uid: vm.uid, farmName: vm.farmerData?['farmName'] ?? 'Farm'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmerViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProduct(context),
        backgroundColor: primaryTeal,
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
            child: StreamBuilder<List<Product>>(
              stream: vm.getFarmerProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: SkeletonLoader(height: 94, borderRadius: 20),
                    ),
                  );
                }
                final products = snapshot.data ?? [];

                if (products.isEmpty) {
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
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final product = products[i];
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
                            child: Hero(
                              tag: product.id ?? 'prod_$i',
                              child: CachedNetworkImage(
                                imageUrl: product.image,
                                width: 70, height: 70, fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                errorWidget: (context, url, error) => Container(color: Colors.green.shade50, child: const Icon(Icons.eco_rounded, color: primaryTeal)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1A1D25))),
                                const SizedBox(height: 4),
                                Text("Rs. ${product.price} / ${product.unit}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => _ProductForm(
                                  uid: vm.uid, 
                                  farmName: vm.farmerData?['farmName'] ?? 'Farm',
                                  existingProduct: product.toMap()..['id'] = product.id,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteProduct(context, product.id!),
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

  Future<void> _deleteProduct(BuildContext context, String id) async {
    final vm = context.read<FarmerViewModel>();
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
      await vm.deleteProduct(id);
    }
  }
}

class _FarmerOrdersScreen extends StatelessWidget {
  const _FarmerOrdersScreen();

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
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: primaryTeal,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _FarmerOrderList(statuses: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived']),
                _FarmerOrderList(statuses: ['Delivered', 'Cancelled', 'Confirm Received']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerOrderList extends StatelessWidget {
  final List<String> statuses;
  const _FarmerOrderList({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmerViewModel>();
    return StreamBuilder<List<OrderModel>>(
      stream: vm.getFarmerOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 3,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SkeletonLoader(height: 180, borderRadius: 28),
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        final docs = allOrders.where((o) => statuses.contains(orderStatusToString(o.status))).toList();

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
            return _DeliveryCard(order: docs[i]);
          },
        );
      },
    );
  }

  String orderStatusToString(dynamic status) {
    if (status is String) return status;
    return status.toString();
  }
}

class _FarmerProfileScreen extends StatefulWidget {
  const _FarmerProfileScreen();

  @override
  State<_FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<_FarmerProfileScreen> {
  bool _isUploading = false;

  Future<void> _updateProfilePhoto() async {
    final vm = context.read<FarmerViewModel>();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadImage(img, 'profile_pics');
      if (url != null) {
        await vm.updateProfileImage(url);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _updateLocation() async {
    final vm = context.read<FarmerViewModel>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final String address = result['address'];
      final double lat = result['lat'];
      final double lng = result['lng'];

      await vm.updateFarmLocation(address, lat, lng);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Farm location updated successfully!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmerViewModel>();
    final farmerName = vm.farmerData?['fullName'] ?? vm.farmerData?['name'] ?? 'Farmer';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final farmLocation = vm.farmerData?['farmLocation'] ?? 'Location not set';
    final profileImageUrl = vm.farmerData?['profileImageUrl'];

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
                      backgroundColor: primaryTeal.withValues(alpha: 0.1),
                      backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(profileImageUrl!) : null,
                      child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                          ? const Icon(Icons.agriculture_rounded, size: 70, color: primaryTeal) : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(child: CircularProgressIndicator(color: primaryTeal)),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(farmerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
              const SizedBox(height: 4),
              Text(email, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 16)),
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
              subtitle: farmLocation,
              trailing: const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 30),

        _ProfileSection(
          title: "APP SETTINGS",
          items: [
            _ProfileItem(
              icon: Icons.map_rounded,
              title: "Update Farm Location",
              onTap: _updateLocation,
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

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryTeal, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1D25))),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4)) : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final String uid, farmName;
  final Map<String, dynamic>? existingProduct;

  const _ProductForm({
    required this.uid, 
    required this.farmName, 
    this.existingProduct,
  });

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final name = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController(text: 'kg');
  final stock = TextEditingController(text: '100');
  XFile? selectedImage;
  bool isUploading = false;

  bool get isEditing => widget.existingProduct != null;
  String? get productId => widget.existingProduct?['id'];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      name.text = widget.existingProduct!['name'] ?? '';
      price.text = widget.existingProduct!['price']?.toString() ?? '';
      unit.text = widget.existingProduct!['unit'] ?? 'kg';
      stock.text = widget.existingProduct!['stock']?.toString() ?? '100';
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    unit.dispose();
    stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FarmerViewModel>();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Heading(title: isEditing ? "Edit Product" : "Add New Product", subtitle: "List your fresh produce on the market"),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final img = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 600,
                    maxHeight: 600,
                    imageQuality: 60,
                  );
                  if (img != null) setState(() => selectedImage = img);
                },
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(File(selectedImage!.path), fit: BoxFit.cover))
                      : (isEditing && widget.existingProduct!['image'] != null)
                        ? ClipRRect(borderRadius: BorderRadius.circular(24), child: CachedNetworkImage(imageUrl: widget.existingProduct!['image'], fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo_rounded, color: Colors.grey, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FieldLabel(label: "PRODUCT NAME"),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: customInputDecoration(hint: "e.g. Fresh Tomatoes", icon: Icons.eco, teal: primaryTeal)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel(label: "PRICE"),
                      const SizedBox(height: 8),
                      TextField(controller: price, keyboardType: TextInputType.number, decoration: customInputDecoration(hint: "0.00", icon: Icons.payments, teal: primaryTeal)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel(label: "UNIT"),
                      const SizedBox(height: 8),
                      TextField(controller: unit, decoration: customInputDecoration(hint: "kg/ltr/bunch", icon: Icons.scale, teal: primaryTeal)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const FieldLabel(label: "STOCK QUANTITY"),
            const SizedBox(height: 8),
            TextField(controller: stock, keyboardType: TextInputType.number, decoration: customInputDecoration(hint: "100", icon: Icons.inventory_2_outlined, teal: primaryTeal)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
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

                  setState(() => isUploading = true);

                  try {
                    if (isEditing) {
                      await vm.requestPriceUpdate({
                        'productId': productId,
                        'productName': name.text,
                        'farmerUid': widget.uid,
                        'farmName': widget.farmName,
                        'oldPrice': double.tryParse(widget.existingProduct!['price']?.toString() ?? '0') ?? 0,
                        'newPrice': priceVal,
                        'oldUnit': widget.existingProduct!['unit'] ?? 'kg',
                        'newUnit': unit.text,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price update request sent to admin")));
                    } else {
                      if (selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
                        if (mounted) setState(() => isUploading = false);
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
                        throw "Error uploading image: $e";
                      }

                      await vm.addProduct({
                        'name': name.text,
                        'title': name.text,
                        'price': priceVal,
                        'farmerUid': widget.uid,
                        'farmName': widget.farmName,
                        'unit': unit.text,
                        'stock': int.tryParse(stock.text) ?? 100,
                        'image': imageUrl,
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': 'pending',
                      });
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product listed! Waiting for admin approval.")));
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  } finally {
                    if (mounted) setState(() => isUploading = false);
                  }
                },
                child: isUploading ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? "Request Price Update" : "List Product", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FarmerViewModel>();
    final String status = order.status;
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
              Expanded(child: Text("Order #${order.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1A1D25)))),
              _statusChip(status, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.itemsSummary, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          if (!isHistory) ...[
            const Divider(height: 32),
            Text("Total: Rs. ${order.total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w800, color: primaryTeal)),
            const SizedBox(height: 16),
            if (status == 'Farmer Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => vm.markReadyForPickup(order.id, order.userId, vm.farmerData?['farmName'] ?? 'Farm'),
                  child: const Text("Ready for Pickup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            if (order.deliveryId != null && order.deliveryId != "") ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _TrackRiderMapScreen(
                          orderId: order.id,
                          riderId: order.deliveryId!,
                          orderData: order.toFirestore(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text("Track Rider"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
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
  MapLibreMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Track Rider - #${widget.orderId.substring(0, 8).toUpperCase()}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.riderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final riderData = snapshot.data!.data() as Map<String, dynamic>?;
          final double? riderLat = (riderData?['lat'] as num?)?.toDouble();
          final double? riderLng = (riderData?['lng'] as num?)?.toDouble();

          if (riderLat == null || riderLng == null) {
            return const Center(child: Text("Rider location not available"));
          }

          final riderPos = LatLng(riderLat, riderLng);

          return Stack(
            children: [
              MapLibreMap(
                initialCameraPosition: CameraPosition(target: riderPos, zoom: 14),
                onMapCreated: (controller) => mapController = controller,
                styleString: "https://tiles.openfreemap.org/styles/positron",
                logoEnabled: false,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              child: const Icon(Icons.person, color: Colors.green),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(riderData?['fullName'] ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(riderData?['phone'] ?? 'No phone info', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                // Dialer link here
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Text("Status: ${widget.orderData['status']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
