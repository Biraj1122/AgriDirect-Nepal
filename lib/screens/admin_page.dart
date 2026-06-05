import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../login_screen.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;

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
        actions: isWide ? [
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 20),
        ] : null,
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
            color: Colors.green.withOpacity(0.1),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("QUICK ACTIONS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_business),
            title: const Text("New Product"),
            onTap: () => _showAddProductDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text("Push Notification"),
            onTap: () {},
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
      selectedTileColor: Colors.green.withOpacity(0.1),
      leading: Icon(icon, color: selected ? Colors.green : Colors.grey),
      title: Text(label, style: TextStyle(color: selected ? Colors.green : Colors.black, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => _currentIndex = index),
    );
  }

  Widget _buildSidePanel() {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Admin Control Panel", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("farmadmin@gmail.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.green),
            ),
            decoration: BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.green),
            title: const Text("Main Dashboard"),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.green),
            title: const Text("Order Management"),
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.green),
            title: const Text("Inventory / Products"),
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.green),
            title: const Text("User Registry"),
            onTap: () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 15, top: 10, bottom: 10),
            child: Text("STORE SETTINGS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Update Banners"),
            onTap: () {
              // Placeholder for banner management
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Product Categories"),
            onTap: () {
              // Placeholder for category management
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text("Push Notifications"),
            onTap: () {
              // Placeholder for sending notifications
              Navigator.pop(context);
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
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        int totalOrders = snapshot.data?.docs.length ?? 0;
        double totalRevenue = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalRevenue += (doc.data() as Map<String, dynamic>)['total'] ?? 0;
          }
        }

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
                      child: _statCard("Total Products", "4", Icons.inventory_2, Colors.purple),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: _statCard("Pending Deliveries", "5", Icons.delivery_dining, Colors.orange)),
                ],
              ),
              const SizedBox(height: 30),
              const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Could add a chart or list of recent orders here
              const Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                  title: Text("New order from Kathmandu"),
                  subtitle: Text("2 minutes ago"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = docs[index].data() as Map<String, dynamic>;
            final status = order['status'] ?? 'Pending';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text("Order #${docs[index].id.substring(0, 8)}"),
                subtitle: Text("Status: $status • Total: Rs. ${order['total']}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showOrderDetails(context, docs[index].id, order),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetails(BuildContext context, String id, Map<String, dynamic> data) {
    final List items = data['items'] ?? [];
    final String userName = data['userName'] ?? 'Unknown User';
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
              Text("Current Status: $status", style: TextStyle(color: _getStatusColor(status))),
              const SizedBox(height: 20),
              const Text("Products:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i] as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(item['image'] ?? 'assets/images/logo.png'),
                      ),
                      title: Text(item['title'] ?? 'Product'),
                      subtitle: Text("${item['unit']} • Rs. ${item['price']}"),
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
                  _statusAction(context, id, "On the way", Colors.blue),
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
      case 'On the way': return Colors.blue;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _statusAction(BuildContext context, String id, String status, Color color) {
    return InkWell(
      onTap: () {
        FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status});
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statusButton(BuildContext context, String id, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: () {
            FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status});
            Navigator.pop(context);
          },
          child: Text("Set as $status", style: const TextStyle(color: Colors.white)),
        ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No products in database."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _seedInitialProducts,
                    child: const Text("Seed Initial Products"),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: product['image'].startsWith('assets/')
                        ? Image.asset(product['image'])
                        : const Icon(Icons.image),
                  ),
                  title: Text(product['title'] ?? 'No Title'),
                  subtitle: Text("${product['unit']} • Rs. ${product['price']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('products').doc(docs[index].id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _seedInitialProducts() async {
    final products = [
      {
        'image': "assets/images/tomatoes.png",
        'title': "Fresh Tomatoes",
        'price': "120",
        'unit': "1kg",
        'description': "Fresh organic tomatoes directly from local farms.",
      },
      {
        'image': "assets/images/potato png.png",
        'title': "Organic Potatoes",
        'price': "80",
        'unit': "1kg",
        'description': "Naturally grown potatoes rich in nutrients.",
      },
      {
        'image': "assets/images/green cabbage.png",
        'title': "Green Cabbage",
        'price': "60",
        'unit': "1kg",
        'description': "Healthy green cabbage freshly harvested.",
      },
      {
        'image': "assets/images/milk png.png",
        'title': "Farm Fresh Milk",
        'price': "110",
        'unit': "1L",
        'description': "Pure farm fresh milk from healthy cows.",// image path fixed
      },
    ];

    for (var p in products) {
      await FirebaseFirestore.instance.collection('products').add(p);
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Product Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (Rs.)"), keyboardType: TextInputType.number),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: "Unit (e.g. 1kg)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('products').add({
                  'title': titleController.text,
                  'price': priceController.text,
                  'unit': unitController.text,
                  'image': "assets/images/logo.png", // Default placeholder
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
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
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['fullName'] ?? 'No Name'),
                subtitle: Text(user['email'] ?? 'No Email'),
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
}
