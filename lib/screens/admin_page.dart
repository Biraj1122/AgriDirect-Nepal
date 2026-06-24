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
  bool _isCheckingRole = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logout();
      return;
    }

    try {
      if (user.email != 'agrifarmadmin@gmail.com') {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = doc.data()?['role'];

        if (role != 'Admin') {
          _logout();
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _isCheckingRole = false;
        });
      }
    } catch (e) {
      debugPrint("Admin check error: $e");
      if (mounted) {
        setState(() {
          _isCheckingRole = false;
        });
      }
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
    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }
    
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          stream: FirebaseFirestore.instance.collection('master_catalog').snapshots(),
          builder: (context, prodSnap) {
            int totalProducts = prodSnap.data?.docs.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth - 40) / 4 : (constraints.maxWidth - 20) / 2;
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          _dashboardCard("Total Revenue", "Rs. ${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.green, cardWidth),
                          _dashboardCard("Total Orders", "$totalOrders", Icons.shopping_bag, Colors.blue, cardWidth),
                          _dashboardCard("Total Products", "$totalProducts", Icons.inventory_2, Colors.orange, cardWidth),
                          _dashboardCard("Pending Shipments", "$pendingDeliveries", Icons.local_shipping, Colors.purple, cardWidth),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                  const Text("Recent System Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: docs.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(30), child: Center(child: Text("No orders found in database")))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length > 5 ? 5 : docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xffF7F8F3), child: Icon(Icons.receipt_long, color: Colors.green, size: 20)),
                              title: Text("Order #${docs[index].id.substring(0, 6)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Status: ${data['status'] ?? 'Pending'}"),
                              trailing: Text("Rs. ${data['total'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            );
                          },
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

  Widget _dashboardCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("Order #$id", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Customer: ${data['userName'] ?? 'N/A'} | Status: ${data['status'] ?? 'Pending'}"),
                trailing: DropdownButton<String>(
                  value: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].contains(data['status']) ? data['status'] : 'Pending',
                  items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => _updateOrderStatus(id, val!),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('master_catalog').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Products in Catalog: ${docs.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(onPressed: () => _showAddProductDialog(context), icon: const Icon(Icons.add), label: const Text("Add Product")),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: Image.network(data['imageUrl'] ?? data['image'] ?? '', width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                      title: Text(data['name'] ?? data['title'] ?? 'N/A'),
                      subtitle: Text("Category: ${data['category']} | Price: Rs. ${data['price']}"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('master_catalog').doc(docs[index].id).delete()),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['fullName'] ?? 'N/A'),
                subtitle: Text("${data['email']} | Role: ${data['role']}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _showUserDetails(context, data),
              ),
            );
          },
        );
      },
    );
  }

  void _updateOrderStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status});
    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(id).get();
    final userId = orderDoc.data()?['userId'];
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
        'title': 'Order Status Updated',
        'body': 'Your order status is now $status',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Product"),
        content: const Text("Product form is available in the Farmer tab."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _showPushNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Global Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: "Message")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final users = await FirebaseFirestore.instance.collection('users').get();
              for (var user in users.docs) {
                await user.reference.collection('notifications').add({
                  'title': titleController.text,
                  'body': bodyController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  Future<void> _handleSeedDatabase(BuildContext context) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await seedProducts();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database seeded successfully")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Seed error: $e")));
      }
    }
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
                        zoom: 14.5,
                      ),
                      styleString: "https://tiles.openfreemap.org/styles/positron",
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

    IconData selectedIcon = Icons.eco_outlined;

    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Manage Categories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                const Align(alignment: Alignment.centerLeft, child: Text("Pick Icon", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setInnerS) => Wrap(
                    spacing: 10,
                    children: availableIcons.map((ico) => IconButton(
                      icon: Icon(ico['icon'], color: selectedIcon == ico['icon'] ? Colors.green : Colors.grey),
                      onPressed: () => setInnerS(() => selectedIcon = ico['icon']),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      await FirebaseFirestore.instance.collection('categories').add({
                        'name': nameController.text.trim(),
                        'iconCode': selectedIcon.codePoint,
                      });
                      nameController.clear();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Create Category", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(IconData(data['iconCode'], fontFamily: 'MaterialIcons'), color: Colors.green),
                      title: Text(data['name']),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('categories').doc(snapshot.data!.docs[index].id).delete()),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnnouncementManager() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Manage Announcements", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Banner Title")),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: "Banner Content"), maxLines: 3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('settings').doc('announcement').set({
                        'title': titleController.text,
                        'content': contentController.text,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      titleController.clear();
                      contentController.clear();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Update App Banner", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResearchManager() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('research_submissions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['cropName'] ?? 'Unknown Crop'),
                subtitle: Text("Diagnosis: ${data['diagnosis'] ?? 'N/A'}"),
                trailing: const Icon(Icons.science_outlined),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}