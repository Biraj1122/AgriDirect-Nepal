import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'orders_screen.dart';
import '../../login_screen.dart';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
class DeliveryPersonScreen extends StatefulWidget {
  const DeliveryPersonScreen({super.key});

  @override
  State<DeliveryPersonScreen> createState() => _DeliveryPersonScreenState();
}

class _DeliveryPersonScreenState extends State<DeliveryPersonScreen> {
  int _tab = 0;

  static const _kGreen = Color(0xFF2E7D32);
  static const _kBg = Color(0xFFF4F6F0);

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.notification?.body ?? 'New update'), backgroundColor: _kGreen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    final pages = [
      _OrdersTab(user: user),
      _EarningsTab(user: user),
      _ProfileTab(user: user),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(icon: Icons.local_shipping_outlined, label: "Orders", active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _NavItem(icon: Icons.account_balance_wallet_outlined, label: "Earnings", active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                _NavItem(icon: Icons.person_outline, label: "Profile", active: _tab == 2, onTap: () => setState(() => _tab = 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NAV ITEM
// ─────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? green : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? green : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ORDERS TAB
// ─────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final User user;
  const _OrdersTab({required this.user});

  static const _kGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Delivery Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('deliveryId', isEqualTo: user.uid)
                  .where('status', whereIn: ['Picked Up', 'On the way'])
                  .snapshots(),
              builder: (ctx, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Text("$count active route${count == 1 ? '' : 's'}", style: const TextStyle(color: Colors.grey, fontSize: 12));
              },
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', whereIn: ['Processing', 'Shipped', 'Picked Up', 'On the way'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }

          final docs = snapshot.data?.docs ?? [];
          final visible = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final assigned = data['deliveryId'];
            return assigned == null || assigned == user.uid;
          }).toList();

          if (visible.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.local_shipping_outlined, size: 40, color: _kGreen),
                ),
                const SizedBox(height: 16),
                const Text("No deliveries right now", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text("New orders will appear here", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            );
          }

          final myOrders = visible.where((d) => (d.data() as Map)['deliveryId'] == user.uid).toList();
          final available = visible.where((d) => (d.data() as Map)['deliveryId'] == null).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              Container(
                height: 240,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _DeliveryMap(user: user)),
              ),
              if (myOrders.isNotEmpty) ...[
                _sectionHeader("My Active Orders", myOrders.length),
                ...myOrders.map((doc) => _OrderCard(doc: doc, user: user)),
                const SizedBox(height: 8),
              ],
              if (available.isNotEmpty) ...[
                _sectionHeader("Available Orders", available.length),
                ...available.map((doc) => _OrderCard(doc: doc, user: user)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
          child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// MAP
// ─────────────────────────────────────────────
class _DeliveryMap extends StatefulWidget {
  final User user;
  const _DeliveryMap({required this.user});

  @override
  State<_DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<_DeliveryMap> {
  final MapController _mapController = MapController();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .get();

    setState(() {
      _markers.clear();
      for (var doc in snap.docs) {
        final data = doc.data();
        final lat = data['customerLat'] as double?;
        final lng = data['customerLng'] as double?;
        if (lat != null && lng != null) {
          _markers.add(Marker(
            point: LatLng(lat, lng),
            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(initialCenter: LatLng(27.7172, 85.3240), initialZoom: 12),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.farmtech_agridirect'),
        MarkerLayer(markers: _markers.toList()),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final User user;
  const _OrderCard({required this.doc, required this.user});

  static const _kGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Processing';
    final shortId = doc.id.substring(0, min(6, doc.id.length));
    final isAssigned = data['deliveryId'] == user.uid;
    final total = data['totalPrice'] ?? data['total'] ?? 0;
    final name = data['customerName'] ?? data['userName'] ?? '-';
    final address = data['deliveryAddress'] ?? data['address'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: isAssigned ? Border.all(color: _kGreen.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAssigned ? _kGreen.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text("Order #$shortId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (isAssigned) ...[
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
                  ]
                ]),
                _StatusBadge(status: status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.person_outline, label: name),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.location_on_outlined, label: address.length > 40 ? '${address.substring(0,40)}…' : address),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.currency_rupee, label: "Rs. ${total is double ? total.toStringAsFixed(2) : total}", bold: true, color: _kGreen),

                if (isAssigned) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Your Photo (for customer)", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.camera_alt, color: _kGreen), onPressed: () => _captureAndUploadPhoto(context, user.uid)),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text("Navigate"),
                      style: OutlinedButton.styleFrom(foregroundColor: _kGreen, side: const BorderSide(color: _kGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(orderId: doc.id))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => _advance(context, doc.id, status, data, user.uid),
                      child: Text(_nextLabel(status), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndUploadPhoto(BuildContext context, String riderUid) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child('delivery_photos/${riderUid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      final photoUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(riderUid).update({'photoUrl': photoUrl});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo uploaded!")));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  String _nextLabel(String status) {
    switch (status) {
      case 'Processing':
      case 'Shipped':
        return "Accept Order";
      case 'Picked Up':
        return "Start Delivery";
      case 'On the way':
        return "Mark Delivered";
      default:
        return "Update";
    }
  }

  String _next(String status) {
    switch (status) {
      case 'Processing':
      case 'Shipped':
        return "Picked Up";
      case 'Picked Up':
        return "On the way";
      case 'On the way':
        return "Delivered";
      default:
        return status;
    }
  }

  Future<void> _advance(BuildContext context, String orderId, String status, Map<String, dynamic> data, String riderUid) async {
    final next = _next(status);

    String? paymentMethod;
    if (next == 'Delivered') {
      paymentMethod = await _showPaymentMethodDialog(context);
      if (paymentMethod == null) return;
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': next,
      'deliveryId': riderUid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (next == 'Delivered') ...{
        'deliveredAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
      },
    });

    final shortId = orderId.substring(0, min(6, orderId.length));

    final customerId = data['userId'];
    if (customerId != null) {
      await FirebaseFirestore.instance.collection('users').doc(customerId).collection('notifications').add({
        'title': 'Delivery Update: $next',
        'body': 'Your order #$shortId is now "$next".',
        'type': 'delivery',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (next == 'Delivered') {
      final total = data['totalPrice'] ?? data['total'] ?? 0;
      final earning = (total is double ? total : (total as num).toDouble()) * 0.1;
      await FirebaseFirestore.instance.collection('users').doc(riderUid).collection('earnings').add({
        'orderId': orderId,
        'shortId': shortId,
        'amount': earning,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order updated to $next"), backgroundColor: _kGreen));
    }
  }

  Future<String?> _showPaymentMethodDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Payment Method"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.money), title: const Text("Cash"), onTap: () => Navigator.pop(ctx, "Cash")),
            ListTile(leading: const Icon(Icons.qr_code), title: const Text("QR Code"), onTap: () => Navigator.pop(ctx, "QR")),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EARNINGS TAB
// ─────────────────────────────────────────────
class _EarningsTab extends StatelessWidget {
  final User user;
  const _EarningsTab({required this.user});

  static const _kGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Earnings & Payments", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('earnings').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }
          final docs = snapshot.data?.docs ?? [];
          final totalEarned = docs.fold<double>(0, (sum, d) => sum + ((d.data() as Map)['amount'] as num? ?? 0).toDouble());
          final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').fold<double>(0, (sum, d) => sum + ((d.data() as Map)['amount'] as num? ?? 0).toDouble());
          final paid = totalEarned - pending;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Row(children: [
                Expanded(child: _SummaryCard(label: "Total Earned", amount: totalEarned, icon: Icons.bar_chart, color: _kGreen)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(label: "Paid Out", amount: paid, icon: Icons.check_circle_outline, color: Colors.blue.shade700)),
              ]),
              const SizedBox(height: 12),
              _SummaryCard(label: "Pending Payout", amount: pending, icon: Icons.hourglass_empty, color: Colors.orange.shade700, fullWidth: true),
              const SizedBox(height: 20),

              if (pending > 0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_outlined, color: Colors.white),
                  label: const Text("Request Payout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _kGreen, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => _requestPayout(context, user.uid, pending),
                ),

              const SizedBox(height: 20),
              const Text("Transaction History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 10),

              if (docs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No transactions yet", style: TextStyle(color: Colors.grey))))
              else
                ...docs.map((d) => _buildTransactionItem(d)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _requestPayout(BuildContext context, String uid, double amount) async {
    await FirebaseFirestore.instance.collection('payoutRequests').add({
      'deliveryId': uid,
      'amount': amount,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('earnings').where('status', isEqualTo: 'pending').get();
    for (var d in snap.docs) {
      batch.update(d.reference, {'status': 'requested'});
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payout request sent to admin")));
    }
  }

  Widget _buildTransactionItem(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num? ?? 0).toDouble();
    final st = data['status'] ?? 'pending';
    final shortId = data['shortId'] ?? '-';
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}" : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: st == 'paid' ? Colors.blue.shade50 : Colors.orange.shade50, shape: BoxShape.circle),
          child: Icon(st == 'paid' ? Icons.check : Icons.hourglass_empty, size: 18, color: st == 'paid' ? Colors.blue.shade700 : Colors.orange.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Order #$shortId", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("Rs. ${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: st == 'paid' ? Colors.blue.shade700 : Colors.orange.shade700)),
          Text(st[0].toUpperCase() + st.substring(1), style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE TAB (with Camera)
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final User user;
  const _ProfileTab({required this.user});

  static const _kGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? data['displayName'] ?? user.displayName ?? 'Rider';
          final phone = data['phone'] ?? '-';
          final vehicle = data['vehicleNumber'] ?? '-';
          final zone = data['zone'] ?? '-';
          final isAvailable = data['isAvailable'] ?? true;
          final photoUrl = data['photoUrl'] as String?;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Center(
                child: Column(children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: _kGreen.withOpacity(0.12),
                        child: photoUrl == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'R', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _kGreen))
                            : null,
                      ),
                      IconButton(
                        icon: const CircleAvatar(backgroundColor: _kGreen, radius: 18, child: Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                        onPressed: () => _captureAndUploadPhoto(context, user.uid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                  Text(user.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.circle, color: _kGreen, size: 12),
                  const SizedBox(width: 10),
                  const Expanded(child: Text("Available for Deliveries", style: TextStyle(fontWeight: FontWeight.w600))),
                  Switch(value: isAvailable, activeColor: _kGreen, onChanged: (val) {
                    FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isAvailable': val});
                  }),
                ]),
              ),
              const SizedBox(height: 16),

              _ProfileSection(title: "Personal Info", items: [
                _ProfileItem(icon: Icons.person_outline, label: "Full Name", value: name),
                _ProfileItem(icon: Icons.phone_outlined, label: "Phone", value: phone),
                _ProfileItem(icon: Icons.email_outlined, label: "Email", value: user.email ?? '-'),
              ]),
              const SizedBox(height: 12),
              _ProfileSection(title: "Vehicle & Zone", items: [
                _ProfileItem(icon: Icons.two_wheeler_outlined, label: "Vehicle No.", value: vehicle),
                _ProfileItem(icon: Icons.location_on_outlined, label: "Zone", value: zone),
              ]),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, color: _kGreen),
                label: const Text("Edit Profile", style: TextStyle(color: _kGreen)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: _kGreen), minimumSize: const Size.fromHeight(50)),
                onPressed: () => _showEditSheet(context, user.uid, data),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _captureAndUploadPhoto(BuildContext context, String riderUid) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child('delivery_photos/${riderUid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      final photoUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(riderUid).update({'photoUrl': photoUrl});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  void _showEditSheet(BuildContext context, String uid, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final vehicleCtrl = TextEditingController(text: data['vehicleNumber'] ?? '');
    final zoneCtrl = TextEditingController(text: data['zone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 16),
          _field("Full Name", nameCtrl, Icons.person_outline),
          _field("Phone", phoneCtrl, Icons.phone_outlined),
          _field("Vehicle Number", vehicleCtrl, Icons.two_wheeler_outlined),
          _field("Zone", zoneCtrl, Icons.location_on_outlined),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, minimumSize: const Size.fromHeight(50)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'vehicleNumber': vehicleCtrl.text.trim(),
                'zone': zoneCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _kGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreen)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade100, fg = Colors.grey.shade700;
    if (status == 'On the way') { bg = Colors.blue.shade50; fg = Colors.blue.shade700; }
    else if (status == 'Picked Up') { bg = Colors.orange.shade50; fg = Colors.orange.shade800; }
    else if (status == 'Delivered') { bg = Colors.green.shade50; fg = Colors.green.shade800; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool bold;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: color ?? Colors.grey.shade600),
      const SizedBox(width: 6),
      Expanded(
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87), overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Icon(e.value.icon, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value.label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  Text(e.value.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
              if (!isLast) Divider(height: 1, indent: 48, color: Colors.grey.shade100),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({required this.icon, required this.label, required this.value});
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _SummaryCard({required this.label, required this.amount, required this.icon, required this.color, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text("Rs. ${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fullWidth ? 20 : 16, color: color)),
          ]),
        ],
      ),
    );
  }
}