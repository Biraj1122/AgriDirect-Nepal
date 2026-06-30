import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../Success/shared_widgets.dart';
import 'auth/login_screen.dart';

const Color primaryTeal = Color(0xFF1D9E75);
const Color secondaryBlue = Color(0xFF2E5BFF);
const Color backgroundColor = Color(0xFFF8FAFC);

class DeliveryPersonScreen extends StatefulWidget {
  const DeliveryPersonScreen({super.key});

  @override
  State<DeliveryPersonScreen> createState() => _DeliveryPersonScreenState();
}

class _DeliveryPersonScreenState extends State<DeliveryPersonScreen> {
  int _tab = 0;
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _setupFCM();
    _startGlobalLocationTracking();
  }

  Future<void> _startGlobalLocationTracking() async {
    bool granted = await _locationService.requestPermission();
    if (!granted) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logout();
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'];

    if (role != 'Delivery Person') {
      _logout();
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

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final body = message.notification?.body ?? 'New Order Alert!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body), 
          backgroundColor: primaryTeal, 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryTeal)));
    }

    final pages = [
      _HomeMapTab(user: user),
      _ShipmentsTab(user: user),
      _EarningsTab(user: user),
      _ProfileTab(user: user, logoutCallback: _logout),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[_tab],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryTeal,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Map"),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: "Shipments"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Wallet"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class _HomeMapTab extends StatefulWidget {
  final User user;
  const _HomeMapTab({required this.user});

  @override
  State<_HomeMapTab> createState() => _HomeMapTabState();
}

class _HomeMapTabState extends State<_HomeMapTab> {
  final LocationService _locationService = LocationService();
  static const LatLng _kDefaultCenter = LatLng(27.7172, 85.3240);

  LatLng? _driverPos;
  StreamSubscription<Position>? _localPosSub;
  MapLibreMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initDriverLocation();
  }

  @override
  void dispose() {
    _localPosSub?.cancel();
    super.dispose();
  }

  Future<void> _initDriverLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _driverPos = LatLng(pos.latitude, pos.longitude));
    }
    
    _localPosSub = Geolocator.getPositionStream().listen((p) {
      if (mounted) setState(() => _driverPos = LatLng(p.latitude, p.longitude));
    });
  }

  void _centerOnDriver() {
    if (_driverPos != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_driverPos!, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          initialCameraPosition: CameraPosition(target: _driverPos ?? _kDefaultCenter, zoom: 14),
          myLocationEnabled: true,
          styleString: "https://tiles.openfreemap.org/styles/positron",
          onMapCreated: (controller) => _mapController = controller,
        ),
        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton(
            onPressed: _centerOnDriver,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.my_location_rounded, color: primaryTeal),
          ),
        ),
        Positioned(
          top: 20, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
            child: Row(
              children: [
                const IconBadge(teal: primaryTeal, blue: secondaryBlue, icon: Icons.delivery_dining_rounded),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Status: Online", style: TextStyle(fontWeight: FontWeight.w800, color: primaryTeal)),
                      Text("Awaiting new orders near you", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShipmentsTab extends StatelessWidget {
  final User user;
  const _ShipmentsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Heading(title: "Shipments", subtitle: "Manage your delivery workload"),
          ),
          TabBar(
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryTeal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrderList(context, ['Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'], true),
                _buildOrderList(context, ['Delivered', 'Cancelled'], false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<String> statuses, bool isActionable) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map;
          return data['deliveryId'] == null || data['deliveryId'] == user.uid;
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActionable ? Icons.local_shipping_outlined : Icons.history_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(isActionable ? "No active shipments" : "No delivery history", style: const TextStyle(color: Colors.grey)),
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isMyOrder = data['deliveryId'] == user.uid;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order #${docs[i].id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      _statusChip(data['status'] ?? 'Pending'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoItem(Icons.storefront_rounded, data['farmName'] ?? 'Pickup location'),
                  _infoItem(Icons.location_on_rounded, data['deliveryAddress'] ?? 'Delivery address'),
                  if (isActionable) ...[
                    const SizedBox(height: 20),
                    if (!isMyOrder)
                      GradientButton(
                        label: "Accept Shipment", 
                        icon: Icons.check_rounded, 
                        isLoading: false, 
                        teal: primaryTeal, blue: secondaryBlue, 
                        onTap: () => _acceptOrder(context, docs[i].id, user.uid)
                      )
                    else
                      GradientButton(
                        label: _getNextStatusLabel(data['status']), 
                        icon: Icons.arrow_forward_rounded, 
                        isLoading: false, 
                        teal: primaryTeal, blue: secondaryBlue, 
                        onTap: () => _updateStatus(context, docs[i].id, data['status'])
                      ),
                  ] else ...[
                     const SizedBox(height: 12),
                     Text("Completed: ${data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate().toString().substring(0, 16) : 'N/A'}", 
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: const TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _getNextStatusLabel(String? current) {
    switch (current) {
      case 'Awaiting Pickup': return 'Mark as Picked Up';
      case 'Picked Up': return 'Start Delivery';
      case 'On the way': return 'I have Arrived';
      case 'Arrived': return 'Mark as Delivered';
      default: return 'Update Progress';
    }
  }

  Future<void> _acceptOrder(BuildContext context, String orderId, String uid) async {
    final riderDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final riderName = riderDoc.data()?['fullName'] ?? 'Rider';
    final riderPhone = riderDoc.data()?['phone'] ?? '';

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'deliveryId': uid,
      'deliveryName': riderName,
      'deliveryPhone': riderPhone,
      'status': 'Awaiting Pickup',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String? current) async {
    String next = 'Delivered';
    if (current == 'Awaiting Pickup') {
      next = 'Picked Up';
    } else if (current == 'Picked Up') {
      next = 'On the way';
    } else if (current == 'On the way') {
      next = 'Arrived';
    } else if (current == 'Arrived') {
      next = 'Confirm Received'; // Delivery person marks as delivered, now customer needs to confirm
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _TasksTab extends StatefulWidget {
  final User user;
  const _TasksTab({required this.user});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  bool _isOnline = true;
  bool _isLoading = false;
  Map<String, dynamic>? _riderData;

  @override
  void initState() {
    super.initState();
    _fetchDutyStatus();
  }

  Future<void> _fetchDutyStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
      if (mounted) {
        setState(() {
          _riderData = doc.data();
          _isOnline = _riderData?['isOnline'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching duty status: $e");
    }
  }

  Future<void> _toggleDuty() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'isOnline': !_isOnline,
        'lastDutyToggle': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _isOnline = !_isOnline;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline ? "You are now ONLINE" : "You are now OFFLINE"),
            backgroundColor: _isOnline ? primaryTeal : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stability Check: Ensure we don't return a blank screen if data is loading
    // but also don't hang indefinitely. A ListView with placeholders is safer.
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Duty & Stats", subtitle: "Manage your availability and performance"),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // Duty Toggle Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isOnline ? primaryTeal : Colors.grey).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isOnline ? Icons.bolt_rounded : Icons.power_settings_new_rounded, 
                                 color: _isOnline ? primaryTeal : Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isOnline ? "On Duty" : "Off Duty", 
                               style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Text(_isOnline ? "Receiving new orders" : "Resting mode", 
                               style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2))
                    else
                      Switch.adaptive(
                        value: _isOnline, 
                        onChanged: (_) => _toggleDuty(),
                        activeTrackColor: primaryTeal,
                        activeThumbColor: Colors.white,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel(label: "DAILY PERFORMANCE"),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('deliveryId', isEqualTo: widget.user.uid)
                    .where('status', isEqualTo: 'Delivered')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final todayDocs = docs.where((d) {
                    final data = d.data() as Map;
                    if (data['updatedAt'] == null) return false;
                    final date = (data['updatedAt'] as Timestamp).toDate();
                    final now = DateTime.now();
                    return date.year == now.year && date.month == now.month && date.day == now.day;
                  }).toList();

                  double earnings = 0;
                  for (var d in todayDocs) {
                    earnings += (d.data() as Map)['deliveryRevenue'] ?? 100.0;
                  }

                  return Row(
                    children: [
                      _statCard("Deliveries", "${todayDocs.length}", Icons.check_circle_rounded, Colors.blue),
                      const SizedBox(width: 16),
                      _statCard("Earnings", "Rs. ${earnings.toStringAsFixed(0)}", Icons.account_balance_wallet_rounded, Colors.green),
                    ],
                  );
                }
              ),
              const SizedBox(height: 32),
              const FieldLabel(label: "SYSTEM ALERTS"),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.uid)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2)));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text("No recent alerts", style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: IconBadge(teal: primaryTeal, blue: secondaryBlue, icon: Icons.notifications_rounded),
                          title: Text(data['title'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(data['body'] ?? '', style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  );
                }
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  final String uid;
  final Map<String, dynamic>? currentData;
  const _VerificationSheet({required this.uid, this.currentData});

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  XFile? licenseFront, licenseBack, citizenshipFront, citizenshipBack;
  bool isUploading = false;
  int step = 1;

  Future<void> _pickImage(String type) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() {
        if (type == 'lf') licenseFront = img;
        if (type == 'lb') licenseBack = img;
        if (type == 'cf') citizenshipFront = img;
        if (type == 'cb') citizenshipBack = img;
      });
    }
  }

  Future<void> _submit() async {
    if (licenseFront == null || licenseBack == null || citizenshipFront == null || citizenshipBack == null) return;
    
    setState(() => isUploading = true);
    try {
      final storage = StorageService();
      final lfUrl = await storage.uploadImage(licenseFront!, 'verification/${widget.uid}');
      final lbUrl = await storage.uploadImage(licenseBack!, 'verification/${widget.uid}');
      final cfUrl = await storage.uploadImage(citizenshipFront!, 'verification/${widget.uid}');
      final cbUrl = await storage.uploadImage(citizenshipBack!, 'verification/${widget.uid}');

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'licenseFront': lfUrl,
        'licenseBack': lbUrl,
        'citizenshipFront': cfUrl,
        'citizenshipBack': cbUrl,
        'verificationStatus': 'pending',
        'documentsUploadedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Heading(title: "Identity Verification", subtitle: step == 1 ? "Upload Driving License" : "Upload Citizenship Card"),
          const SizedBox(height: 32),
          if (step == 1) ...[
            _uploadBox("Front Side", licenseFront, () => _pickImage('lf')),
            const SizedBox(height: 16),
            _uploadBox("Back Side", licenseBack, () => _pickImage('lb')),
            const SizedBox(height: 32),
            GradientButton(label: "Next Step", icon: Icons.arrow_forward_rounded, isLoading: false, teal: primaryTeal, blue: secondaryBlue, onTap: () => setState(() => step = 2)),
          ] else ...[
            _uploadBox("Front Side", citizenshipFront, () => _pickImage('cf')),
            const SizedBox(height: 16),
            _uploadBox("Back Side", citizenshipBack, () => _pickImage('cb')),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => step = 1), child: const Text("Back"))),
                const SizedBox(width: 16),
                Expanded(child: GradientButton(label: "Submit Documents", icon: Icons.check_rounded, isLoading: isUploading, teal: primaryTeal, blue: secondaryBlue, onTap: _submit)),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _uploadBox(String label, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
        child: file != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(file.path), fit: BoxFit.cover))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_rounded, color: Colors.grey), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
      ),
    );
  }
}

class _EarningsTab extends StatelessWidget {
  final User user;
  const _EarningsTab({required this.user});

  void _showRevenueDetails(BuildContext context, List<QueryDocumentSnapshot> docs, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Heading(title: "Income Breakdown", subtitle: "Total earnings after 20% platform fee"),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final gross = (data['deliveryFee'] ?? 40).toDouble();
                  final net = gross * 0.8;
                  final fee = gross * 0.2;
                  
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
                            Text("Rs. ${gross.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 24),
                        _incomeRow("Gross Delivery Fee", gross),
                        _incomeRow("Platform Fee (20%)", -fee, isNegative: true),
                        const Divider(height: 24),
                        _incomeRow("Your Earnings", net, isBold: true, color: Colors.green),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('deliveryId', isEqualTo: user.uid).where('status', isEqualTo: 'Delivered').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double total = 0;
        for (var d in docs) {
          final data = d.data() as Map;
          // Calculate Net: 80% of delivery fee
          total += ((data['deliveryFee'] ?? 40).toDouble() * 0.8);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Heading(title: "My Earnings", subtitle: "Track your delivery revenue and payouts"),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _showRevenueDetails(context, docs, total),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryTeal, secondaryBlue]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Rs. ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const FieldLabel(label: "RECENT TRANSACTIONS"),
            const SizedBox(height: 12),
            ...docs.map((d) {
              final data = d.data() as Map;
              final net = (data['deliveryFee'] ?? 40).toDouble() * 0.8;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.1), child: const Icon(Icons.add_rounded, color: Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Delivery Reward", style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text("Order #${d.id.substring(0,6).toUpperCase()}", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )),
                    Text("+Rs. ${net.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final User user;
  final VoidCallback logoutCallback;
  const _ProfileTab({required this.user, required this.logoutCallback});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showEditNameDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Full Name"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isUpdating = true);
              try {
                await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
                  'fullName': _nameController.text.trim(),
                });
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name updated successfully")));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm New Password", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) return;
              if (_newPasswordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                return;
              }
              Navigator.pop(context);
              setState(() => _isUpdating = true);
              try {
                AuthCredential credential = EmailAuthProvider.credential(
                  email: widget.user.email!,
                  password: _currentPasswordController.text,
                );
                await widget.user.reauthenticateWithCredential(credential);
                await widget.user.updatePassword(_newPasswordController.text);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(Map<String, dynamic>? userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VerificationSheet(uid: widget.user.uid, currentData: userData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['fullName'] ?? 'Rider Name';
        
        final String verificationStatus = data?['verificationStatus'] ?? 'unverified';
        Color statusColor = Colors.grey;
        String statusLabel = "Un-verified";
        IconData statusIcon = Icons.error_outline_rounded;

        if (verificationStatus == 'verified') {
          statusColor = primaryTeal;
          statusLabel = "Verified Partner";
          statusIcon = Icons.verified_rounded;
        } else if (verificationStatus == 'pending') {
          statusColor = Colors.orange;
          statusLabel = "Verification Pending";
          statusIcon = Icons.hourglass_empty_rounded;
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Heading(title: "My Profile", subtitle: "Manage your rider account settings"),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: primaryTeal.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, size: 60, color: primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(widget.user.email ?? '', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_isUpdating) const Padding(padding: EdgeInsets.only(top: 8), child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const FieldLabel(label: "ACCOUNT SETTINGS"),
            const SizedBox(height: 12),
            _profileItem(Icons.badge_rounded, name, onTap: () => _showEditNameDialog(name)),
            _profileItem(Icons.lock_rounded, "Change Password", onTap: _showChangePasswordDialog),
            _profileItem(Icons.phone_rounded, data?['phone'] ?? 'Add phone number'),
            _profileItem(statusIcon, statusLabel, onTap: verificationStatus == 'verified' ? null : () => _showVerificationDialog(data)),
            const SizedBox(height: 40),
            GradientButton(
              label: "Logout Account", 
              icon: Icons.logout_rounded, 
              isLoading: false, 
              teal: Colors.redAccent, blue: Colors.red.shade900, 
              onTap: widget.logoutCallback
            ),
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
            Icon(icon, color: primaryTeal, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (onTap != null) Icon(Icons.edit_rounded, color: Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }
}
