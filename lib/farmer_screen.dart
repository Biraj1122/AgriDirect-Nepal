import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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

class _DashboardTab extends StatelessWidget {
  final String farmerName, farmName, farmLocation, uid;
  const _DashboardTab({required this.farmerName, required this.farmName, required this.farmLocation, required this.uid});

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
                    Text(farmerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                  Text(farmName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(farmLocation, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 25),
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
          const Text("Active Delivery Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('farmerUid', isEqualTo: uid)
                  .where('status', isEqualTo: 'Pending Farmer')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Text("Error: ${snap.error}");
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const SizedBox();
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _OrderAcceptanceTile(orderId: doc.id, data: data);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text("Recent Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: uid).snapshots(),
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
}

class _ProductsTab extends StatelessWidget {
  final String uid, farmName;
  const _ProductsTab({required this.uid, required this.farmName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Products"), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showProductSheet(context))
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.eco, color: Colors.green),
                  title: Text(data['name'] ?? 'Product'),
                  subtitle: Text("Rs. ${data['price']} / ${data['unit']}"),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => docs[i].reference.delete()),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductSheet(BuildContext context) {
    final name = TextEditingController();
    final price = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: price, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('products').add({
                  'name': name.text,
                  'price': double.parse(price.text),
                  'farmerUid': uid,
                  'farmName': farmName,
                  'unit': 'kg',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: const Text("Add Product"),
            ),
            const SizedBox(height: 20),
          ],
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
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('farmerUid', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(
                      title: Text("Order #${docs[i].id.substring(0, 5)}"),
                      subtitle: Text("Status: ${data['status']}"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _updateStatus(docs[i].reference, data, 'Processing'),
                          child: const Text("Process"),
                        ),
                        TextButton(
                          onPressed: () => _updateStatus(docs[i].reference, data, 'Delivered'),
                          child: const Text("Complete"),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(DocumentReference orderRef, Map<String, dynamic> orderData, String status) async {
    await orderRef.update({'status': status});
    
    // Push notification to the customer
    final String userId = orderData['userId'] ?? '';
    if (userId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Order Update',
        'body': 'Your order #${orderRef.id.substring(0, 5)} is now $status.',
        'type': 'order',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
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
      appBar: AppBar(title: const Text("Stock Management")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('farmerUid', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Product'),
                subtitle: Text("Current Stock: ${data['stock'] ?? 0}"),
              );
            },
          );
        },
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
