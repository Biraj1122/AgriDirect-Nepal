import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:image_picker/image_picker.dart';
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
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            int totalOrders = 0;
            double totalRevenue = 0;
            int pendingDeliveries = 0;
            int totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
            List<DocumentSnapshot> recentOrders = [];

            if (orderSnapshot.hasData) {
              final docs = orderSnapshot.data!.docs;
              totalOrders = docs.length;
              recentOrders = docs.toList()..sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
              });

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalRevenue += (data['total'] ?? 0);
                if (data['status'] == 'Pending' || data['status'] == 'On the way') {
                  pendingDeliveries++;
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (orderSnapshot.hasError || productSnapshot.hasError)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Error connecting to Firebase: ${orderSnapshot.error ?? productSnapshot.error}",
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      Expanded(child: _statCard("Pending Deliveries", pendingDeliveries.toString(), Icons.delivery_dining, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (recentOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text("No recent activity", style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...recentOrders.take(5).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final status = data['status'] ?? 'Pending';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                            child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 20),
                          ),
                          title: Text("Order from ${data['userName'] ?? 'User'}"),
                          subtitle: Text("${DateFormat('MMM d, h:mm a').format(date)} • $status"),
                          onTap: () => _showOrderDetails(context, doc.id, data),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered': return Icons.check_circle;
      case 'On the way': return Icons.local_shipping;
      case 'Cancelled': return Icons.cancel;
      default: return Icons.pending_actions;
    }
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

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(item['image']),
                        ),
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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductImage(dynamic imagePath) {
    if (imagePath == null || imagePath.toString().isEmpty) {
      return const Icon(Icons.image, color: Colors.grey);
    }
    String path = imagePath.toString();
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, 
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red));
    } else if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red));
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.red);
      }
    } else if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.image, color: Colors.grey);
    }
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
          List<DocumentSnapshot> docs = [];
          if (snapshot.hasData) docs = snapshot.data!.docs;

          if (docs.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("No products found in cloud."),
                  if (snapshot.hasError) const Text("(Firebase Access Denied)", style: TextStyle(color: Colors.red, fontSize: 10)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _seedInitialProducts,
                    child: const Text("Seed Sample Products"),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProductImage(product['image']),
                    ),
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
        'longDescription': "These fresh organic tomatoes are hand-picked from the local farms of Nepal. They are rich in vitamins and minerals, perfect for your daily salads and cooking needs. No pesticides used.",
        'category': 'Vegetables',
      },
      {
        'image': "assets/images/potato png.png",
        'title': "Organic Potatoes",
        'price': "80",
        'unit': "1kg",
        'description': "Naturally grown potatoes rich in nutrients.",
        'longDescription': "Our organic potatoes are grown in the fertile soil of the Himalayan foothills. They are firm, flavorful, and perfect for roasting, boiling, or making traditional Nepali dishes.",
        'category': 'Vegetables',
      },
      {
        'image': "assets/images/green cabbage.png",
        'title': "Green Cabbage",
        'price': "60",
        'unit': "1kg",
        'description': "Healthy green cabbage freshly harvested.",
        'longDescription': "Freshly harvested green cabbage, packed with fiber and nutrients. It has a crisp texture and a sweet, mild flavor that enhances any meal.",
        'category': 'Vegetables',
      },
      {
        'image': "assets/images/milk png.png",
        'title': "Farm Fresh Milk",
        'price': "110",
        'unit': "1L",
        'description': "Pure farm fresh milk from healthy cows.",
        'longDescription': "High-quality, pure farm fresh milk collected daily from healthy, grass-fed cows. It is pasteurized for safety while maintaining its natural creaminess and nutritional value.",
        'category': 'Dairy',
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
    final descController = TextEditingController();
    final urlController = TextEditingController();
    String selectedCategory = 'Vegetables';
    String? base64Image;
    bool isUploading = false;

    final List<String> categories = [
      'Vegetables', 'Fruits', 'Dairy', 'Grains', 'Herbs', 'Organic', 'Seasonal'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Upload image or use a URL", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 15),
                
                // Image Preview
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 400, // Limit size to keep Base64 string manageable
                      maxHeight: 400,
                      imageQuality: 70,
                    );
                    
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final base64 = base64Encode(bytes);
                      setDialogState(() {
                        base64Image = 'data:image/png;base64,$base64';
                        urlController.clear(); // Clear URL if image is picked
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              base64Decode(base64Image!.split(',').last),
                              fit: BoxFit.cover,
                            ),
                          )
                        : ValueListenableBuilder<TextEditingValue>(
                            valueListenable: urlController,
                            builder: (context, value, _) {
                              if (value.text.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    value.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.red),
                                  ),
                                );
                              }
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.green, size: 30),
                                  Text("Pick Image", style: TextStyle(fontSize: 10, color: Colors.green)),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: urlController, 
                  onChanged: (val) {
                    if (val.isNotEmpty && base64Image != null) {
                      setDialogState(() => base64Image = null);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Or Direct Image Link (URL)", 
                    hintText: "https://example.com/photo.jpg",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link, size: 20),
                  ),
                ),
                
                const SizedBox(height: 15),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (Rs.)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(labelText: "Unit (e.g. 1kg)", border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isUploading ? null : () async {
                if (titleController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  setDialogState(() => isUploading = true);
                  try {
                    String finalImageUrl = base64Image ?? urlController.text.trim();
                    if (finalImageUrl.isEmpty) finalImageUrl = "assets/images/logo.png";

                    await FirebaseFirestore.instance.collection('products').add({
                      'title': titleController.text.trim(),
                      'name': titleController.text.trim(),
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'unit': unitController.text.trim(),
                      'category': selectedCategory,
                      'description': descController.text.trim(),
                      'longDescription': descController.text.trim(),
                      'image': finalImageUrl,
                      'imagePath': finalImageUrl,
                      'badge': 'Fresh',
                      'badgeColor': const Color(0xFF4CAF50).toARGB32(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product added successfully!")));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                    }
                  } finally {
                    setDialogState(() => isUploading = false);
                  }
                }
              },
              child: isUploading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Add Product", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
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
