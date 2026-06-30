import 'dart:async';
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
      _NotificationsTab(user: user),
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
            BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Tasks"),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          initialCameraPosition: CameraPosition(target: _driverPos ?? _kDefaultCenter, zoom: 14),
          myLocationEnabled: true,
          styleString: "https://tiles.openfreemap.org/styles/positron",
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Active Shipments", subtitle: "Manage your current delivery tasks"),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: ['Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'])
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
                    Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("No active shipments", style: TextStyle(color: Colors.grey)),
                  ],
                ));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'deliveryId': uid,
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
      next = 'Delivered';
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _NotificationsTab extends StatelessWidget {
  final User user;
  const _NotificationsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Heading(title: "Tasks & Alerts", subtitle: "Stay updated with system notifications"),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No notifications"));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: IconBadge(teal: primaryTeal, blue: secondaryBlue, icon: Icons.notifications_rounded),
                      title: Text(data['title'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(data['body'] ?? ''),
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
}

class _EarningsTab extends StatelessWidget {
  final User user;
  const _EarningsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('deliveryId', isEqualTo: user.uid).where('status', isEqualTo: 'Delivered').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double total = 0;
        for (var d in docs) {
          final data = d.data() as Map;
          total += (data['deliveryRevenue'] ?? 100).toDouble(); // Default flat rate if not specified
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Heading(title: "My Earnings", subtitle: "Track your delivery revenue and payouts"),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryTeal, secondaryBlue]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Rs. ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const FieldLabel(label: "RECENT TRANSACTIONS"),
            const SizedBox(height: 12),
            ...docs.map((d) {
              final data = d.data() as Map;
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
                    Text("+Rs. ${data['deliveryRevenue'] ?? 100}", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green)),
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

class _ProfileTab extends StatelessWidget {
  final User user;
  final VoidCallback logoutCallback;
  const _ProfileTab({required this.user, required this.logoutCallback});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        
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
                  Text(data?['fullName'] ?? 'Rider Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(user.email ?? '', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const FieldLabel(label: "ACCOUNT SETTINGS"),
            const SizedBox(height: 12),
            _profileItem(Icons.phone_rounded, data?['phone'] ?? 'Add phone number'),
            _profileItem(Icons.verified_user_rounded, "Verified Delivery Partner"),
            const SizedBox(height: 40),
            GradientButton(
              label: "Logout Account", 
              icon: Icons.logout_rounded, 
              isLoading: false, 
              teal: Colors.redAccent, blue: Colors.red.shade900, 
              onTap: logoutCallback
            ),
          ],
        );
      }
    );
  }

  Widget _profileItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
