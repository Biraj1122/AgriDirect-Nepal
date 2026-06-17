import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'screens/crop_health_screen.dart';
import 'product.dart';

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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          _farmerData = doc.data();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading farmer data: $e");
      if (mounted) setState(() => _loading = false);
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
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated")));
    }

    final List<Widget> pages = [
      _DashboardTab(
          farmerName: farmerName,
          farmName: farmName,
          farmLocation: farmLocation,
          uid: uid),
      _ProductsTab(uid: uid, farmName: farmName),
      _DeliveryTab(uid: uid),
      const CropHealthScreen(),
      _StockTab(uid: uid),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Deliveries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety_outlined),
              activeIcon: Icon(Icons.health_and_safety),
              label: 'Crop Health'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Stock'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String farmerName;
  final String farmName;
  final String farmLocation;
  final String uid;

  const _DashboardTab({
    required this.farmerName,
    required this.farmName,
    required this.farmLocation,
    required this.uid,
  });

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
                    Text("Welcome back 👋", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(farmerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                    if (farmLocation.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 13, color: Colors.green),
                          const SizedBox(width: 2),
                          Text(farmLocation, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          icon: const Icon(Icons.notifications_none, color: Color(0xFF1A2E1A)),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('notifications')
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
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                              context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.logout, color: Colors.red, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF56B947)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.agriculture, color: Colors.white, size: 30),
                  const SizedBox(height: 8),
                  Text(farmName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (farmLocation.isNotEmpty)
                    Text(farmLocation, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
              builder: (context, productSnap) {
                final productCount = productSnap.hasData ? productSnap.data!.docs.length : 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: uid).snapshots(),
                  builder: (context, orderSnap) {
                    final orders = orderSnap.hasData ? orderSnap.data!.docs : [];
                    final pendingOrders = orders.where((o) => (o.data() as Map)['status'] == 'Pending').length;
                    final deliveredOrders = orders.where((o) => (o.data() as Map)['status'] == 'Delivered').length;

                    return Row(
                      children: [
                        _StatCard(title: "Products", value: "$productCount", icon: Icons.storefront, color: Colors.green),
                        const SizedBox(width: 12),
                        _StatCard(title: "Pending", value: "$pendingOrders", icon: Icons.pending_actions, color: Colors.orange),
                        const SizedBox(width: 12),
                        _StatCard(title: "Delivered", value: "$deliveredOrders", icon: Icons.check_circle, color: Colors.blue),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 25),

            /// DYNAMIC BANNER (ADMIN ANNOUNCEMENT)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('announcement').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox();
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Special Announcement';
                final content = data['content'] ?? 'Important updates from the admin team.';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/vegetables.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.black.withAlpha(180), Colors.transparent],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(content, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text("Recent Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('farmerUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text("Error: ${snap.error}");
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const _EmptyState(icon: Icons.receipt_long, message: "No orders yet");
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _OrderTile(orderId: doc.id, data: data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final String uid;
  final String farmName;

  const _ProductsTab({required this.uid, required this.farmName});

  void _showAddEditProduct(BuildContext context, {DocumentSnapshot? doc}) {
    final nameCtrl = TextEditingController(text: doc != null ? doc['name'] : '');
    final priceCtrl = TextEditingController(text: doc != null ? doc['price'].toString() : '');
    final descCtrl = TextEditingController(text: doc != null ? doc['description'] : '');
    final stockCtrl = TextEditingController(text: doc != null ? doc['stock'].toString() : '');
    final urlCtrl = TextEditingController(text: doc != null ? (doc['imageUrl'] ?? '') : '');

    String selectedUnit = doc != null ? (doc['unit'] ?? 'kg') : 'kg';
    final units = ['kg', 'g', 'pcs', 'dozen', 'litre', 'bunch'];
    String selectedCategory = doc != null ? (doc['category'] ?? 'Vegetables') : 'Vegetables';

    XFile? pickedXFile;
    Uint8List? webImage;
    String existingImageUrl = doc != null ? (doc['imageUrl'] ?? '') : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc == null ? "Add Product" : "Edit Product", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // --- IMAGE PREVIEW AREA ---
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: urlCtrl.text.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(urlCtrl.text.trim(), fit: BoxFit.cover, 
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.red)))
                      : pickedXFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb ? Image.memory(webImage!, fit: BoxFit.cover) : Image.file(File(pickedXFile!.path), fit: BoxFit.cover))
                          : const Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                _buildInput(urlCtrl, "Direct Image URL (e.g. .jpg, .png)", Icons.link, 
                  onChanged: (v) => setS(() {}),
                  suffix: urlCtrl.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setS(() => urlCtrl.clear())) 
                    : null
                ),
                const Text("Tip: Right-click Google Image and 'Copy image address'", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        if (kIsWeb) {
                          final bytes = await image.readAsBytes();
                          setS(() { pickedXFile = image; webImage = bytes; urlCtrl.clear(); });
                        } else {
                          setS(() { pickedXFile = image; urlCtrl.clear(); });
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text("Select Local Photo"),
                  ),
                ),
                
                const Divider(height: 30),
                _buildInput(nameCtrl, "Product Name", Icons.eco_outlined),
                const SizedBox(height: 12),
                _buildInput(descCtrl, "Description", Icons.description_outlined, maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildInput(priceCtrl, "Price (Rs.)", Icons.currency_rupee, type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInput(stockCtrl, "Stock Qty", Icons.inventory_2_outlined, type: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                // ... (rest of the dropdowns remain the same)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    List<String> categories = ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Spices', 'Pulses', 'Mushrooms', 'Tea & Coffee', 'Specialty'];
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      categories = snapshot.data!.docs.map((d) => (d.data() as Map<String, dynamic>)['name'] as String).toList();
                    }
                    
                    // Ensure selectedCategory is in the list or default to the first one
                    if (!categories.contains(selectedCategory)) {
                      selectedCategory = categories.isNotEmpty ? categories.first : 'Vegetables';
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setS(() => selectedCategory = v!),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  decoration: InputDecoration(
                    labelText: "Unit",
                    prefixIcon: const Icon(Icons.straighten),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setS(() => selectedUnit = v!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
                        return;
                      }

                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
                        );

                        String finalImageUrl = existingImageUrl;

                        if (pickedXFile != null) {
                          String fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          Reference storageRef = FirebaseStorage.instance.ref().child('product_images').child(fileName);

                          final metadata = SettableMetadata(contentType: 'image/jpeg');
                          if (kIsWeb) {
                            final bytes = webImage ?? await pickedXFile!.readAsBytes();
                            UploadTask uploadTask = storageRef.putData(bytes, metadata);
                            TaskSnapshot snapshot = await uploadTask;
                            finalImageUrl = await snapshot.ref.getDownloadURL();
                          } else {
                            UploadTask uploadTask = storageRef.putFile(File(pickedXFile!.path), metadata);
                            TaskSnapshot snapshot = await uploadTask;
                            finalImageUrl = await snapshot.ref.getDownloadURL();
                          }
                        } else if (urlCtrl.text.isNotEmpty) {
                          finalImageUrl = urlCtrl.text.trim();
                        }

                        final data = {
                          'farmerUid': uid,
                          'farmName': farmName,
                          'name': nameCtrl.text.trim(),
                          'title': nameCtrl.text.trim(), // Standardize with Admin
                          'description': descCtrl.text.trim(),
                          'category': selectedCategory,
                          'price': double.tryParse(priceCtrl.text) ?? 0.0,
                          'stock': int.tryParse(stockCtrl.text) ?? 0,
                          'unit': selectedUnit,
                          'imageUrl': finalImageUrl,
                          'image': finalImageUrl, // Standardize with Admin
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        if (doc == null) {
                          data['createdAt'] = FieldValue.serverTimestamp();
                          await FirebaseFirestore.instance.collection('products').add(data);
                        } else {
                          await FirebaseFirestore.instance.collection('products').doc(doc.id).update(data);
                        }

                        if (context.mounted) {
                          // Use a small delay to ensure Firestore has processed before closing
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
                              Navigator.pop(ctx); // Dismiss bottom sheet
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(doc == null ? "Product added successfully!" : "Product updated!")),
                          );
                        }
                      } catch (e) {
                        debugPrint("Error saving product: $e");
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop(); // Ensure dialog is dismissed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to save product: ${e.toString()}")),
                          );
                        }
                      }
                    },
                    child: Text(doc == null ? "Add Product" : "Update Product", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("My Products", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showAddEditProduct(context),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('farmerUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const _EmptyState(icon: Icons.storefront_outlined, message: "No products yet.\nTap Add to get started.");
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final product = Product.fromMap(data, docId: doc.id);
                    return _ProductCard(
                      product: product,
                      onEdit: () => _showAddEditProduct(context, doc: doc),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Product"),
                            content: Text("Delete \"${data['name']}\"? This cannot be undone."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
                          try {
                            await FirebaseStorage.instance.refFromURL(data['imageUrl'].toString()).delete();
                          } catch (_) {}
                        }
                        }
                      },
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

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, TextInputType type = TextInputType.text, ValueChanged<String>? onChanged, Widget? suffix}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}

class _DeliveryTab extends StatefulWidget {
  final String uid;
  const _DeliveryTab({required this.uid});

  @override
  State<_DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<_DeliveryTab> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text("Delivery Tracking", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (ctx, i) {
                final f = _filters[i];
                final selected = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.green : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filter == 'All'
                  ? FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).snapshots()
                  : FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: widget.uid).where('status', isEqualTo: _filter).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const _EmptyState(icon: Icons.local_shipping_outlined, message: "No orders found\nfor this status.");
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _DeliveryCard(
                      orderId: doc.id,
                      data: data,
                      onUpdateStatus: (newStatus) async {
                        await FirebaseFirestore.instance.collection('orders').doc(doc.id).update({
                          'status': newStatus,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        
                        // Notify the Customer
                        final userId = data['userId'];
                        if (userId != null) {
                          await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
                            'title': 'Order Status: $newStatus',
                            'body': 'Farmer updated your order #${doc.id.substring(0, 6)} to $newStatus.',
                            'time': DateTime.now().toString(),
                            'createdAt': FieldValue.serverTimestamp(),
                            'type': 'delivery',
                          });
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order status updated to $newStatus")));
                        }
                      },
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

class _StockTab extends StatelessWidget {
  final String uid;
  const _StockTab({required this.uid});

  void _showUpdateStock(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ctrl = TextEditingController(text: data['stock']?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Stock: ${data['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "New Stock Quantity (${data['unit'] ?? 'kg'})",
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  final newStock = int.tryParse(ctrl.text);
                  if (newStock == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid number")));
                    return;
                  }
                  await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                    'stock': newStock,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text("Update Stock", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text("Stock Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const _EmptyState(icon: Icons.inventory_2_outlined, message: "No products to track.\nAdd products first.");

                final lowStock = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['stock'] ?? 0) < 10;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (lowStock.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(child: Text("${lowStock.length} product(s) running low on stock!", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text("All Products", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
                    const SizedBox(height: 8),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final int stock = data['stock'] ?? 0;
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Current Stock: $stock ${data['unit'] ?? 'kg'}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: stock < 10 ? Colors.red : Colors.green),
                              ),
                              const SizedBox(width: 16),
                              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.green), onPressed: () => _showUpdateStock(context, doc)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit, onDelete;
  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: product.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.image.startsWith('assets/')
                          ? Image.asset(product.image, fit: BoxFit.cover)
                          : Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              key: ValueKey(product.image), // Force reload if URL changes
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                    )
                  : const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text(product.category!, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    ),
                  const SizedBox(height: 4),
                  Text("Rs. ${product.price} / ${product.unit}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final Function(String) onUpdateStatus;
  const _DeliveryCard({required this.orderId, required this.data, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final String currentStatus = data['status'] ?? 'Pending';
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ID: #${orderId.substring(0, min(6, orderId.length))}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(currentStatus, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 20),
            Text("Product: ${data['productName'] ?? 'Items'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text("Customer: ${data['customerName'] ?? 'Buyer'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Text("Address: ${data['deliveryAddress'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String>(
                  value: currentStatus,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.edit_location_alt_outlined, color: Colors.green, size: 20),
                  items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((String val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null && v != currentStatus) onUpdateStatus(v);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _OrderTile({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['productName'] ?? 'New Order', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Total: Rs. ${data['totalPrice'] ?? 0}", style: const TextStyle(color: Colors.green, fontSize: 13)),
            ],
          ),
          Text(data['status'] ?? 'Pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}