// delivery_person_screen.dart
// FIXES APPLIED: Solved layout/rendering pixel crashes by adding explicit container constraints, and added complete Edit/Delete interactive action sheets.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../login_screen.dart';
import 'orders_screen.dart';

// THEME CONFIGURATION
const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF4F6F0);

class DeliveryPersonScreen extends StatefulWidget {
  const DeliveryPersonScreen({super.key});

  @override
  State<DeliveryPersonScreen> createState() => _DeliveryPersonScreenState();
}

class _DeliveryPersonScreenState extends State<DeliveryPersonScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final body = message.notification?.body ?? 'New Order Alert!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body), backgroundColor: _kGreen, behavior: SnackBarBehavior.floating),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    final pages = [
      _HomeMapTab(user: user),
      _ShipmentsTab(user: user),
      _NotificationsTab(user: user),
      _EarningsTab(user: user),
      _ProfileTab(user: user),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: _BottomNav(
        currentTab: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ====================== BOTTOM NAVIGATION BAR ======================
class _BottomNav extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(0, Icons.map, "Home"),
              _navItem(1, Icons.local_shipping, "Shipments"),
              _navItem(2, Icons.assignment, "Details"),
              _navItem(3, Icons.account_balance_wallet, "Payments"),
              _navItem(4, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final isSel = currentTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? _kGreen : Colors.grey.shade400, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? _kGreen : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ====================== TAB 1: HOME DRIVING MAP ======================
class _HomeMapTab extends StatefulWidget {
  final User user;
  const _HomeMapTab({required this.user});

  @override
  State<_HomeMapTab> createState() => _HomeMapTabState();
}

class _HomeMapTabState extends State<_HomeMapTab> {
  final MapController _mapController = MapController();
  static const LatLng _kDefaultCenter = LatLng(27.7172, 85.3240);

  LatLng? _driverPos;
  LatLng? _customPickupPoint;
  List<Marker> _customerMarkers = [];
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<QuerySnapshot>? _orderSub;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _listenToActiveOrders();
    _loadCustomPickupPoint();
  }

  Future<void> _loadCustomPickupPoint() async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (snap.exists && mounted) {
      final data = snap.data();
      if (data != null && data['pickupLat'] != null && data['pickupLng'] != null) {
        setState(() {
          _customPickupPoint = LatLng(data['pickupLat'], data['pickupLng']);
        });
      }
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _updateDriverPosition(pos);
    } catch (_) {}

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 8),
    ).listen(_updateDriverPosition);
  }

  void _updateDriverPosition(Position pos) {
    if (!mounted) return;
    final latlng = LatLng(pos.latitude, pos.longitude);
    setState(() => _driverPos = latlng);

    FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'lat': pos.latitude, 'lng': pos.longitude}).catchError((_) {});
  }

  void _listenToActiveOrders() {
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final markers = <Marker>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final lat = (data['customerLat'] as num?)?.toDouble();
        final lng = (data['customerLng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 45,
              height: 45,
              child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 38),
            ),
          );
        }
      }
      setState(() => _customerMarkers = markers);
    });
  }

  void _handleMapLongPress(dynamic tapPosition, LatLng point) async {
    setState(() {
      _customPickupPoint = point;
    });
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'pickupLat': point.latitude,
      'pickupLng': point.longitude,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New product pickup location saved on map!")),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverPos ?? _kDefaultCenter,
              initialZoom: 14.5,
              onLongPress: _handleMapLongPress,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.farmtech_agridirect'),
              MarkerLayer(markers: _customerMarkers),
              if (_driverPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverPos!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      ),
                    ),
                  ],
                ),
              if (_customPickupPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _customPickupPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.store, color: Colors.orange, size: 36),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Row(
                children: const [
                  Icon(Icons.navigation, color: _kGreen),
                  SizedBox(width: 10),
                  Expanded(child: Text("Tip: Long-press anywhere on map to add product pickup point.", style: TextStyle(fontSize: 12, color: Colors.black87))),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kGreen,
        mini: true,
        onPressed: () {
          if (_driverPos != null) _mapController.move(_driverPos!, 14.5);
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

// ====================== TAB 2: SHIPMENTS & HISTORIC RECORDS ======================
class _ShipmentsTab extends StatefulWidget {
  final User user;
  const _ShipmentsTab({required this.user});

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab> with SingleTickerProviderStateMixin {
  late TabController _shipmentController;

  @override
  void initState() {
    super.initState();
    _shipmentController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text("Shipments Ledger", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _shipmentController,
          labelColor: _kGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kGreen,
          tabs: const [Tab(text: "Active Delivery Requests"), Tab(text: "Past Finished History")],
        ),
      ),
      body: TabBarView(
        controller: _shipmentController,
        children: [
          _buildLiveStream(context),
          _buildHistoryStream(context),
        ],
      ),
    );
  }

  Widget _buildLiveStream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['Processing', 'Shipped', 'Picked Up', 'On the way'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _kGreen));
        final docs = snapshot.data!.docs;
        final myOrders = docs.where((d) => (d.data() as Map<String, dynamic>)['deliveryId'] == widget.user.uid).toList();
        final available = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['deliveryId'] == null || data['deliveryId'] == '';
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myOrders.isNotEmpty) ...[
              _headerSection("Assigned to Me", myOrders.length),
              ...myOrders.map((doc) => _OrderCard(doc: doc, user: widget.user)),
            ],
            if (available.isNotEmpty) ...[
              _headerSection("Available Hub Open Orders", available.length),
              ...available.map((doc) => _OrderCard(doc: doc, user: widget.user)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHistoryStream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryId', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _kGreen));
        final historyDocs = snapshot.data!.docs;

        if (historyDocs.isEmpty) {
          return const Center(child: Text("No completed orders yet.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyDocs.length,
          itemBuilder: (context, idx) {
            final data = historyDocs[idx].data() as Map<String, dynamic>;
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: _kGreen),
                title: Text("Order #${historyDocs[idx].id.substring(0, min(6, historyDocs[idx].id.length))} Delivered"),
                subtitle: Text(data['deliveryAddress'] ?? data['address'] ?? 'No Address Data'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerSection(String text, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text("$text ($count)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }
}

// ====================== TAB 3: CUSTOMER & PRODUCT DETAILS ======================
class _NotificationsTab extends StatelessWidget {
  final User user;
  const _NotificationsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("Customer & Product Details", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('deliveryId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text("No current order details assigned.", style: TextStyle(color: Colors.grey))));
          }

          final alerts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, idx) {
              final data = alerts[idx].data() as Map<String, dynamic>;
              final name = data['customerName'] ?? data['userName'] ?? 'Customer';
              final phone = data['customerPhone'] ?? data['userPhone'] ?? 'No Number';
              final itemsSummary = data['itemsSummary'] ?? 'Standard Package Item';

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order ID: #${alerts[idx].id.substring(0, min(5, alerts[idx].id.length))}", style: const TextStyle(fontWeight: FontWeight.bold, color: _kGreen)),
                          Text("${data['status']}", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))
                        ],
                      ),
                      const Divider(height: 16),
                      Row(children: [const Icon(Icons.person, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Customer Name: $name")]),
                      const SizedBox(height: 6),
                      Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Phone Number: $phone")]),
                      const SizedBox(height: 6),
                      Row(children: [const Icon(Icons.shopping_bag, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text("Product details: $itemsSummary", maxLines: 2, overflow: TextOverflow.ellipsis))]),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)),
                        child: Text("Drop Location: ${data['deliveryAddress'] ?? data['address'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      )
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
}

// ====================== TAB 4: WALLET & QR MANAGEMENT ======================
class _EarningsTab extends StatefulWidget {
  final User user;
  const _EarningsTab({required this.user});

  @override
  State<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<_EarningsTab> {
  String? _qrCodeImgPath;

  @override
  void initState() {
    super.initState();
    _loadSavedQR();
  }

  Future<void> _loadSavedQR() async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (snap.exists && mounted) {
      setState(() {
        _qrCodeImgPath = snap.data()?['paymentQrCode'];
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: _kGreen),
              title: const Text("Upload / Change QR Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickQrCodeImage();
              },
            ),
            if (_qrCodeImgPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Delete Current QR Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQrCodeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickQrCodeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _qrCodeImgPath = pickedFile.path;
      });
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'paymentQrCode': pickedFile.path,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment QR Code updated successfully!")));
      }
    }
  }

  Future<void> _deleteQrCodeImage() async {
    setState(() {
      _qrCodeImgPath = null;
    });
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'paymentQrCode': FieldValue.delete(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment QR Code removed.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kGreen, Colors.teal]),
                borderRadius: BorderRadius.circular(16)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("MY WALLET BALANCE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text("Rs. 18,450.00", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Accepted Payment Modes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _paymentModeRow("Cash On Delivery (COD)", Icons.payments, Colors.amber.shade900),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImageOptions,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.blue.shade800),
                      const SizedBox(width: 12),
                      const Text("Tap here to update/manage QR Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (_qrCodeImgPath != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb || _qrCodeImgPath!.startsWith('http')
                            ? Image.network(_qrCodeImgPath!, fit: BoxFit.contain)
                            : Image.file(File(_qrCodeImgPath!), fit: BoxFit.contain),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Recent Shipments Income", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          _paymentHistoryRow("Delivery complete #1980", "Rs. 600.00"),
          _paymentHistoryRow("Delivery complete #4410", "Rs. 1,450.00"),
        ],
      ),
    );
  }

  Widget _paymentModeRow(String title, IconData ico, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(ico, color: col, size: 24),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _paymentHistoryRow(String title, String amt) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Text(amt, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ====================== TAB 5: EDITABLE PROFILE HUB ======================
class _ProfileTab extends StatefulWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSaving = false;

  String? _profileImgPath;
  String? _licenseImgPath;

  @override
  void initState() {
    super.initState();
    _loadProfileMetadata();
  }

  Future<void> _loadProfileMetadata() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _vehicleController.text = data['vehicleDetails'] ?? 'Motorbike';
          _profileImgPath = data['profileImageUrl'];
          _licenseImgPath = data['licenseImageUrl'];
        });
      }
    }
  }

  void _showImageOptions({required bool isProfile}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: _kGreen),
              title: Text("Choose New ${isProfile ? 'Profile Picture' : 'License Image'}"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile);
              },
            ),
            if (isProfile ? _profileImgPath != null : _licenseImgPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text("Delete Current ${isProfile ? 'Profile Picture' : 'License Image'}"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage(isProfile);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isProfile) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImgPath = pickedFile.path;
        } else {
          _licenseImgPath = pickedFile.path;
        }
      });
    }
  }

  void _deleteImage(bool isProfile) {
    setState(() {
      if (isProfile) {
        _profileImgPath = null;
      } else {
        _licenseImgPath = null;
      }
    });
  }

  Future<void> _persistProfile() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'vehicleDetails': _vehicleController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp()
    };

    if (_profileImgPath == null) updates['profileImageUrl'] = FieldValue.delete();
    else updates['profileImageUrl'] = _profileImgPath;

    if (_licenseImgPath == null) updates['licenseImageUrl'] = FieldValue.delete();
    else updates['licenseImageUrl'] = _licenseImgPath;

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(
        updates,
        SetOptions(merge: true)
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile changes saved!")));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showImageOptions(isProfile: true),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: _kGreen.withOpacity(0.1),
                    backgroundImage: _profileImgPath != null
                        ? (kIsWeb || _profileImgPath!.startsWith('http')
                        ? NetworkImage(_profileImgPath!)
                        : FileImage(File(_profileImgPath!)) as ImageProvider)
                        : null,
                    child: _profileImgPath == null ? const Icon(Icons.person, size: 44, color: _kGreen) : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageOptions(isProfile: true),
                    child: const CircleAvatar(radius: 14, backgroundColor: _kGreen, child: Icon(Icons.edit, size: 12, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Rider Profile Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _buildField("Full Name", _nameController, Icons.badge),
          _buildField("Phone Number", _phoneController, Icons.phone),
          _buildField("Vehicle Spec / Plate No.", _vehicleController, Icons.motorcycle),
          const SizedBox(height: 16),
          const Text("License Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showImageOptions(isProfile: false),
            child: CustomPaint(
              painter: _DashedBorderPainter(color: Colors.grey.shade400, radius: 12),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)),
                child: _licenseImgPath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: kIsWeb || _licenseImgPath!.startsWith('http')
                        ? Image.network(_licenseImgPath!, fit: BoxFit.cover)
                        : Image.file(File(_licenseImgPath!), fit: BoxFit.cover),
                  ),
                )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.assignment, color: Colors.grey), SizedBox(height: 4), Text("Tap here to manage License Image", style: TextStyle(fontSize: 12, color: Colors.grey))]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _isSaving ? null : _persistProfile,
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), side: const BorderSide(color: Colors.redAccent)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData ico) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(prefixIcon: Icon(ico, size: 18, color: _kGreen), labelText: label, labelStyle: const TextStyle(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}

// ====================== UNIVERSAL REUSABLE ORDER COMPONENT ======================
class _OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final User user;
  const _OrderCard({required this.doc, required this.user});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Processing';
    final shortId = doc.id.substring(0, min(6, doc.id.length));
    final total = data['totalPrice'] ?? data['total'] ?? 0;
    final address = data['deliveryAddress'] ?? data['address'] ?? 'No Address Data';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #$shortId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(address, style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("Price: Rs. $total", style: const TextStyle(fontWeight: FontWeight.bold, color: _kGreen, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, side: const BorderSide(color: _kGreen)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(orderId: doc.id))),
                    child: const Text("View Route", style: TextStyle(color: _kGreen, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _kGreen, visualDensity: VisualDensity.compact),
                    onPressed: () => _advance(context, doc.id, status, data, user.uid),
                    child: Text(_nextLabel(status), style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _nextLabel(String status) {
    if (status == 'Processing' || status == 'Shipped') return "Accept Request";
    if (status == 'Picked Up') return "Start Delivery Route";
    return "Mark Delivered";
  }

  Future<void> _advance(BuildContext context, String orderId, String status, Map<String, dynamic> data, String riderUid) async {
    String next = 'Delivered';
    if (status == 'Processing' || status == 'Shipped') next = 'Picked Up';
    else if (status == 'Picked Up') next = 'On the way';

    final shortId = orderId.substring(0, min(6, orderId.length));

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': next,
      'deliveryId': riderUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final customerId = data['userId'];
    if (customerId != null) {
      String title = 'Order Status Updated';
      String body = 'Your order #$shortId status is now $next';

      if (next == 'Picked Up') {
        title = '📦 Order Picked Up';
        body = 'Rider has picked up your package #$shortId.';
      } else if (next == 'On the way') {
        title = '🚴 On The Way';
        body = 'Rider is coming to your location with package #$shortId.';
      } else if (next == 'Delivered') {
        title = '✅ Delivered';
        body = 'Package #$shortId has been dropped off. Thank you!';
      }

      await FirebaseFirestore.instance.collection('users').doc(customerId).collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'delivery_status',
        'status': next,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status changed to: $next")));
    }
  }
}

// ====================== UTILITY CUSTOM CANVAS DASHED PAINTER ======================
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Use smooth manual segment calculations compatible with cross-platform linter rules
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}