import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/screens/profile/notifications_screen.dart';
import 'package:farmtech_agridirect/screens/ai/crop_health_screen.dart';
import 'package:farmtech_agridirect/models/price_request_model.dart';

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
    if (mounted) {
      FirebaseAuth.instance.signOut();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final String farmerName = _farmerData?['fullName'] ?? 'Farmer';
    final String farmName = _farmerData?['farmName'] ?? 'My Farm';
    final String farmLocation = _farmerData?['farmLocation'] ?? '';
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> pages = [
      _DashboardTab(farmerName: farmerName, farmName: farmName, farmLocation: farmLocation, uid: uid),
      _ProductsTab(uid: uid, farmName: farmName),
      _DeliveryTab(uid: uid),
      const CropHealthScreen(),
      _StockTab(uid: uid),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(farmName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_outlined), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final String farmerName, farmName, farmLocation, uid;
  const _DashboardTab({required this.farmerName, required this.farmName, required this.farmLocation, required this.uid});

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
        _currentCarouselIndex = (_currentCarouselIndex + 1) % 4;
        _pageController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(widget.farmerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.agriculture, color: Colors.white, size: 30),
                  const SizedBox(height: 10),
                  Text(widget.farmName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.farmLocation, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                final notifications = snapshot.data?.docs ?? [];
                
                return Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.asset(
                          "assets/images/vegetables.png",
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(color: Colors.black.withAlpha(80)),
                        
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
                  .where('farmerUid', isEqualTo: widget.uid)
                  .where('status', isEqualTo: 'Pending Farmer')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Text("Error: ${snap.error}");
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const SizedBox();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Active Delivery Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                    const SizedBox(height: 12),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _OrderAcceptanceTile(orderId: doc.id, data: data);
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
                final orders = snapshot.data?.docs ?? [];
                final pending = orders.where((o) => (o.data() as Map)['status'] == 'Pending').length;
                return Row(
                  children: [
                    _StatCard(title: "Orders", value: "${orders.length}", icon: Icons.receipt_long, color: Colors.blue),
                    const SizedBox(width: 12),
                    _StatCard(title: "Pending", value: "$pending", icon: Icons.pending, color: Colors.orange),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSlide(String title, String body, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final String uid, farmName;
  const _ProductsTab({required this.uid, required this.farmName});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Products"), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showProductSheet(context))
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: widget.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final String? imageUrl = data['imageUrl'] ?? data['image'];
              
              return Card(
                child: ListTile(
                  leading: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.green)),
                        )
                      : const Icon(Icons.eco, color: Colors.green),
                  title: Text(data['name'] ?? 'Product'),
                  subtitle: Text("Rs. ${data['price']} / ${data['unit']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductSheet(context, existingProduct: data, productId: docs[i].id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => docs[i].reference.delete(),
                      ),
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

  void _showProductSheet(BuildContext context, {Map<String, dynamic>? existingProduct, String? productId}) {
    final name = TextEditingController(text: existingProduct?['name']);
    final price = TextEditingController(text: existingProduct?['price']?.toString());
    final unit = TextEditingController(text: existingProduct?['unit'] ?? 'kg');
    bool isEditing = existingProduct != null;
    XFile? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? "Request Price Update" : "Add New Product", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              if (!isEditing) ...[
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setModalState(() => selectedImage = image);
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.withAlpha(50)),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.green, size: 30),
                                SizedBox(height: 4),
                                Text("Add Photo", style: TextStyle(fontSize: 10, color: Colors.green)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: name, decoration: const InputDecoration(labelText: "Product Name")),
              ],
              
              if (isEditing) Text("Updating: ${name.text}", style: const TextStyle(color: Colors.grey)),
              
              Row(
                children: [
                  Expanded(child: TextField(controller: price, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number)),
                  const SizedBox(width: 20),
                  Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: "Unit (e.g. kg, bundle)"))),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isUploading ? null : () async {
                    if (price.text.isEmpty || (!isEditing && name.text.isEmpty)) return;

                    setModalState(() => isUploading = true);

                    try {
                      if (isEditing) {
                        await FirebaseFirestore.instance.collection('price_requests').add({
                          'productId': productId,
                          'productName': name.text,
                          'farmerUid': widget.uid,
                          'farmName': widget.farmName,
                          'oldPrice': double.tryParse(existingProduct['price']?.toString() ?? '0') ?? 0,
                          'newPrice': double.parse(price.text),
                          'oldUnit': existingProduct['unit'] ?? 'kg',
                          'newUnit': unit.text,
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price update request sent to admin")));
                      } else {
                        String? imageUrl;
                        if (selectedImage != null) {
                          final cloudinary = CloudinaryPublic('drt6y7f8v', 'agridirect_unsigned', cache: false);
                          CloudinaryResponse response = await cloudinary.uploadFile(
                            CloudinaryFile.fromFile(selectedImage!.path, folder: 'products'),
                          );
                          imageUrl = response.secureUrl;
                        }

                        await FirebaseFirestore.instance.collection('products').add({
                          'name': name.text,
                          'price': double.parse(price.text),
                          'farmerUid': widget.uid,
                          'farmName': widget.farmName,
                          'unit': unit.text,
                          'imageUrl': imageUrl,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                    } finally {
                      setModalState(() => isUploading = false);
                    }
                  },
                  child: isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEditing ? "Submit Request" : "Add Product", style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
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
        backgroundColor: const Color(0xFFF5F7F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("Deliveries", style: TextStyle(color: Colors.black)),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
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
                Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(data['itemsSummary'] ?? 'Products ordered', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text("Total: Rs. ${data['total'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            if (status == 'Farmer Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => docRef.update({'status': 'Awaiting Pickup'}),
                  child: const Text("Ready for Pickup", style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderAcceptanceTile extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _OrderAcceptanceTile({required this.orderId, required this.data});

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['itemsSummary'] ?? 'New Order', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Total: Rs. ${data['total'] ?? 0}", style: const TextStyle(color: Colors.green, fontSize: 13)),
                  Text("Customer: ${data['userName']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
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
                await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                  'status': 'Farmer Accepted',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                final userId = data['userId'];
                if (userId != null) {
                  await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
                    'title': 'Farmer Accepted Your Order',
                    'body': 'A farm has accepted your order and is preparing it.',
                    'createdAt': FieldValue.serverTimestamp(),
                    'isRead': false,
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
            return const Center(child: Text("No products in stock. Add some in 'Products' tab!"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'Product';
              final String stock = data['stock']?.toString() ?? '0';
              final String image = data['imageUrl'] ?? data['image'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: image.isNotEmpty
                          ? Image.network(image, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage())
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
