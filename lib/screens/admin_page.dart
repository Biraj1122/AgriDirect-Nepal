import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../models/research_submission_model.dart';
import '../models/price_request_model.dart';
import 'auth/login_screen.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    if (viewModel.isCheckingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
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
            onPressed: () => viewModel.logout(context, const LoginScreen()),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      drawer: isWide ? null : _buildSidePanel(context, viewModel),
      body: Row(
        children: [
          if (isWide) _buildPersistentPanel(context, viewModel),
          Expanded(
            child: viewModel.currentIndex < 8 
              ? IndexedStack(
                index: viewModel.currentIndex,
                children: [
                  _buildDashboard(context, viewModel),
                  _buildOrdersList(context, viewModel),
                  _buildProductsList(context, viewModel),
                  _buildUsersList(context, viewModel),
                  _buildAnnouncementManager(context, viewModel),
                  _buildResearchManager(context, viewModel),
                  _buildRevenueAnalyticsPage(context, viewModel),
                  _buildPriceApprovalsList(context, viewModel),
                ],
              )
              : const Center(child: Text("Page Not Found")),
          ),
        ],
      ),
      bottomNavigationBar: isWide || viewModel.currentIndex >= 5
          ? null
          : BottomNavigationBar(
        currentIndex: viewModel.currentIndex,
        onTap: (index) => viewModel.setCurrentIndex(index),
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

  Widget _buildPersistentPanel(BuildContext context, AdminViewModel viewModel) {
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
          _panelItem(context, viewModel, 0, Icons.dashboard, "Dashboard"),
          _panelItem(context, viewModel, 1, Icons.shopping_bag, "Orders Management"),
          _panelItem(context, viewModel, 2, Icons.inventory_2, "Products & Inventory"),
          _panelItem(context, viewModel, 3, Icons.people, "User Database"),
          _panelItem(context, viewModel, 4, Icons.campaign, "Announcements"),
          _panelItem(context, viewModel, 5, Icons.health_and_safety, "Research Data"),
          _panelItem(context, viewModel, 7, Icons.price_check, "Price Approvals"),
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
            onTap: () => _showAddProductDialog(context, viewModel),
          ),
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.orange),
            title: const Text("Push Notification"),
            onTap: () => _showPushNotificationDialog(context, viewModel),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: const Text("Seed Database"),
            onTap: () => _handleSeedDatabase(context, viewModel),
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.green),
            title: const Text("Revenue Analytics"),
            onTap: () => viewModel.setCurrentIndex(6),
          ),
          const Spacer(),
          const Text("AgriDirect v1.0", style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _panelItem(BuildContext context, AdminViewModel viewModel, int index, IconData icon, String label) {
    bool selected = viewModel.currentIndex == index;
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.green.withValues(alpha: 0.1),
      leading: Icon(icon, color: selected ? Colors.green : Colors.grey),
      title: Text(label, style: TextStyle(color: selected ? Colors.green : Colors.black)),
      onTap: () => viewModel.setCurrentIndex(index),
    );
  }

  Widget _buildSidePanel(BuildContext context, AdminViewModel viewModel) {
    return Drawer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Admin Control Panel", style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(viewModel.adminEmail ?? "Not Logged In"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.green),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),
            _panelItem(context, viewModel, 0, Icons.dashboard, "Main Dashboard"),
            _panelItem(context, viewModel, 1, Icons.shopping_bag, "Order Management"),
            _panelItem(context, viewModel, 2, Icons.inventory_2, "Inventory / Products"),
            _panelItem(context, viewModel, 3, Icons.people, "User Registry"),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text("Manage Announcements"),
              onTap: () {
                viewModel.setCurrentIndex(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: Colors.orange),
              title: const Text("Send Notification"),
              onTap: () {
                Navigator.pop(context);
                _showPushNotificationDialog(context, viewModel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.blue),
              title: const Text("Seed Database"),
              onTap: () {
                Navigator.pop(context);
                _handleSeedDatabase(context, viewModel);
              },
            ),
            _panelItem(context, viewModel, 5, Icons.health_and_safety, "Research Data"),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.green),
              title: const Text("Revenue Analytics"),
              onTap: () {
                viewModel.setCurrentIndex(6);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout Admin", style: TextStyle(color: Colors.red)),
              onTap: () => viewModel.logout(context, const LoginScreen()),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<OrderModel>>(
      stream: viewModel.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final orders = snapshot.data ?? [];
        double totalRevenue = 0;
        int pendingDeliveries = 0;

        for (var order in orders) {
          totalRevenue += order.total;
          String status = order.status.toLowerCase();
          if (status == 'pending' || status == 'processing') pendingDeliveries++;
        }

        return StreamBuilder<List<Product>>(
          stream: viewModel.getProducts(),
          builder: (context, prodSnap) {
            int totalProducts = prodSnap.data?.length ?? 0;

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
                          GestureDetector(onTap: () => viewModel.setCurrentIndex(6), child: _dashboardCard("Total Revenue", "Rs. ${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.green, cardWidth)),
                          GestureDetector(onTap: () => viewModel.setCurrentIndex(1), child: _dashboardCard("Total Orders", "${orders.length}", Icons.shopping_bag, Colors.blue, cardWidth)),
                          GestureDetector(onTap: () => viewModel.setCurrentIndex(2), child: _dashboardCard("Total Products", "$totalProducts", Icons.inventory_2, Colors.orange, cardWidth)),
                          GestureDetector(onTap: () { viewModel.setCurrentIndex(1); viewModel.setShowPendingOnly(true); }, child: _dashboardCard("Pending Shipments", "$pendingDeliveries", Icons.local_shipping, Colors.purple, cardWidth)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text("Recent System Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: orders.isEmpty
                        ? const Padding(padding: EdgeInsets.all(30), child: Center(child: Text("No orders found in database")))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length > 5 ? 5 : orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xffF7F8F3), child: Icon(Icons.receipt_long, color: Colors.green, size: 20)),
                          title: Text("Order #${order.id.substring(0, 6)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Status: ${order.status}"),
                          trailing: Text("Rs. ${order.total}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<OrderModel>>(
      stream: viewModel.getOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var orders = snapshot.data!;

        if (viewModel.showPendingOnly) {
          orders = orders.where((order) => order.status.toLowerCase() == 'pending').toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("Order #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Customer: ${order.userName ?? 'N/A'} | Status: ${order.status}"),
                trailing: DropdownButton<String>(
                  value: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].contains(order.status) ? order.status : 'Pending',
                  items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => viewModel.updateOrderStatus(order.id, val!),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsList(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<Product>>(
      stream: viewModel.getProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Products in Catalog: ${products.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(onPressed: () => _showAddProductDialog(context, viewModel), icon: const Icon(Icons.add), label: const Text("Add Product")),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: ListTile(
                      leading: Image.network(product.image, width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                      title: Text(product.title),
                      subtitle: Text("Category: ${product.category} | Price: Rs. ${product.price}"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => viewModel.deleteProduct(product.id!)),
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

  Widget _buildUsersList(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<UserModel>>(
      stream: viewModel.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              child: ListTile(
                title: Text(user.fullName ?? 'N/A'),
                subtitle: Text("${user.email} | Role: ${user.role}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _showUserDetails(context, user),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementManager(BuildContext context, AdminViewModel viewModel) {
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
                      await viewModel.updateAnnouncement(titleController.text, contentController.text);
                      titleController.clear();
                      contentController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement updated")));
                      }
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

  Widget _buildResearchManager(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<ResearchSubmissionModel>>(
      stream: viewModel.getResearchSubmissions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final research = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: research.length,
          itemBuilder: (context, index) {
            final item = research[index];
            return Card(
              child: ListTile(
                title: Text(item.cropName ?? 'Unknown Crop'),
                subtitle: Text("Diagnosis: ${item.diagnosis ?? 'N/A'}"),
                trailing: const Icon(Icons.science_outlined),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueAnalyticsPage(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<OrderModel>>(
      stream: viewModel.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data ?? [];
        Map<String, double> revenueByDate = {};
        double totalRevenue = 0;

        for (var order in orders) {
          totalRevenue += order.total;

          String dateKey = "Today";
          if (order.createdAt != null) {
            dateKey = "${order.createdAt!.day}/${order.createdAt!.month}";
          }
          revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + order.total;
        }

        List<FlSpot> spots = [];
        int index = 0;
        revenueByDate.forEach((date, revenue) {
          spots.add(FlSpot(index.toDouble(), revenue));
          index++;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => viewModel.setCurrentIndex(0),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Back to Dashboard", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Revenue Analytics", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Revenue", style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text("Rs. ${totalRevenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (spots.isNotEmpty)
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.green, barWidth: 3)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceApprovalsList(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<PriceRequestModel>>(
      stream: viewModel.getPriceRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return const Center(child: Text("No pending price update requests."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(request.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(request.farmName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _priceChangeChip("Old", request.oldPrice, request.oldUnit, Colors.grey),
                        const Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                        _priceChangeChip("New", request.newPrice, request.newUnit, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => viewModel.declinePriceRequest(request),
                          child: const Text("Decline", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => viewModel.approvePriceRequest(request),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Approve", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _priceChangeChip(String label, double price, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(50))),
      child: Text("$label: Rs. $price / $unit", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _showAddProductDialog(BuildContext context, AdminViewModel viewModel) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController();
    final stockController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text("New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Product Name"),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Price (Rs.)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: "Stock (optional)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: "Image URL"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                if (nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name and price are required")),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  await viewModel.addProduct({
                    'name': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'stock': int.tryParse(stockController.text.trim()) ?? 0,
                    'imageUrl': imageUrlController.text.trim(),
                    'createdAt': DateTime.now(),
                  });

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Product added successfully")),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error adding product: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isSaving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Add Product", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPushNotificationDialog(BuildContext context, AdminViewModel viewModel) {
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
              await viewModel.sendGlobalNotification(titleController.text, bodyController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  Future<void> _handleSeedDatabase(BuildContext context, AdminViewModel viewModel) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await viewModel.seedDatabase();
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

  void _showUserDetails(BuildContext context, UserModel user) {
    final double? lat = user.lat;
    final double? lng = user.lng;
    final String address = user.address ?? 'No address saved';

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
              const Text("User Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              _detailRow(Icons.person, "Full Name", user.fullName ?? 'N/A'),
              _detailRow(Icons.email, "Email", user.email ?? 'N/A'),
              _detailRow(Icons.phone, "Phone", user.phone ?? 'N/A'),
              _detailRow(Icons.location_on, "Address", address),
              _detailRow(Icons.badge, "Role", user.role ?? 'Customer'),
              const SizedBox(height: 20),
              const Text("Location on Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (lat != null && lng != null)
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: MapLibreMap(
                    initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 14.5),
                    styleString: "https://tiles.openfreemap.org/styles/positron",
                  ),
                ),
            ],
          ),
        ),
      ),
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
