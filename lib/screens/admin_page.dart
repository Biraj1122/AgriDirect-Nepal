import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../models/research_submission_model.dart';
import '../models/price_request_model.dart';
import '../Success/shared_widgets.dart';
import 'auth/login_screen.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const Color primaryTeal = Color(0xFF1D9E75);
  static const Color secondaryBlue = Color(0xFF2E5BFF);
  static const Color backgroundColor = Color(0xffF8FAFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().refreshAdminState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    if (viewModel.isCheckingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("AgriDirect Admin", 
          style: TextStyle(color: Color(0xFF1A1D25), fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primaryTeal),
        actions: [
          IconButton(
            onPressed: () => viewModel.refreshAdminState(),
            icon: const Icon(Icons.refresh_rounded, color: primaryTeal),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: TextButton.icon(
              onPressed: () => viewModel.logout(context, const LoginScreen()),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : _buildSidePanel(context, viewModel),
      body: Row(
        children: [
          if (isWide) _buildPersistentPanel(context, viewModel),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: viewModel.currentIndex < 9 
                ? IndexedStack(
                  key: ValueKey(viewModel.currentIndex),
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
                    _buildProductApprovalsList(context, viewModel),
                  ],
                )
                : const Center(child: Text("Page Not Found")),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide || viewModel.currentIndex >= 5
          ? null
          : BottomNavigationBar(
        currentIndex: viewModel.currentIndex,
        onTap: (index) => viewModel.setCurrentIndex(index),
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dash"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: "Catalog"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: "News"),
        ],
      ),
    );
  }

  Widget _buildPersistentPanel(BuildContext context, AdminViewModel viewModel) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                IconBadge(teal: primaryTeal, blue: secondaryBlue, icon: Icons.admin_panel_settings_rounded),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Admin", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      Text(viewModel.adminEmail?.split('@').first ?? "Manager", 
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500), 
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _panelItem(context, viewModel, 0, Icons.dashboard_rounded, "Overview"),
                _panelItem(context, viewModel, 1, Icons.shopping_cart_rounded, "Order Management"),
                _panelItem(context, viewModel, 2, Icons.inventory_2_rounded, "Products Catalog"),
                _panelItem(context, viewModel, 3, Icons.people_alt_rounded, "User Database"),
                _panelItem(context, viewModel, 4, Icons.campaign_rounded, "Announcements"),
                _panelItem(context, viewModel, 5, Icons.science_rounded, "Research Insights"),
                _panelItem(context, viewModel, 7, Icons.price_change_rounded, "Price Approvals"),
                _panelItem(context, viewModel, 8, Icons.verified_user_rounded, "Product Verification"),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text("INSIGHTS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ),
                _panelItem(context, viewModel, 6, Icons.analytics_rounded, "Revenue Reports"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GradientButton(
              label: "New Product",
              icon: Icons.add_rounded,
              isLoading: false,
              teal: primaryTeal,
              blue: secondaryBlue,
              onTap: () => _showAddProductDialog(context, viewModel),
            ),
          ),
          const Text("AgriDirect v2.0", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _panelItem(BuildContext context, AdminViewModel viewModel, int index, IconData icon, String label) {
    bool selected = viewModel.currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: primaryTeal.withValues(alpha: 0.1),
        leading: Icon(icon, color: selected ? primaryTeal : Colors.grey.shade400, size: 22),
        title: Text(label, style: TextStyle(
          color: selected ? primaryTeal : const Color(0xFF1A1D25),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14
        )),
        onTap: () => viewModel.setCurrentIndex(index),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context, AdminViewModel viewModel) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [primaryTeal, secondaryBlue]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(viewModel.adminEmail ?? "Administrator", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("System Control Access", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _sideDrawerItem(context, viewModel, 0, Icons.dashboard_rounded, "Dashboard"),
                _sideDrawerItem(context, viewModel, 1, Icons.shopping_bag_rounded, "Orders"),
                _sideDrawerItem(context, viewModel, 2, Icons.inventory_2_rounded, "Products"),
                _sideDrawerItem(context, viewModel, 3, Icons.people_rounded, "Users"),
                _sideDrawerItem(context, viewModel, 7, Icons.price_check_rounded, "Price Requests"),
                _sideDrawerItem(context, viewModel, 8, Icons.approval_rounded, "Approvals"),
                const Divider(),
                _sideDrawerItem(context, viewModel, 4, Icons.campaign_rounded, "Announcements"),
                _sideDrawerItem(context, viewModel, 6, Icons.analytics_rounded, "Analytics"),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => viewModel.logout(context, const LoginScreen()),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sideDrawerItem(BuildContext context, AdminViewModel viewModel, int index, IconData icon, String label) {
    bool selected = viewModel.currentIndex == index;
    return ListTile(
      selected: selected,
      selectedTileColor: primaryTeal.withValues(alpha: 0.1),
      leading: Icon(icon, color: selected ? primaryTeal : Colors.grey),
      title: Text(label, style: TextStyle(color: selected ? primaryTeal : Colors.black, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        viewModel.setCurrentIndex(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<OrderModel>>(
      stream: viewModel.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryTeal));
        }

        final orders = snapshot.data ?? [];
        double totalRevenue = 0;
        int activeOrders = 0;
        int completedOrders = 0;

        for (var order in orders) {
          totalRevenue += order.adminRevenue;
          String status = order.status.toLowerCase();
          if (status == 'delivered' || status == 'cancelled') {
            completedOrders++;
          } else {
            activeOrders++;
          }
        }

        return StreamBuilder<List<Product>>(
          stream: viewModel.getProducts(),
          builder: (context, prodSnap) {
            int totalProducts = prodSnap.data?.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Heading(title: "Overview", subtitle: "Real-time statistics of your marketplace"),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth = constraints.maxWidth > 900 ? (constraints.maxWidth - 60) / 4 : (constraints.maxWidth - 20) / 2;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _dashboardCard("Total Revenue", "Rs. ${totalRevenue.toStringAsFixed(0)}", Icons.payments_rounded, Colors.green, cardWidth, () => viewModel.setCurrentIndex(6)),
                          _dashboardCard("Active Orders", "$activeOrders", Icons.shopping_cart_checkout_rounded, Colors.orange, cardWidth, () => viewModel.setCurrentIndex(1)),
                          _dashboardCard("Products", "$totalProducts", Icons.inventory_2_rounded, Colors.blue, cardWidth, () => viewModel.setCurrentIndex(2)),
                          _dashboardCard("Completed", "$completedOrders", Icons.task_alt_rounded, Colors.purple, cardWidth, () { viewModel.setCurrentIndex(1); }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1D25))),
                      TextButton(onPressed: () => viewModel.setCurrentIndex(1), child: const Text("View All")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
                    ),
                    child: orders.isEmpty
                        ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No transactions yet")))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length > 6 ? 6 : orders.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _getStatusColor(order.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 20),
                          ),
                          title: Text("Order #${order.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(order.status, style: TextStyle(color: _getStatusColor(order.status), fontSize: 12, fontWeight: FontWeight.w500)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Rs. ${order.total}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(order.createdAt != null ? DateFormat('MMM d, h:mm a').format(order.createdAt!) : "Just now", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                          onTap: () => _showOrderDetails(context, order, viewModel),
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

  Widget _dashboardCard(String title, String value, IconData icon, Color color, double width, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, AdminViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Expanded(child: Heading(title: "Orders", subtitle: "Monitor and manage all customer orders")),
              ToggleButtons(
                isSelected: [!viewModel.showPendingOnly, viewModel.showPendingOnly],
                onPressed: (index) => viewModel.setShowPendingOnly(index == 1),
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                selectedColor: Colors.white,
                fillColor: primaryTeal,
                children: const [
                  Text("All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text("Pending", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: viewModel.getOrders(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              
              var orders = snapshot.data!;
              if (viewModel.showPendingOnly) {
                orders = orders.where((order) => order.status.toLowerCase() == 'pending').toList();
              }
  
              if (orders.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No orders found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ],
                ));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Row(
                        children: [
                          Text("Order #${order.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          _statusChip(order.status),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Customer: ${order.userName ?? 'Guest'} • Items: ${order.items?.length ?? 0}", 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Rs. ${order.total}", style: const TextStyle(fontWeight: FontWeight.w800, color: primaryTeal, fontSize: 16)),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showOrderDetails(context, order, viewModel),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'farmer accepted': return Colors.teal;
      case 'picked up': return Colors.indigo;
      case 'on the way': return Colors.cyan;
      case 'arrived': return Colors.lightGreen;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'shipped': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'processing': return Icons.sync_rounded;
      case 'farmer accepted': return Icons.assignment_turned_in_rounded;
      case 'picked up': return Icons.inventory_2_rounded;
      case 'on the way': return Icons.local_shipping_rounded;
      case 'arrived': return Icons.location_on_rounded;
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'shipped': return Icons.flight_takeoff_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order, AdminViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1D25))),
                          Text("#${order.id.toUpperCase()}", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      _statusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const FieldLabel(label: "ORDER PROGRESS"),
                  const SizedBox(height: 16),
                  _buildOrderStepIndicator(order.status),
                  const SizedBox(height: 32),
                  const FieldLabel(label: "ACTION"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: [
                          'Pending', 'Farmer Accepted', 'Processing', 'Picked Up', 
                          'On the way', 'Arrived', 'Shipped', 'Delivered', 'Cancelled'
                        ].contains(order.status) ? order.status : 'Pending',
                        items: [
                          'Pending', 'Farmer Accepted', 'Processing', 'Picked Up', 
                          'On the way', 'Arrived', 'Shipped', 'Delivered', 'Cancelled'
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            viewModel.updateOrderStatus(order.id, val);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const FieldLabel(label: "SUMMARY"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _summaryRow("Customer", order.userName ?? "N/A"),
                        _summaryRow("Total Price", "Rs. ${order.total}"),
                        _summaryRow("Admin Fee", "Rs. ${order.adminRevenue.toStringAsFixed(2)}", isLast: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStepIndicator(String status) {
    int step = 0;
    List<String> labels = ['Pending', 'Confirmed', 'Picked Up', 'Delivered'];
    
    switch (status.toLowerCase()) {
      case 'pending': step = 0; break;
      case 'farmer accepted':
      case 'processing': step = 1; break;
      case 'picked up':
      case 'on the way':
      case 'arrived':
      case 'shipped': step = 2; break;
      case 'delivered': step = 3; break;
      case 'cancelled': step = 0; labels[0] = 'Cancelled'; break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (i) {
        bool isDone = i < step;
        bool isActive = i == step;
        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? primaryTeal : isActive ? primaryTeal.withValues(alpha: 0.1) : Colors.grey.shade100,
                border: Border.all(color: isDone || isActive ? primaryTeal : Colors.grey.shade200),
              ),
              child: Center(
                child: isDone 
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text("${i+1}", style: TextStyle(color: isActive ? primaryTeal : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? primaryTeal : Colors.grey)),
          ],
        );
      }),
    );
  }

  Widget _summaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1D25))),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, AdminViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Heading(title: "Catalog", subtitle: "Global inventory management"),
              IconButton(onPressed: () => _showAddProductDialog(context, viewModel), icon: const Icon(Icons.add_circle_rounded, color: primaryTeal, size: 32)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: viewModel.getProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final products = snapshot.data!;
      
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          width: 56, height: 56, fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade100),
                          errorWidget: (context, url, error) => const Icon(Icons.image_outlined),
                        ),
                      ),
                      title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text("${product.category} • Rs. ${product.price}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), 
                        onPressed: () => _confirmDelete(context, () => viewModel.deleteProduct(product.id!))
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, AdminViewModel viewModel) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Users", subtitle: "All registered farmers, riders and customers"),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: viewModel.getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final users = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                        child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role), size: 20),
                      ),
                      title: Text(user.fullName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${user.email} • ${user.role}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => _showUserDetails(context, user),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'farmer': return Colors.green;
      case 'delivery person': return Colors.orange;
      case 'admin': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'farmer': return Icons.agriculture_rounded;
      case 'delivery person': return Icons.delivery_dining_rounded;
      case 'admin': return Icons.admin_panel_settings_rounded;
      default: return Icons.person_rounded;
    }
  }

  Widget _buildAnnouncementManager(BuildContext context, AdminViewModel viewModel) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(title: "Announcements", subtitle: "Broadcast news to all app users"),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: "BANNER TITLE"),
                const SizedBox(height: 8),
                TextField(controller: titleController, decoration: customInputDecoration(hint: "Enter title", icon: Icons.title, teal: primaryTeal)),
                const SizedBox(height: 24),
                const FieldLabel(label: "MESSAGE CONTENT"),
                const SizedBox(height: 8),
                TextField(controller: contentController, maxLines: 4, decoration: customInputDecoration(hint: "Enter message", icon: Icons.message, teal: primaryTeal)),
                const SizedBox(height: 32),
                GradientButton(
                  label: "Update App Banner", 
                  icon: Icons.send_rounded, 
                  isLoading: false, 
                  teal: primaryTeal, blue: secondaryBlue, 
                  onTap: () async {
                    if (titleController.text.isEmpty) return;
                    await viewModel.updateAnnouncement(titleController.text, contentController.text);
                    titleController.clear();
                    contentController.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement published")));
                    }
                  }
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResearchManager(BuildContext context, AdminViewModel viewModel) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Research", subtitle: "Crop disease submissions and analysis"),
        ),
        Expanded(
          child: StreamBuilder<List<ResearchSubmissionModel>>(
            stream: viewModel.getResearchSubmissions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final research = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: research.length,
                itemBuilder: (context, index) {
                  final item = research[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: IconBadge(teal: Colors.purple, blue: Colors.deepPurple, icon: Icons.science_rounded),
                      title: Text(item.cropName ?? 'Unknown Crop', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Diagnosis: ${item.diagnosis ?? 'Pending Analysis'}"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueAnalyticsPage(BuildContext context, AdminViewModel viewModel) {
    return StreamBuilder<List<OrderModel>>(
      stream: viewModel.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryTeal));

        final orders = snapshot.data ?? [];
        Map<String, double> revenueByDate = {};
        double totalRevenue = 0;

        for (var order in orders) {
          totalRevenue += order.adminRevenue;
          String dateKey = "Today";
          if (order.createdAt != null) {
            dateKey = DateFormat('MM/dd').format(order.createdAt!);
          }
          revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + order.adminRevenue;
        }

        List<FlSpot> spots = [];
        List<String> labels = revenueByDate.keys.toList();
        for (int i = 0; i < labels.length; i++) {
          spots.add(FlSpot(i.toDouble(), revenueByDate[labels[i]]!));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => viewModel.setCurrentIndex(0), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryTeal)),
              const Heading(title: "Revenue Analytics", subtitle: "Financial performance overview"),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryTeal, secondaryBlue]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Platform Revenue", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text("Rs. ${totalRevenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (spots.isNotEmpty)
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots, 
                          isCurved: true, 
                          color: primaryTeal, 
                          barWidth: 4, 
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: primaryTeal.withValues(alpha: 0.1)),
                        )
                      ],
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Price Updates", subtitle: "Review farmer requests for price adjustments"),
        ),
        Expanded(
          child: StreamBuilder<List<PriceRequestModel>>(
            stream: viewModel.getPriceRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final requests = snapshot.data!;
      
              if (requests.isEmpty) {
                return const Center(child: Text("No pending price requests"));
              }
      
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(request.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            _statusChip("Pending"),
                          ],
                        ),
                        Text("Farmer: ${request.farmName}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _priceBox("From", request.oldPrice, request.oldUnit, Colors.grey.shade400),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward_rounded, color: primaryTeal),
                            ),
                            _priceBox("To", request.newPrice, request.newUnit, primaryTeal),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => viewModel.declinePriceRequest(request),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => viewModel.approvePriceRequest(request),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
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
        ),
      ],
    );
  }

  Widget _priceBox(String label, double price, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Rs. $price", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            Text("per $unit", style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductApprovalsList(BuildContext context, AdminViewModel viewModel) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Product Verification", subtitle: "Review new catalog submissions"),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: viewModel.getPendingProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final products = snapshot.data!;
      
              if (products.isEmpty) {
                return const Center(child: Text("No pending product approvals"));
              }
      
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: product.image,
                                width: 80, height: 80, fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                  Text("Farm: ${product.farmName ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text("Rs. ${product.price} / ${product.unit}", style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(product.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => viewModel.rejectProduct(product),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => viewModel.approveProduct(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
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
        ),
      ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Add to Global Catalog", style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: "PRODUCT NAME"),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: customInputDecoration(hint: "e.g. Organic Ginger", icon: Icons.shopping_basket, teal: primaryTeal)),
                const SizedBox(height: 16),
                const FieldLabel(label: "CATEGORY"),
                const SizedBox(height: 8),
                TextField(controller: categoryController, decoration: customInputDecoration(hint: "e.g. Vegetables", icon: Icons.category, teal: primaryTeal)),
                const SizedBox(height: 16),
                const FieldLabel(label: "PRICE (RS)"),
                const SizedBox(height: 8),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: customInputDecoration(hint: "0.00", icon: Icons.payments, teal: primaryTeal)),
                const SizedBox(height: 16),
                const FieldLabel(label: "IMAGE URL"),
                const SizedBox(height: 8),
                TextField(controller: imageUrlController, decoration: customInputDecoration(hint: "https://...", icon: Icons.image, teal: primaryTeal)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                  setDialogState(() => isSaving = true);
                  await viewModel.addProduct({
                    'name': nameController.text.trim(),
                    'title': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'stock': int.tryParse(stockController.text.trim()) ?? 0,
                    'image': imageUrlController.text.trim(),
                    'imageUrl': imageUrlController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Save Product", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                          child: Icon(_getRoleIcon(user.role), size: 50, color: _getRoleColor(user.role)),
                        ),
                        const SizedBox(height: 16),
                        Text(user.fullName ?? 'Unnamed User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        Text(user.role ?? 'Customer', style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const FieldLabel(label: "CONTACT INFORMATION"),
                  const SizedBox(height: 12),
                  _userInfoCard([
                    _infoRow(Icons.email_outlined, user.email ?? 'No email'),
                    _infoRow(Icons.phone_outlined, user.phone ?? 'No phone'),
                    _infoRow(Icons.location_on_outlined, user.address ?? 'No address'),
                  ]),
                  const SizedBox(height: 32),
                  if (user.lat != null && user.lng != null) ...[
                    const FieldLabel(label: "SAVED LOCATION"),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 200,
                        child: MapLibreMap(
                          initialCameraPosition: CameraPosition(target: LatLng(user.lat!, user.lng!), zoom: 14),
                          styleString: "https://tiles.openfreemap.org/styles/positron",
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1D25)))),
        ],
      ),
    );
  }
}
