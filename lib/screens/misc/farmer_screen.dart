import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';

class FarmerScreen extends StatefulWidget {
  const FarmerScreen({super.key});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _farmerData;
  bool _loading = true;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _orderSubscription;
  int _unreadCount = 0;
  int _pendingOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _setupGlobalListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _setupGlobalListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _unreadCount = snapshot.docs.length);
    });

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Pending Farmer')
        .snapshots()
        .listen((snapshot) {
      final pendingOrders = snapshot.docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList();
      final currentCount = pendingOrders.length;
      
      if (mounted) {
        if (currentCount > _pendingOrderCount && _currentIndex != 0) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("New order request available!"),
              backgroundColor: Colors.orange,
              action: SnackBarAction(label: "VIEW", textColor: Colors.white, onPressed: () {
                setState(() => _currentIndex = 0);
              }),
            )
          );
        }
        setState(() => _pendingOrderCount = currentCount);
      }
    });
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

    final String farmerName = _farmerData?['name'] ?? _farmerData?['fullName'] ?? 'Farmer';
    final String farmName = _farmerData?['farmName'] ?? 'AgriDirect Farm';
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> pages = [
      _DashboardTab(
        farmerName: farmerName,
        farmName: farmName,
        uid: uid,
        farmerLat: _farmerData?['farmLat'],
        farmerLng: _farmerData?['farmLng'],
      ),
      _ProductsTab(
        uid: uid,
        farmName: farmName,
        farmerLat: _farmerData?['farmLat'],
        farmerLng: _farmerData?['farmLng'],
      ),
      _DeliveryTab(uid: uid),
      _StockTab(uid: uid),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(farmName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_unreadCount + _pendingOrderCount}'),
              isLabelVisible: _unreadCount + _pendingOrderCount > 0,
              child: const Icon(Icons.dashboard_outlined),
            ),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Products'),
          const BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Deliveries'),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final String farmerName, farmName, uid;
  final double? farmerLat, farmerLng;
  const _DashboardTab({required this.farmerName, required this.farmName, required this.uid, this.farmerLat, this.farmerLng});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  int _carouselItemCount = 0;

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
      if (_pageController.hasClients && _carouselItemCount > 1) {
        int nextIndex = (_currentCarouselIndex + 1) % _carouselItemCount;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildCarouselSlide(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withValues(alpha: 0.2), size: 60),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Namaste, ${widget.farmerName}!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            const Text("Hope your harvest is plentiful today.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 25),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            final notifications = snapshot.data?.docs ?? [];
            _carouselItemCount = notifications.isEmpty ? 1 : notifications.length;

            return SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
                    itemCount: _carouselItemCount,
                    itemBuilder: (context, i) {
                      if (notifications.isEmpty) {
                        return _buildCarouselSlide("Fresh Harvest Awaits", "Keep track of your products and orders efficiently.", Icons.eco);
                      }
                      final data = notifications[i].data() as Map<String, dynamic>;
                      return _buildCarouselSlide(data['title'] ?? 'Notification', data['body'] ?? '', Icons.info_outline);
                    },
                  ),
                  Positioned(
                    bottom: 15,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        _carouselItemCount,
                        (index) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
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

        const SizedBox(height: 25),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Pending Farmer').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final availableDocs = docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList();

            if (availableDocs.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("New Order Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...availableDocs.map((doc) => _OrderAcceptanceTile(
                  orderId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  currentFarmerUid: widget.uid,
                  currentFarmName: widget.farmName,
                  farmerLat: widget.farmerLat,
                  farmerLng: widget.farmerLng,
                )),
                const SizedBox(height: 20),
              ],
            );
          },
        ),

        const Text("Business Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            double totalEarnings = 0;
            int pendingCount = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['status'] == 'Delivered') {
                totalEarnings += (data['farmerRevenue'] ?? (data['total'] ?? 0) * 0.8).toDouble();
              } else if (data['status'] != 'Cancelled') {
                pendingCount++;
              }
            }

            return Row(
              children: [
                _StatCard(title: "Total Revenue", value: "Rs. ${totalEarnings.toStringAsFixed(0)}", icon: Icons.payments, color: Colors.green),
                const SizedBox(width: 15),
                _StatCard(title: "Active Tasks", value: "$pendingCount", icon: Icons.pending_actions, color: Colors.blue),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;
  const _ProductsTab({required this.uid, required this.farmName, this.farmerLat, this.farmerLng});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProduct,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: widget.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("No products yet", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: data['image'] ?? '',
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.eco, color: Colors.green),
                    ),
                  ),
                  title: Text(data['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rs. ${data['price']} / ${data['unit']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('products').doc(docs[i].id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;

  const _ProductForm({required this.uid, required this.farmName, this.farmerLat, this.farmerLng});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final name = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController(text: 'kg');
  XFile? selectedImage;
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add New Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GestureDetector(
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
            const SizedBox(height: 20),
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()))),
                const SizedBox(width: 15),
                Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: isUploading ? null : _submit,
                child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("List Product", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (name.text.isEmpty || price.text.isEmpty || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => isUploading = true);
    try {
      final storageService = StorageService();
      final imageUrl = await storageService.uploadImage(selectedImage!, 'products');
      if (imageUrl == null) throw "Upload failed";

      await FirebaseFirestore.instance.collection('products').add({
        'name': name.text,
        'title': name.text,
        'price': double.parse(price.text),
        'farmerUid': widget.uid,
        'farmName': widget.farmName,
        'farmerLat': widget.farmerLat,
        'farmerLng': widget.farmerLng,
        'unit': unit.text,
        'image': imageUrl,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }
}

class _DeliveryTab extends StatelessWidget {
  final String uid;
  const _DeliveryTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          labelColor: Colors.green,
          indicatorColor: Colors.green,
          tabs: [Tab(text: "Active"), Tab(text: "History")],
        ),
        body: TabBarView(
          children: [
            _OrderList(uid: uid, statuses: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way']),
            _OrderList(uid: uid, statuses: ['Delivered']),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String uid;
  final List<String> statuses;
  const _OrderList({required this.uid, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('farmerUid', isEqualTo: uid)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No orders found", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text("Order #${docs[i].id.substring(0, 8)}"),
                subtitle: Text(data['itemsSummary'] ?? 'Products'),
                trailing: status == 'Farmer Accepted'
                    ? ElevatedButton(
                        onPressed: () => docs[i].reference.update({'status': 'Awaiting Pickup'}),
                        child: const Text("Pack & Ready"),
                      )
                    : Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            );
          },
        );
      },
    );
  }
}

class _StockTab extends StatelessWidget {
  final String uid;
  const _StockTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: Column(
                children: [
                  Expanded(child: CachedNetworkImage(imageUrl: d['image'] ?? '', fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.eco))),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(d['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _OrderAcceptanceTile extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final String currentFarmerUid;
  final String currentFarmName;
  final double? farmerLat, farmerLng;
  const _OrderAcceptanceTile({required this.orderId, required this.data, required this.currentFarmerUid, required this.currentFarmName, this.farmerLat, this.farmerLng});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(data['itemsSummary'] ?? 'New Order'),
        subtitle: Text("Total: Rs. ${data['total']} • ${data['deliveryAddress']}"),
        trailing: ElevatedButton(
          onPressed: () => FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'status': 'Farmer Accepted',
            'farmerUid': currentFarmerUid,
            'farmName': currentFarmName,
            'farmerLat': farmerLat,
            'farmerLng': farmerLng,
          }),
          child: const Text("Accept"),
        ),
      ),
    );
  }
}
