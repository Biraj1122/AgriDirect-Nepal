import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';
import 'package:farmtech_agridirect/Success/shared_widgets.dart';
import 'package:geolocator/geolocator.dart';

class FarmerScreen extends StatefulWidget {
  const FarmerScreen({super.key});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  static const Color primaryTeal = Color(0xFF1D9E75);
  
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryTeal)));

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
      _ProfileTab(uid: uid, farmerName: farmerName),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(farmName, style: const TextStyle(color: Color(0xFF1A1D25), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 20,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'My Store'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final String uid, farmerName;
  const _ProfileTab({required this.uid, required this.farmerName});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadImage(image, 'profile_pics');
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'profileImageUrl': url,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final url = data?['profileImageUrl'];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Heading(title: "Farm Profile", subtitle: "Manage your professional settings"),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                          backgroundImage: getImageProvider(url),
                          child: (url == null || url.isEmpty) ? const Icon(Icons.agriculture_rounded, size: 60, color: Color(0xFF1D9E75)) : null,
                        ),
                        if (_isUploading)
                          const Positioned.fill(child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.farmerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        );
      }
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

  Widget _buildCarouselSlide(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D9E75), Color(0xFF2E5BFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white24, size: 64),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Heading(title: "Namaste, ${widget.farmerName}!", subtitle: "Hope your harvest is plentiful today."),
        const SizedBox(height: 28),

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
            final count = notifications.isEmpty ? 1 : notifications.length;

            return SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentCarouselIndex = i % count),
                    itemCount: null, // Infinite scroll simulation
                    itemBuilder: (context, index) {
                      final i = index % count;
                      if (notifications.isEmpty) {
                        return _buildCarouselSlide("Fresh Harvest Awaits", "Keep track of your products and orders efficiently.", Icons.eco_rounded);
                      }
                      final data = notifications[i].data() as Map<String, dynamic>;
                      return _buildCarouselSlide(data['title'] ?? 'Notification', data['body'] ?? '', Icons.info_outline_rounded);
                    },
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 32),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Pending Farmer').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final availableDocs = docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList();

            if (availableDocs.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: "AVAILABLE ORDERS"),
                const SizedBox(height: 12),
                ...availableDocs.map((doc) => _OrderAcceptanceTile(
                  orderId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  currentFarmerUid: widget.uid,
                  currentFarmName: widget.farmName,
                  farmerLat: widget.farmerLat,
                  farmerLng: widget.farmerLng,
                )),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        const FieldLabel(label: "BUSINESS OVERVIEW"),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            double totalNetEarnings = 0;
            int pendingCount = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['status'] == 'Delivered') {
                totalNetEarnings += (data['farmerRevenue'] ?? 0).toDouble();
              } else if (data['status'] != 'Cancelled') {
                pendingCount++;
              }
            }

            return Row(
              children: [
                _StatCard(title: "Revenue", value: "Rs. ${totalNetEarnings.toStringAsFixed(0)}", icon: Icons.payments_rounded, color: const Color(0xFF1D9E75)),
                const SizedBox(width: 16),
                _StatCard(title: "Active", value: "$pendingCount", icon: Icons.pending_actions_rounded, color: const Color(0xFF2E5BFF)),
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
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Heading(title: "My Products", subtitle: "Manage your farm products for sale"),
          ),
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
                        Icon(Icons.storefront_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No products yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
      
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SafeProductImage(
                            imageUrl: data['image'] ?? data['imageUrl'] ?? '',
                            width: 60, height: 60, fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(data['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text("Rs. ${data['price']} / ${data['unit']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => FirebaseFirestore.instance.collection('products').doc(docs[i].id).delete(),
                        ),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Heading(title: "Add New Product", subtitle: "List your fresh produce on the market"),
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
            const SizedBox(height: 32),
            GradientButton(
              label: "List Product", 
              icon: Icons.check_rounded, 
              isLoading: isUploading, 
              teal: primaryTeal, blue: const Color(0xFF2E5BFF), 
              onTap: _submit
            ),
            const SizedBox(height: 40),
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
        'imageUrl': imageUrl,
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
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Heading(title: "Orders", subtitle: "Track your outgoing deliveries"),
          ),
          TabBar(
            labelColor: const Color(0xFF1D9E75),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1D9E75),
            indicatorWeight: 3,
            tabs: const [Tab(text: "Active"), Tab(text: "History")],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderList(uid: uid, statuses: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived', 'Confirm Received']),
                _OrderList(uid: uid, statuses: ['Delivered', 'Cancelled']),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text("Order #${docs[i].id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(data['itemsSummary'] ?? 'Produce Pack'),
                trailing: status == 'Farmer Accepted'
                    ? ElevatedButton(
                        onPressed: () => docs[i].reference.update({'status': 'Awaiting Pickup'}),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Pack & Ready", style: TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    : Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
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
        if (docs.isEmpty) return const Center(child: Text("No stock found"));

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: SafeProductImage(imageUrl: d['image'] ?? d['imageUrl'] ?? ''))),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(d['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Qty: ${d['stock'] ?? 100}", style: const TextStyle(color: Color(0xFF1D9E75))),
                      ],
                    ),
                  )
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['itemsSummary'] ?? 'New Order', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text("Subtotal: Rs. ${data['subtotal']} • ${data['deliveryAddress']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          GradientButton(
            label: "Accept Order", 
            icon: Icons.check_circle_rounded, 
            isLoading: false, 
            teal: const Color(0xFF1D9E75), blue: const Color(0xFF2E5BFF), 
            onTap: () async {
              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                'status': 'Farmer Accepted',
                'farmerUid': currentFarmerUid,
                'farmName': currentFarmName,
                'farmerLat': farmerLat,
                'farmerLng': farmerLng,
              });
            },
          ),
        ],
      ),
    );
  }
}

class _TrackRiderMapScreen extends StatelessWidget {
  final String orderId, riderId;
  final Map<String, dynamic> orderData;
  const _TrackRiderMapScreen({required this.orderId, required this.riderId, required this.orderData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Rider")),
      body: const Center(child: Text("Map integration here")),
    );
  }
}
