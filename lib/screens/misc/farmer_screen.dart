import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmtech_agridirect/screens/auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';
import 'package:farmtech_agridirect/Success/shared_widgets.dart';

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
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _orderSubscription;
  int _unreadCount = 0;
  int _pendingOrderCount = 0;

  bool _isUpdatingPassword = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _setupGlobalListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _orderSubscription?.cancel();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setupGlobalListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _unreadCount = snapshot.docs.length);
    });

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Pending Farmer')
        .snapshots()
        .listen((snapshot) {
      final pendingOrders = snapshot.docs.where((d) => (d.data() as Map)['farmerUid'] == null).toList();
      final currentCount = pendingOrders.length;
      
      if (mounted) {
        if (currentCount > _pendingOrderCount && _currentIndex != 0) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("New order request available!"),
              backgroundColor: primaryTeal,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: "VIEW", textColor: Colors.white, onPressed: () {
                setState(() => _currentIndex = 0);
              }),
            )
          );
        }
        setState(() => _pendingOrderCount = currentCount);
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      _markNotificationsAsRead();
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
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

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: customInputDecoration(hint: "Current Password", icon: Icons.lock_outline, teal: primaryTeal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: customInputDecoration(hint: "New Password", icon: Icons.vpn_key_outlined, teal: primaryTeal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: customInputDecoration(hint: "Confirm New Password", icon: Icons.check_circle_outline, teal: primaryTeal),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _isUpdatingPassword ? null : () async {
                  if (_newPasswordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                    return;
                  }
                  
                  setDialogState(() => _isUpdatingPassword = true);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    final cred = EmailAuthProvider.credential(email: user!.email!, password: _currentPasswordController.text);
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(_newPasswordController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
                    }
                  } finally {
                    setDialogState(() => _isUpdatingPassword = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isUpdatingPassword 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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
      _CatalogTab(
        uid: uid,
        farmName: farmName,
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
      _ProfileTab(uid: uid, farmerName: farmerName, email: FirebaseAuth.instance.currentUser?.email ?? '', onChangePassword: _showChangePasswordDialog),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 20,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_unreadCount + _pendingOrderCount}'),
              isLabelVisible: _currentIndex != 0 && (_unreadCount + _pendingOrderCount > 0),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.dashboard_rounded),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.apps_rounded), label: 'Catalog'),
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'My Store'),
          const BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;
  const _CatalogTab({required this.uid, required this.farmName, this.farmerLat, this.farmerLng});

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Global Catalog", subtitle: "Pick items you grow to list them in your store"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: customInputDecoration(hint: "Search global catalog...", icon: Icons.search, teal: _FarmerScreenState.primaryTeal),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('master_catalog').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _FarmerScreenState.primaryTeal));
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No items found in catalog"));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () => _showPickDialog(data),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: SafeProductImage(imageUrl: data['image'] ?? '', width: double.infinity, fit: BoxFit.cover),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(data['category'] ?? 'General', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text("Suggested: Rs. ${data['price']}/${data['unit']}", style: const TextStyle(color: _FarmerScreenState.primaryTeal, fontWeight: FontWeight.w700, fontSize: 12)),
                              ],
                            ),
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
    );
  }

  void _showPickDialog(Map<String, dynamic> catalogData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductForm(
        uid: widget.uid,
        farmName: widget.farmName,
        farmerLat: widget.farmerLat,
        farmerLng: widget.farmerLng,
        prefillData: catalogData,
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final String uid, farmerName, email;
  final VoidCallback onChangePassword;
  const _ProfileTab({required this.uid, required this.farmerName, required this.email, required this.onChangePassword});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
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
                          backgroundImage: (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
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
                  Text(widget.email, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const FieldLabel(label: "SECURITY"),
            const SizedBox(height: 12),
            _profileItem(Icons.lock_reset_rounded, "Change Password", onTap: widget.onChangePassword),
            _profileItem(Icons.verified_user_rounded, "Verified Farmer Partner"),
          ],
        );
      }
    );
  }

  Widget _profileItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D9E75), size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
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
  int _carouselItemCount = 0;

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
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _carouselItemCount > 1) {
        int nextIndex = (_currentCarouselIndex + 1) % _carouselItemCount;
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
        boxShadow: [
          BoxShadow(color: const Color(0xFF1D9E75).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white24, size: 64),
        ],
      ),
    );
  }

  void _showRevenueDetails(BuildContext context, List<QueryDocumentSnapshot> docs, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Heading(title: "Income Details", subtitle: "Breakdown of your earnings (80% share)"),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final subtotal = (data['subtotal'] ?? 0).toDouble();
                  final net = subtotal * 0.8;
                  final fee = subtotal * 0.2;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Order #${docs[i].id.substring(0,8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Rs. ${subtotal.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 24),
                        _incomeRow("Gross Sale Amount", subtotal),
                        _incomeRow("App Commission (20%)", -fee, isNegative: true),
                        const Divider(height: 24),
                        _incomeRow("Your Earnings", net, isBold: true, color: const Color(0xFF1D9E75)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomeRow(String label, double amount, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${isNegative ? '-' : ''}Rs. ${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (isNegative ? Colors.redAccent : Colors.black)),
        ),
      ],
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
            _carouselItemCount = notifications.isEmpty ? 1 : notifications.length;

            return SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
                    itemCount: _carouselItemCount,
                    itemBuilder: (context, i) {
                      if (notifications.isEmpty) {
                        return _buildCarouselSlide("Fresh Harvest Awaits", "Keep track of your products and orders efficiently.", Icons.eco_rounded);
                      }
                      final data = notifications[i].data() as Map<String, dynamic>;
                      return _buildCarouselSlide(data['title'] ?? 'Notification', data['body'] ?? '', Icons.info_outline_rounded);
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 24,
                    child: Row(
                      children: List.generate(
                        _carouselItemCount,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 6),
                          width: _currentCarouselIndex == index ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: _currentCarouselIndex == index ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  )
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
            final availableDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['farmerUid'] == null && data['status'] != 'Cancelled';
            }).toList();

            if (availableDocs.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: "NEW ORDER REQUESTS"),
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
            final deliveredDocs = docs.where((d) => (d.data() as Map)['status'] == 'Delivered').toList();
            double totalNetEarnings = 0;
            int pendingCount = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['status'] == 'Delivered') {
                totalNetEarnings += ((data['subtotal'] ?? 0) * 0.8).toDouble();
              } else if (data['status'] != 'Cancelled') {
                pendingCount++;
              }
            }

            return Row(
              children: [
                _StatCard(
                  title: "Total Revenue", 
                  value: "Rs. ${totalNetEarnings.toStringAsFixed(0)}", 
                  icon: Icons.payments_rounded, 
                  color: const Color(0xFF1D9E75),
                  onTap: () => _showRevenueDetails(context, deliveredDocs, totalNetEarnings),
                ),
                const SizedBox(width: 16),
                _StatCard(title: "Active Tasks", value: "$pendingCount", icon: Icons.pending_actions_rounded, color: const Color(0xFF2E5BFF)),
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

  void _showEditPrice(String productId, String name, double currentPrice, String unit) {
    final priceController = TextEditingController(text: currentPrice.toString());
    final unitController = TextEditingController(text: unit);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Update Price: $name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: customInputDecoration(hint: "New Price", icon: Icons.payments, teal: _FarmerScreenState.primaryTeal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: customInputDecoration(hint: "Unit (e.g. kg)", icon: Icons.scale, teal: _FarmerScreenState.primaryTeal),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setDialogState(() => isSubmitting = true);
                try {
                  await FirebaseFirestore.instance.collection('price_requests').add({
                    'productId': productId,
                    'productName': name,
                    'farmerUid': widget.uid,
                    'farmName': widget.farmName,
                    'oldPrice': currentPrice,
                    'newPrice': double.parse(priceController.text),
                    'oldUnit': unit,
                    'newUnit': unitController.text,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price update request sent to Admin")));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _FarmerScreenState.primaryTeal),
              child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Request Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
            child: Heading(title: "My Store", subtitle: "Manage your farm products for sale"),
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
                        const Text("No products yet in your store", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
      
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                    final unit = data['unit'] ?? 'kg';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SafeProductImage(
                                imageUrl: data['image'] ?? '',
                                width: 60, height: 60, fit: BoxFit.cover,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(data['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w700))),
                                StatusBadge(status: status),
                              ],
                            ),
                            subtitle: Text("Rs. $price / $unit"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => FirebaseFirestore.instance.collection('products').doc(docs[i].id).delete(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showEditPrice(docs[i].id, data['name'], price, unit),
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text("Update Price", style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final String uid, farmName;
  final double? farmerLat, farmerLng;
  final Map<String, dynamic>? prefillData;

  const _ProductForm({required this.uid, required this.farmName, this.farmerLat, this.farmerLng, this.prefillData});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController unit;
  late final TextEditingController description;
  XFile? selectedImage;
  String? prefilledImageUrl;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.prefillData?['name'] ?? '');
    price = TextEditingController(text: widget.prefillData?['price']?.toString() ?? '');
    unit = TextEditingController(text: widget.prefillData?['unit'] ?? 'kg');
    description = TextEditingController(text: widget.prefillData?['description'] ?? '');
    prefilledImageUrl = widget.prefillData?['image'] ?? widget.prefillData?['imageUrl'];
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    unit.dispose();
    description.dispose();
    super.dispose();
  }

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
            Heading(
              title: widget.prefillData != null ? "Pick from Catalog" : "Add Custom Product", 
              subtitle: widget.prefillData != null ? "Set your own price and stock for this item" : "List your unique produce on the market"
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: widget.prefillData != null ? null : () async {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (img != null) setState(() => selectedImage = img);
                },
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(File(selectedImage!.path), fit: BoxFit.cover))
                      : (prefilledImageUrl != null)
                        ? ClipRRect(borderRadius: BorderRadius.circular(24), child: SafeProductImage(imageUrl: prefilledImageUrl!, fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo_rounded, color: Colors.grey, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FieldLabel(label: "PRODUCT NAME"),
            const SizedBox(height: 8),
            TextField(
              controller: name, 
              enabled: widget.prefillData == null,
              decoration: customInputDecoration(hint: "e.g. Fresh Tomatoes", icon: Icons.eco, teal: const Color(0xFF1D9E75))
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel(label: "PRICE (RS)"),
                      const SizedBox(height: 8),
                      TextField(controller: price, keyboardType: TextInputType.number, decoration: customInputDecoration(hint: "0.00", icon: Icons.payments, teal: const Color(0xFF1D9E75))),
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
                      TextField(controller: unit, decoration: customInputDecoration(hint: "kg/ltr/bunch", icon: Icons.scale, teal: const Color(0xFF1D9E75))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const FieldLabel(label: "SHORT DESCRIPTION"),
            const SizedBox(height: 8),
            TextField(controller: description, decoration: customInputDecoration(hint: "A brief note about quality...", icon: Icons.description, teal: const Color(0xFF1D9E75))),
            const SizedBox(height: 32),
            GradientButton(
              label: widget.prefillData != null ? "Add to My Store" : "List Product", 
              icon: Icons.check_rounded, 
              isLoading: isUploading, 
              teal: const Color(0xFF1D9E75), blue: const Color(0xFF2E5BFF), 
              onTap: _submit
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (name.text.isEmpty || price.text.isEmpty || (selectedImage == null && prefilledImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name, Price and Image are required")));
      return;
    }

    setState(() => isUploading = true);
    try {
      String? imageUrl = prefilledImageUrl;
      
      if (selectedImage != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadImage(selectedImage!, 'products');
      }
      
      if (imageUrl == null) throw "Image processing failed";

      // If picked from catalog, it's approved by default (standard item)
      // If custom added, it's pending Admin approval
      final String initialStatus = widget.prefillData != null ? 'approved' : 'pending';

      await FirebaseFirestore.instance.collection('products').add({
        'name': name.text,
        'title': name.text,
        'price': double.parse(price.text),
        'farmerUid': widget.uid,
        'farmName': widget.farmName,
        'farmerLat': widget.farmerLat,
        'farmerLng': widget.farmerLng,
        'unit': unit.text,
        'description': description.text,
        'longDescription': description.text,
        'category': widget.prefillData?['category'] ?? 'General',
        'image': imageUrl,
        'imageUrl': imageUrl,
        'status': initialStatus,
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
            indicatorSize: TabBarIndicatorSize.label,
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("No orders found", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

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
                    : _statusChip(status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;
    if (status == 'Delivered') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;
    if (status == 'Picked Up' || status == 'On the way' || status == 'Confirm Received') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconBadge(teal: color, blue: color.withValues(alpha: 0.7), icon: icon),
                  if (onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
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

  Future<void> _acceptOrder() async {
    final double? customerLat = (data['customerLat'] as num?)?.toDouble();
    final double? customerLng = (data['customerLng'] as num?)?.toDouble();
    
    double deliveryFee = 40.0;
    
    if (customerLat != null && customerLng != null && farmerLat != null && farmerLng != null) {
      final double distance = Geolocator.distanceBetween(
        farmerLat!, farmerLng!,
        customerLat, customerLng,
      ) / 1000;
      
      if (distance >= 1 && distance <= 3) {
        deliveryFee = 50.0;
      } else if (distance > 3) {
        deliveryFee = 15.0 * distance;
      }
    }

    final double subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double total = subtotal + deliveryFee;

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Farmer Accepted',
      'farmerUid': currentFarmerUid,
      'farmName': currentFarmName,
      'farmerLat': farmerLat,
      'farmerLng': farmerLng,
      'deliveryFee': deliveryFee,
      'total': total,
      'farmerRevenue': subtotal * 0.8,
      'adminRevenue': (subtotal * 0.2) + (deliveryFee * 0.2),
      'deliveryRevenue': deliveryFee * 0.8,
    });
  }

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
            onTap: _acceptOrder,
          ),
        ],
      ),
    );
  }
}
