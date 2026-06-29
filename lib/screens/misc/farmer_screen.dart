import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/screens/profile/notifications_screen.dart';
import 'package:farmtech_agridirect/services/cloudinary_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

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

    final String farmerName = _farmerData?['name'] ?? 'Farmer';
    final String farmName = _farmerData?['farmName'] ?? 'AgriDirect Farm';
    final String farmLocation = _farmerData?['farmLocation'] ?? '';
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> pages = [
      _DashboardTab(
        farmerName: farmerName,
        farmName: farmName,
        farmLocation: farmLocation,
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
      _ProfileTab(user: FirebaseAuth.instance.currentUser!),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _currentIndex == 0 
          ? Image.asset('assets/images/logo.png', height: 40)
          : Text(farmName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final String farmerName, farmName, farmLocation, uid;
  final double? farmerLat, farmerLng;
  const _DashboardTab({
    required this.farmerName,
    required this.farmName,
    required this.farmLocation,
    required this.uid,
    this.farmerLat,
    this.farmerLng,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
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
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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
          Icon(icon, color: Colors.white.withAlpha(50), size: 60),
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
          stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).collection('notifications').orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (context, snapshot) {
            final notifications = snapshot.data?.docs ?? [];
            return SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
                    itemCount: notifications.isEmpty ? 1 : notifications.length,
                    itemBuilder: (context, i) {
                      if (notifications.isEmpty) {
                        return _buildCarouselSlide(
                          "Fresh Harvest Awaits",
                          "Keep track of your products and orders efficiently.",
                          Icons.eco,
                        );
                      }
                      final data = notifications[i].data() as Map<String, dynamic>;
                      return _buildCarouselSlide(
                        data['title'] ?? 'Notification',
                        data['body'] ?? '',
                        Icons.info_outline,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 15,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        notifications.isEmpty ? 1 : notifications.length,
                            (index) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == index ? Colors.white : Colors.white.withAlpha(100),
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

        const SizedBox(height: 20),

        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('announcement').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String title = data['title'] ?? '';
            final String content = data['content'] ?? '';

            if (title.isEmpty && content.isEmpty) return const SizedBox();

            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withAlpha(50))),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.orange),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(content, style: const TextStyle(fontSize: 12)),
                  ]))
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'Pending Farmer')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text("Error: ${snap.error}");
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

            final docs = snap.data!.docs;
            // Only show orders that haven't been picked by another farmer
            final availableDocs = docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList();

            if (availableDocs.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Available Orders (Unassigned)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 12),
                ...availableDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _OrderAcceptanceTile(
                    orderId: doc.id,
                    data: data,
                    currentFarmerUid: widget.uid,
                    currentFarmName: widget.farmName,
                    farmerLat: widget.farmerLat,
                    farmerLng: widget.farmerLng,
                  );
                }),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text("Recent Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            double totalEarnings = 0;
            int pendingCount = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              // Only count revenue from Delivered orders and use the new 80% share field
              if (data['status'] == 'Delivered') {
                totalEarnings += (data['farmerRevenue'] ?? 0).toDouble();
              } else if (data['status'] != 'Cancelled') {
                pendingCount++;
              }
            }

            return Row(
              children: [
                _StatCard(title: "Farmer Net", value: "Rs. ${totalEarnings.toStringAsFixed(0)}", icon: Icons.payments, color: Colors.green),
                const SizedBox(width: 15),
                _StatCard(title: "Live Tasks", value: "$pendingCount", icon: Icons.pending_actions, color: Colors.blue),
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

  void _editProduct(Map<String, dynamic> product, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductForm(uid: widget.uid, farmName: widget.farmName, existingProduct: product, productId: id),
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

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withAlpha(50)),
                  const SizedBox(height: 16),
                  const Text("No products yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: data['image'] ?? '',
                      width: 60, height: 60, fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.eco, color: Colors.green),
                    ),
                  ),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rs. ${data['price']} / ${data['unit'] ?? 'kg'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _editProduct(data, docs[i].id)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteProduct(docs[i].id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
    }
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
  final description = TextEditingController();
  final ImagePicker _picker = ImagePicker();
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
            if (!isEditing) TextField(controller: description, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 15),
            TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Stock Quantity", border: OutlineInputBorder())),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                        final cloudinaryService = CloudinaryService();
                        imageUrl = await cloudinaryService.uploadImage(selectedImage!, 'products');
                        if (imageUrl == null) throw "Upload failed";
                      } catch (e) {
                        String errorMsg = "Error uploading image: $e";
                        throw errorMsg;
                      }

                      await FirebaseFirestore.instance.collection('products').add({
                        'name': name.text,
                        'title': name.text,
                        'price': priceVal,
                        'farmerUid': widget.uid,
                        'farmName': widget.farmName,
                        'farmerLat': widget.farmerLat,
                        'farmerLng': widget.farmerLng,
                        'unit': unit.text,
                        'stock': int.tryParse(stock.text) ?? 100,
                        'image': imageUrl,
                        'imageUrl': imageUrl,
                        'description': description.text,
                        'longDescription': description.text,
                        'category': 'General',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
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

class _DeliveryTab extends StatelessWidget {
  final String uid;
  const _DeliveryTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: "Pending"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
        body: TabBarView(
          children: [
            _OrderList(uid: uid, statuses: ['Pending Farmer', 'Farmer Accepted', 'Awaiting Pickup', 'Processing']),
            _OrderList(uid: uid, statuses: ['Delivered']),
            _OrderList(uid: uid, statuses: ['Cancelled']),
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
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_outlined, size: 80, color: Colors.green.withAlpha(50)),
                const SizedBox(height: 16),
                const Text("No deliveries to show yet!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text("Your crops are growing and orders will come soon.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
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

class _DeliveryCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final DocumentReference docRef;
  const _DeliveryCard({required this.orderId, required this.data, required this.docRef});

  @override
  Widget build(BuildContext context) {
    String status = data['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'Delivered') statusColor = Colors.green;
    if (status == 'Cancelled') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(data['itemsSummary'] ?? 'Products ordered', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text("Total: Rs. ${data['total'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            if (status == 'Farmer Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

                    // Notify all Delivery Persons that a new pickup is available
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
                  child: const Text("Ready for Pickup", style: TextStyle(color: Colors.white)),
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
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("Track Rider"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ]
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
  const _OrderAcceptanceTile({
    required this.orderId,
    required this.data,
    required this.currentFarmerUid,
    required this.currentFarmName,
    this.farmerLat,
    this.farmerLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['itemsSummary'] ?? 'New Order', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Total: Rs. ${data['total'] is num ? (data['total'] as num).toStringAsFixed(2) : data['total'] ?? 0}", style: const TextStyle(color: Colors.green, fontSize: 13)),
                    Text("Customer: ${data['userName']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("Address: ${data['deliveryAddress']}", style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text("NEW REQUEST", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                // Check if already taken
                final freshDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
                if (freshDoc.data()?['farmerUid'] != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Too late! Another farm already accepted this order.")));
                  }
                  return;
                }

                await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                  'status': 'Farmer Accepted',
                  'farmerUid': currentFarmerUid,
                  'farmName': currentFarmName,
                  'farmerLat': farmerLat,
                  'farmerLng': farmerLng,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                final userId = data['userId'];
                if (userId != null) {
                  await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
                    'title': 'Farmer Accepted Your Order',
                    'body': '$currentFarmName has accepted your order and is preparing it.',
                    'createdAt': FieldValue.serverTimestamp(),
                    'isRead': false,
                    'type': 'delivery_status',
                  });
                }
              },
              child: const Text("Accept & Prepare", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}

class _StockTab extends StatelessWidget {
  final String uid;
  const _StockTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Stock Inventory", style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final String name = d['name'] ?? 'Product';
              final String image = d['image'] ?? '';
              final int stock = d['stock'] ?? 0;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: image.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => _fallbackImage(),
                      )
                          : _fallbackImage(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Qty: $stock", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.green.withAlpha(20),
      child: const Center(child: Icon(Icons.eco, size: 40, color: Colors.green)),
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

class _ProfileTab extends StatefulWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSaving = false;

  String? _profileImgPath;

  @override
  void initState() {
    super.initState();
    _loadProfileMetadata();
  }

  Future<void> _loadProfileMetadata() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _farmNameController.text = data['farmName'] ?? '';
          _farmLocationController.text = data['farmLocation'] ?? '';
          _profileImgPath = data['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImgPath = pickedFile.path;
      });
    }
  }

  Future<void> _persistProfile() async {
    setState(() => _isSaving = true);
    String? finalProfileUrl = _profileImgPath;

    try {
      if (_profileImgPath != null && !(_profileImgPath!.startsWith('http'))) {
        final cloudinaryService = CloudinaryService();
        finalProfileUrl = await cloudinaryService.uploadImage(XFile(_profileImgPath!), 'profile_pics');
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'farmName': _farmNameController.text.trim(),
        'farmLocation': _farmLocationController.text.trim(),
        'profileImageUrl': finalProfileUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.withAlpha(30),
              backgroundImage: _profileImgPath != null
                  ? (_profileImgPath!.startsWith('http')
                      ? CachedNetworkImageProvider(_profileImgPath!)
                      : FileImage(File(_profileImgPath!)) as ImageProvider)
                  : null,
              child: _profileImgPath == null ? const Icon(Icons.camera_alt, size: 30, color: Colors.green) : null,
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _farmNameController, decoration: const InputDecoration(labelText: 'Farm Name', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _farmLocationController, decoration: const InputDecoration(labelText: 'Farm Location', border: OutlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isSaving ? null : _persistProfile,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}