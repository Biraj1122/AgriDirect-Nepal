import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../login_screen.dart';
import '../utils/db_seeder.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;
  final String? adminEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 20),
        ],
      ),
      drawer: isWide ? null : _buildSidePanel(),
      body: Row(
        children: [
          if (isWide) _buildPersistentPanel(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(),
                _buildOrdersList(),
                _buildProductsList(),
                _buildUsersList(),
                _buildAnnouncementManager(),
                _buildCategoriesManager(),
                _buildResearchManager(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: "Research"),
        ],
      ),
    );
  }

  Widget _buildPersistentPanel() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Admin Panel", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Super Admin", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          _panelItem(0, Icons.dashboard, "Dashboard"),
          _panelItem(1, Icons.shopping_bag, "Orders Management"),
          _panelItem(2, Icons.inventory_2, "Products & Inventory"),
          _panelItem(3, Icons.people, "User Database"),
          _panelItem(4, Icons.campaign, "Announcements"),
          _panelItem(5, Icons.category, "Categories"),
          _panelItem(6, Icons.health_and_safety, "Research Data"),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("QUICK ACTIONS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_business, color: Colors.green),
            title: const Text("New Product"),
            onTap: () => _showAddProductDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.orange),
            title: const Text("Push Notification"),
            onTap: () => _showPushNotificationDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: const Text("Seed Database"),
            onTap: () => _handleSeedDatabase(context),
          ),
          const Spacer(),
          const Text("AgriDirect v1.0", style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _panelItem(int index, IconData icon, String label) {
    bool selected = _currentIndex == index;
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.green.withValues(alpha: 0.1),
      leading: Icon(icon, color: selected ? Colors.green : Colors.grey),
      title: Text(label, style: TextStyle(color: selected ? Colors.green : Colors.black, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => _currentIndex = index),
    );
  }

  Widget _buildSidePanel() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("Admin Control Panel", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(adminEmail ?? "Not Logged In"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.green),
            ),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          _panelItem(0, Icons.dashboard, "Main Dashboard"),
          _panelItem(1, Icons.shopping_bag, "Order Management"),
          _panelItem(2, Icons.inventory_2, "Inventory / Products"),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.green),
            title: const Text("Manage Categories"),
            onTap: () {
              setState(() => _currentIndex = 5);
              Navigator.pop(context);
            },
          ),
          _panelItem(3, Icons.people, "User Registry"),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.green),
            title: const Text("Manage Announcements"),
            onTap: () {
              setState(() => _currentIndex = 4);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.orange),
            title: const Text("Send Notification"),
            onTap: () {
              Navigator.pop(context);
              _showPushNotificationDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: const Text("Seed Database"),
            onTap: () {
              Navigator.pop(context);
              _handleSeedDatabase(context);
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout Admin", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      // Removed orderBy temporarily to ensure it works without waiting for an index
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text("Database Error: ${snapshot.error}", 
                       textAlign: TextAlign.center,
                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final docs = snapshot.data?.docs ?? [];
        int totalOrders = docs.length;
        double totalRevenue = 0;
        int pendingDeliveries = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          var rawPrice = data['totalPrice'] ?? data['total'] ?? 0;
          double price = 0;
          if (rawPrice is num) {
            price = rawPrice.toDouble();
          } else if (rawPrice is String) {
            price = double.tryParse(rawPrice) ?? 0;
          }
          totalRevenue += price;

          String status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'pending' || status == 'processing') {
            pendingDeliveries++;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, prodSnap) {
            int totalProducts = prodSnap.data?.docs.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: _statCard("Total Orders", totalOrders.toString(), Icons.shopping_cart, Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _statCard("Revenue", "Rs. ${totalRevenue.toStringAsFixed(0)}", Icons.monetization_on, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _currentIndex = 2),
                          child: _statCard("Total Products", totalProducts.toString(), Icons.inventory_2, Colors.purple),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _statCard("Pending / Active", pendingDeliveries.toString(), Icons.delivery_dining, Colors.orange)),
                    ],
                  ),
                const SizedBox(height: 30),
                  const Text("AI Research & Crop Health", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('research_submissions').snapshots(),
                    builder: (context, resSnap) {
                      final count = resSnap.data?.docs.length ?? 0;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.psychology, color: Colors.white)),
                          title: const Text("Recent Research Submissions"),
                          subtitle: Text("$count leaf scans collected for AI training"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => setState(() => _currentIndex = 6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text("Quick Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                      title: Text(totalOrders > 0 ? "You have $totalOrders total orders." : "No orders yet."),
                      subtitle: Text("Current Revenue: Rs. ${totalRevenue.toStringAsFixed(2)}"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      // Simple stream without orderBy to avoid index issues
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No orders found."),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('orders').add({
                      'userId': 'test_user',
                      'userName': 'Test Customer',
                      'total': 1250.0,
                      'status': 'Pending',
                      'createdAt': FieldValue.serverTimestamp(),
                      'items': [
                        {'name': 'Test Product', 'price': 1250, 'unit': '1kg'}
                      ]
                    });
                  },
                  child: const Text("Create Test Order"),
                )
              ],
            ),
          );
        }
        
        // Sort in memory instead of Firestore to avoid index requirement
        final sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final order = sortedDocs[index].data() as Map<String, dynamic>;
            final status = order['status'] ?? 'Pending';
            
            // Handle both 'totalPrice' and 'total'
            var rawPrice = order['totalPrice'] ?? order['total'] ?? 0;
            double price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text("Order #${sortedDocs[index].id.substring(0, 8)}"),
                subtitle: Text("Status: $status • Total: Rs. $price"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showOrderDetails(context, sortedDocs[index].id, order),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetails(BuildContext context, String id, Map<String, dynamic> data) {
    final List items = data['items'] ?? [];
    final String userName = data['userName'] ?? data['customerName'] ?? 'Unknown User';
    final String status = data['status'] ?? 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Order Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text("Ordered by: $userName", style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("Current Status: $status", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Products:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty 
                  ? const Center(child: Text("No items listed in this order."))
                  : ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i] as Map<String, dynamic>;
                      final String imgUrl = item['image'] ?? item['imageUrl'] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: imgUrl.startsWith('http') 
                            ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                            : Image.asset(imgUrl.isEmpty ? 'assets/images/logo.png' : imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                        ),
                        title: Text(item['title'] ?? item['name'] ?? 'Product'),
                        subtitle: Text("${item['unit'] ?? 'pcs'} • Rs. ${item['price']}"),
                      );
                    },
                  ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusAction(context, id, "Pending", Colors.orange),
                  _statusAction(context, id, "Processing", Colors.blue),
                  _statusAction(context, id, "Delivered", Colors.green),
                  _statusAction(context, id, "Cancelled", Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered': return Colors.green;
      case 'Processing': case 'On the way': return Colors.blue;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _statusAction(BuildContext context, String id, String status, Color color) {
    return InkWell(
      onTap: () async {
        await FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status});
        
        if (!context.mounted) return;

        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(id).get();
        if (orderDoc.exists) {
          final data = orderDoc.data()!;
          final userId = data['userId'];
          
          if (userId != null) {
            await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
              'title': 'Order Update: $status',
              'body': 'Your order #${id.substring(0, 8)} is now $status.',
              'time': DateTime.now().toString(),
              'createdAt': FieldValue.serverTimestamp(),
              'type': 'delivery',
            });
          }
        }
        
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductsList() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index].data() as Map<String, dynamic>;
              final String imgUrl = product['image'] ?? product['imageUrl'] ?? '';
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: imgUrl.startsWith('http')
                        ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : Image.asset(imgUrl.isEmpty ? 'assets/images/logo.png' : imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                  ),
                  title: Text(product['title'] ?? product['name'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${product['unit'] ?? 'kg'} • Rs. ${product['price']}"),
                      if (product['category'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product['category'],
                            style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (product['season'] != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(product['season'], style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('products').doc(docs[index].id).delete(),
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

  void _showAddProductDialog(BuildContext context) {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Vegetables';
    String selectedSeason = 'All Year';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Product"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- IMAGE PREVIEW ---
                  Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: urlController.text.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              urlController.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.broken_image, color: Colors.red), Text("Invalid URL", style: TextStyle(fontSize: 10))],
                              ),
                            ),
                          )
                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: "Image URL (Direct link)",
                      hintText: "https://example.com/image.jpg",
                      suffixIcon: urlController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setDialogState(() => urlController.clear())) 
                        : null,
                    ),
                    onChanged: (val) => setDialogState(() {}), // Refresh preview
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text("Tip: Right-click image and 'Copy image address'", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Product Name")),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (Rs.)"), keyboardType: TextInputType.number),
                  TextField(controller: unitController, decoration: const InputDecoration(labelText: "Unit (e.g. 1kg)")),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                    builder: (context, snapshot) {
                      List<String> categories = ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Spices'];
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        categories = snapshot.data!.docs.map((d) => (d.data() as Map<String, dynamic>)['name'] as String).toList();
                      }
                      
                      if (!categories.contains(selectedCategory)) {
                        selectedCategory = categories.isNotEmpty ? categories.first : 'Vegetables';
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: "Select Category", border: OutlineInputBorder()),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v!),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedSeason,
                    decoration: const InputDecoration(labelText: "Growth Season", border: OutlineInputBorder()),
                    items: ["Spring", "Summer", "Monsoon", "Autumn", "Winter", "All Year"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedSeason = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    FirebaseFirestore.instance.collection('products').add({
                      'title': titleController.text.trim(),
                      'name': titleController.text.trim(), // Standardize with Farmer
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'unit': unitController.text.trim(),
                      'description': descController.text.trim(),
                      'longDescription': descController.text.trim(),
                      'category': selectedCategory,
                      'season': selectedSeason,
                      'stock': 999, // Admin products usually high stock
                      'image': urlController.text.trim().isEmpty ? "assets/images/logo.png" : urlController.text.trim(),
                      'imageUrl': urlController.text.trim().isEmpty ? "assets/images/logo.png" : urlController.text.trim(), // Standardize with Farmer
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'farmerUid': 'admin',
                      'farmName': 'AgriDirect Central',
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add Product", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showPushNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Global Push Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This message will be sent to ALL users in the app.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Notification Title")),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: "Message Body"), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final users = await FirebaseFirestore.instance.collection('users').get();
                for (var user in users.docs) {
                  await user.reference.collection('notifications').add({
                    'title': titleController.text,
                    'body': bodyController.text,
                    'time': DateTime.now().toString(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'type': 'promo',
                  });
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification sent to all users!")));
                }
              }
            },
            child: const Text("Send Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final user = docs[index].data() as Map<String, dynamic>;
            final role = user['role'] ?? 'Customer';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'Farmer' ? Colors.green : Colors.blue,
                  child: Icon(role == 'Farmer' ? Icons.agriculture : Icons.person, color: Colors.white)
                ),
                title: Text(user['fullName'] ?? 'No Name'),
                subtitle: Text("${user['email'] ?? 'No Email'} • $role"),
                onTap: () => _showUserDetails(context, user),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    final double? lat = user['lat'];
    final double? lng = user['lng'];
    final String address = user['address'] ?? 'No address saved';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("User Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 15),
              _detailRow(Icons.person, "Full Name", user['fullName'] ?? 'N/A'),
              _detailRow(Icons.email, "Email", user['email'] ?? 'N/A'),
              _detailRow(Icons.phone, "Phone", user['phone'] ?? 'N/A'),
              _detailRow(Icons.location_on, "Address", address),
              _detailRow(Icons.badge, "Role", user['role'] ?? 'Customer'),
              const SizedBox(height: 20),
              const Text("Location on Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (lat != null && lng != null)
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: MapLibreMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(lat, lng),
                        zoom: 14,
                      ),
                      styleString: "https://tiles.openfreemap.org/styles/liberty",
                      onMapCreated: (controller) {
                        controller.addSymbol(SymbolOptions(
                          geometry: LatLng(lat, lng),
                          iconImage: "marker-15",
                          iconColor: "#FF0000",
                          iconSize: 2.0,
                        ));
                      },
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(child: Text("No location coordinates saved")),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesManager() {
    final nameController = TextEditingController();
    
    // Mapping some common icons to their names/codes for the admin to pick
    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'Eco', 'icon': Icons.eco_outlined},
      {'name': 'Fruit', 'icon': Icons.apple_outlined},
      {'name': 'Dairy', 'icon': Icons.local_drink_outlined},
      {'name': 'Herbs', 'icon': Icons.grass},
      {'name': 'Organic', 'icon': Icons.energy_savings_leaf},
      {'name': 'Meat', 'icon': Icons.kebab_dining},
      {'name': 'Grain', 'icon': Icons.grain},
      {'name': 'Fast Food', 'icon': Icons.fastfood},
    ];
    
    IconData selectedIcon = Icons.category;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text("Add New Category"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Category Name"),
                    ),
                    const SizedBox(height: 20),
                    const Text("Select Icon:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: availableIcons.map((item) {
                        bool isSelected = selectedIcon == item['icon'];
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = item['icon']),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item['icon'], color: isSelected ? Colors.green : Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('categories').add({
                          'name': nameController.text.trim(),
                          'iconCode': selectedIcon.codePoint,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                        nameController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Add", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No categories found. Click + to add one."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cat = docs[index].data() as Map<String, dynamic>;
              final iconCode = cat['iconCode'] as int?;
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: Icon(
                      iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.category,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(cat['name'] ?? 'No Name'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('categories').doc(docs[index].id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _handleSeedDatabase(BuildContext context) async {
    final List<String> allCategories = [
      "Vegetables", "Fruits", "Dairy", "Grains", "Tea & Coffee", "Spices", "Pulses", "Mushrooms", "Specialty"
    ];
    final List<String> allSeasons = [
      "Spring", "Summer", "Monsoon", "Autumn", "Winter", "All Year"
    ];

    List<String> selectedCategories = List.from(allCategories);
    List<String> selectedSeasons = List.from(allSeasons);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Seed Database"),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text("Select categories to populate:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 5),
                  ...allCategories.map((cat) {
                    return CheckboxListTile(
                      title: Text(cat, style: const TextStyle(fontSize: 14)),
                      value: selectedCategories.contains(cat),
                      activeColor: Colors.green,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedCategories.add(cat);
                          } else {
                            selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }),
                  const Divider(),
                  const Text("Seasons", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Text("Filter by growth season:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 5),
                  ...allSeasons.map((season) {
                    return CheckboxListTile(
                      title: Text(season, style: const TextStyle(fontSize: 14)),
                      value: selectedSeasons.contains(season),
                      activeColor: Colors.blue,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedSeasons.add(season);
                          } else {
                            selectedSeasons.remove(season);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: (selectedCategories.isEmpty || selectedSeasons.isEmpty) ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Seed Selected", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      // Check Auth before starting
      if (FirebaseAuth.instance.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: You must be logged in to seed the database."), backgroundColor: Colors.red)
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 15),
                  Text("Seeding Database...", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("This may take a moment on web.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
      
      try {
        final results = await seedProducts(
          selectedCategories: selectedCategories,
          selectedSeasons: selectedSeasons,
        );
        
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          int totalSuccess = results['productSuccess']! + results['categorySuccess']!;
          int totalError = results['productError']! + results['categoryError']!;

          if (totalError == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Success! Seeded ${results['productSuccess']} products and ${results['categorySuccess']} categories."),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              )
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Finished with errors. Success: $totalSuccess, Failed: $totalError. Check console for details."),
                backgroundColor: Colors.orange,
                action: SnackBarAction(label: "Retry", textColor: Colors.white, onPressed: () => _handleSeedDatabase(context)),
              )
            );
          }
        }
      } catch (e) {
        debugPrint("Seeding Error: $e");
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Critical Error: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10),
            )
          );
        }
      }
    }
  }

  Widget _buildResearchManager() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Crop Health Research Data", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Manage and review leaf scans submitted by users for AI model fine-tuning.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('research_submissions').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No research data submitted yet."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null ? timestamp.toDate().toString().split('.')[0] : 'N/A';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['predictedLabel'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Confidence: ${((data['confidence'] ?? 0) * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.green, fontSize: 13)),
                                  Text("Submitted: $dateStr", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => FirebaseFirestore.instance.collection('research_submissions').doc(docs[i].id).delete(),
                            ),
                          ],
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

  Widget _buildAnnouncementManager() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('announcement').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          titleController.text = data['title'] ?? '';
          contentController.text = data['content'] ?? '';
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Global Announcement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("This will be visible to both Farmers and Customers.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Banner Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Banner Content", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('settings').doc('announcement').set({
                    'title': titleController.text,
                    'content': contentController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement Updated!")));
                },
                child: const Text("Update Announcement", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
