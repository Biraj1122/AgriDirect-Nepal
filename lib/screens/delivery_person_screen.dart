import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../services/location_service.dart';
import 'auth/login_screen.dart';

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
    _checkRole();
    _setupFCM();
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

class _HomeMapTab extends StatefulWidget {
  final User user;
  const _HomeMapTab({required this.user});

  @override
  State<_HomeMapTab> createState() => _HomeMapTabState();
}

class _HomeMapTabState extends State<_HomeMapTab> with TickerProviderStateMixin {
  MapLibreMapController? _mapController;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _kDefaultCenter = LatLng(27.7172, 85.3240);

  LatLng? _driverPos;
  LatLng? _customPickupPoint;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<QuerySnapshot>? _orderSub;
  
  final List<Symbol> _customerSymbols = [];

  String _currentAddress = "Fetching location...";
  bool _isMoving = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  late AnimationController _pinController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeOut),
    );
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
    bool granted = await _locationService.requestPermission();
    if (!granted) return;

    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _updateDriverPosition(pos);
      _updateAddress(LatLng(pos.latitude, pos.longitude));
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

  Future<void> _updateAddress(LatLng position) async {
    String address = await _locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  void _listenToActiveOrders() {
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .snapshots()
        .listen((snap) {
      if (!mounted || _mapController == null) return;

      _updateMarkersOnMap(snap.docs);
    });
  }

  Future<void> _updateMarkersOnMap(List<QueryDocumentSnapshot> docs) async {
    if (_mapController == null) return;

    for (var s in _customerSymbols) {
      await _mapController!.removeSymbol(s);
    }
    _customerSymbols.clear();

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['customerLat'] as num?)?.toDouble();
      final lng = (data['customerLng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(lat, lng),
            iconImage: "marker-15",
            iconColor: "#FF5252",
            iconSize: 2.0,
          ),
        );
        _customerSymbols.add(symbol);
      }
    }

    if (_customPickupPoint != null) {
      final symbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: _customPickupPoint!,
          iconImage: "harbor-15",
          iconColor: "#FFA000",
          iconSize: 2.0,
          textField: "Pickup",
          textSize: 10,
          textOffset: const Offset(0, 1.5),
        ),
      );
      _customerSymbols.add(symbol);
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .get()
        .then((snap) => _updateMarkersOnMap(snap.docs));
  }

  void _onCameraIdle() {
    setState(() => _isMoving = false);
    _pinController.reverse();
    if (_mapController != null) {
      _updateAddress(_mapController!.cameraPosition!.target);
    }
  }

  void _handleSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _locationService.searchLocation(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    final address = result['display_name'] as String;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16, tilt: 45),
      ),
    );

    setState(() {
      _currentAddress = address;
      _searchResults = [];
      _searchController.text = "";
    });
    FocusScope.of(context).unfocus();
  }

  void _confirmPickupLocation() async {
    if (_mapController == null) return;
    final point = _mapController!.cameraPosition!.target;
    
    setState(() {
      _customPickupPoint = point;
    });

    FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .get()
        .then((snap) => _updateMarkersOnMap(snap.docs));

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'pickupLat': point.latitude,
      'pickupLng': point.longitude,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup location saved")),
      );
    }
  }

  void _handleMapLongPress(LatLng point) async {
    setState(() {
      _customPickupPoint = point;
    });

    FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: widget.user.uid)
        .where('status', whereIn: ['Picked Up', 'On the way'])
        .get()
        .then((snap) => _updateMarkersOnMap(snap.docs));

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'pickupLat': point.latitude,
      'pickupLng': point.longitude,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup location saved")),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _orderSub?.cancel();
    _searchController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _driverPos ?? _kDefaultCenter,
              zoom: 14.5,
              tilt: 45,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            onCameraMove: (pos) {
              if (!_isMoving) {
                setState(() => _isMoving = true);
                _pinController.forward();
              }
            },
            onCameraIdle: _onCameraIdle,
            onMapLongClick: (point, latlng) => _handleMapLongPress(latlng),
            styleString: "https://tiles.openfreemap.org/styles/positron",
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      decoration: InputDecoration(
                        hintText: "Search pickup/delivery point...",
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        suffixIcon: _isSearching 
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final res = _searchResults[i];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Colors.green),
                            title: Text(res['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            onTap: () => _selectSearchResult(res),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinAnimation.value - 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: const Text("Set Pickup", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.location_on, size: 40, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.location_on, color: Colors.green, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_isMoving ? "Updating map..." : _currentAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isMoving ? null : _confirmPickupLocation,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("SAVE PICKUP POINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 200,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: true,
              onPressed: () {
                if (_driverPos != null) _mapController?.animateCamera(CameraUpdate.newLatLng(_driverPos!));
              },
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

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
          .where('status', whereIn: ['Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _kGreen));
        final docs = snapshot.data!.docs;
        final myOrders = docs.where((d) => (d.data() as Map<String, dynamic>)['deliveryId'] == widget.user.uid).toList();
        final available = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          // Show orders that are ready for pickup and not yet taken by a rider
          return (data['deliveryId'] == null || data['deliveryId'] == '') && data['status'] == 'Awaiting Pickup';
        }).toList();

        if (myOrders.isEmpty && available.isEmpty) {
          return const Center(child: Text("No active requests found", style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myOrders.isNotEmpty) ...[
              _headerSection("Assigned to Me", myOrders.length),
              ...myOrders.map((doc) => _OrderCard(doc: doc, user: widget.user)),
            ],
            if (available.isNotEmpty) ...[
              _headerSection("Available Hub Orders", available.length),
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
          return const Center(child: Text("No completed orders", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyDocs.length,
          itemBuilder: (context, idx) {
            final data = historyDocs[idx].data() as Map<String, dynamic>;
            final paymentMethod = data['paymentMethod'] ?? 'COD';
            final isCOD = paymentMethod == 'COD';
            final shortId = historyDocs[idx].id.substring(0, min(6, historyDocs[idx].id.length));

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.check_circle, color: _kGreen, size: 32),
                title: Text("Order #$shortId Delivered", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(data['deliveryAddress'] ?? 'No Address', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCOD ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCOD ? "COD" : "ONLINE",
                            style: TextStyle(color: isCOD ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text("Rs. ${data['total'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, color: _kGreen)),
                onTap: () {
                  if (!isCOD) {
                    _showReceipt(context, shortId, data);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showReceipt(BuildContext context, String shortId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Receipt #$shortId"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status: Paid Online", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Customer: ${data['userName'] ?? 'N/A'}"),
            Text("Total: Rs. ${data['total'] ?? 0}"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  Widget _headerSection(String text, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text("$text ($count)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }
}

class DeliveryRouteMapScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final String deliveryPersonName;

  const DeliveryRouteMapScreen({
    required this.orderId,
    required this.orderData,
    required this.deliveryPersonName,
    super.key,
  });

  @override
  State<DeliveryRouteMapScreen> createState() => _DeliveryRouteMapScreenState();
}

class _DeliveryRouteMapScreenState extends State<DeliveryRouteMapScreen> with TickerProviderStateMixin {
  MapLibreMapController? _mapController;
  LatLng? _driverPos;
  StreamSubscription<Position>? _positionSub;

  static const LatLng _kDefaultCenter = LatLng(27.7172, 85.3240);
  
  bool _isMoving = false;
  String _currentAddress = "Fetching destination...";
  final LocationService _locationService = LocationService();

  late AnimationController _pinController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeOut),
    );
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool granted = await _locationService.requestPermission();
    if (!granted) return;

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
  }

  void _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
    
    final customerLat = (widget.orderData['customerLat'] as num?)?.toDouble();
    final customerLng = (widget.orderData['customerLng'] as num?)?.toDouble();
    
    if (customerLat != null && customerLng != null) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(customerLat, customerLng),
          iconImage: "marker-15",
          iconColor: "#FF5252",
          iconSize: 2.0,
        ),
      );
      _updateAddress(LatLng(customerLat, customerLng));
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    String address = await _locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.orderData['status'] ?? 'Processing';
    final shortId = widget.orderId.substring(0, min(6, widget.orderId.length));

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _driverPos ?? _kDefaultCenter,
              zoom: 14.5,
              tilt: 45,
            ),
            myLocationEnabled: true,
            onCameraMove: (pos) {
              if (!_isMoving) {
                setState(() => _isMoving = true);
                _pinController.forward();
              }
            },
            onCameraIdle: () {
              setState(() => _isMoving = false);
              _pinController.reverse();
            },
            styleString: "https://tiles.openfreemap.org/styles/positron",
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          Positioned(
            top: 80, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: _kGreen, child: Icon(Icons.delivery_dining, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Rider: ${widget.deliveryPersonName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(status, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinAnimation.value - 20),
                  child: const Icon(Icons.location_on, size: 45, color: Colors.redAccent),
                );
              },
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 15),
                  const Text("DESTINATION", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.flag, color: Colors.redAccent, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_currentAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context),
                      child: Text("ORDER #$shortId - BACK", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 230, right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: true,
              onPressed: () {
                if (_driverPos != null) _mapController?.animateCamera(CameraUpdate.newLatLng(_driverPos!));
              },
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

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
            return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text("No order details assigned", style: TextStyle(color: Colors.grey))));
          }

          final alerts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, idx) {
              final data = alerts[idx].data() as Map<String, dynamic>;
              final name = data['customerName'] ?? data['userName'] ?? 'Customer';
              final phone = data['customerPhone'] ?? data['userPhone'] ?? 'No Number';
              final itemsSummary = data['itemsSummary'] ?? 'Items';

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
                        Row(children: [const Icon(Icons.person, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Customer: $name")]),
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Phone: $phone")]),
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.shopping_bag, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text("Details: $itemsSummary", maxLines: 2, overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)),
                          child: Text("Drop: ${data['deliveryAddress'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        )
                      ],
                    ),
                  )
               );
              },
          );
        },
      ),
    );
  }
}

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
              title: const Text("Upload QR Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickQrCodeImage();
              },
            ),
            if (_qrCodeImgPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Delete QR Photo"),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR updated")));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR removed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('deliveryId', isEqualTo: widget.user.uid)
            .where('status', isEqualTo: 'Delivered')
            .snapshots(),
        builder: (context, snapshot) {
          double totalEarnings = 0;
          List<Map<String, dynamic>> recentEarnings = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final earning = (data['deliveryFee'] ?? 100).toDouble();
              totalEarnings += earning;
              recentEarnings.add({
                'id': doc.id.substring(0, min(6, doc.id.length)),
                'amount': earning,
              });
            }
          }

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
                    children: [
                      const Text("WALLET BALANCE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Rs. ${totalEarnings.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Total Earned", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Payment Modes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _paymentModeRow("COD", Icons.payments, Colors.amber.shade900),
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
                            const Text("Manage QR Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                const Text("Recent Income", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (recentEarnings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("No earnings", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  ...recentEarnings.reversed.take(10).map((e) => _paymentHistoryRow("Delivery complete #${e['id']}", "Rs. ${e['amount']}")),
              ],
            ),
          );
        }
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
              title: Text("Choose ${isProfile ? 'Profile' : 'License'} Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile);
              },
            ),
            if (isProfile ? _profileImgPath != null : _licenseImgPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text("Delete Photo"),
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

    String? finalProfileUrl = _profileImgPath;
    String? finalLicenseUrl = _licenseImgPath;

    try {
      final cloudinary = CloudinaryPublic('drt6y7f8v', 'agridirect_unsigned', cache: false);

      if (_profileImgPath != null && !(_profileImgPath!.startsWith('http'))) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_profileImgPath!, folder: 'profile_pics'),
        );
        finalProfileUrl = response.secureUrl;
      }

      if (_licenseImgPath != null && !(_licenseImgPath!.startsWith('http'))) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_licenseImgPath!, folder: 'licenses'),
        );
        finalLicenseUrl = response.secureUrl;
      }

      final updates = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'vehicleDetails': _vehicleController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (finalProfileUrl == null) {
        updates['profileImageUrl'] = FieldValue.delete();
      } else {
        updates['profileImageUrl'] = finalProfileUrl;
      }

      if (finalLicenseUrl == null) {
        updates['licenseImageUrl'] = FieldValue.delete();
      } else {
        updates['licenseImageUrl'] = finalLicenseUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(
          updates,
          SetOptions(merge: true)
      );

      await FirebaseFirestore.instance.collection('riders').doc(widget.user.uid).set(
          updates,
          SetOptions(merge: true)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile saved")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                    backgroundColor: _kGreen.withValues(alpha: 0.1),
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
          const Text("Rider Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _buildField("Full Name", _nameController, Icons.badge),
          _buildField("Phone", _phoneController, Icons.phone),
          _buildField("Vehicle Details", _vehicleController, Icons.motorcycle),
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
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.assignment, color: Colors.grey), SizedBox(height: 4), Text("Manage License Image", style: TextStyle(fontSize: 12, color: Colors.grey))]),
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
    final address = data['deliveryAddress'] ?? 'No Address';

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
                  decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(address, style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("Price: Rs. ${total is num ? total.toStringAsFixed(2) : total}", style: const TextStyle(fontWeight: FontWeight.bold, color: _kGreen, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, side: const BorderSide(color: _kGreen)),
                    onPressed: () => _showDeliveryRoute(context, doc.id, data),
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
    if (status == 'Awaiting Pickup') return "Accept & Pickup";
    if (status == 'Picked Up') return "Start Delivery";
    if (status == 'On the way') return "Mark Arrived";
    return "Mark Delivered";
  }

  void _showDeliveryRoute(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    final deliveryPersonName = orderData['deliveryName'] ?? 'Rider';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryRouteMapScreen(
          orderId: orderId,
          orderData: orderData,
          deliveryPersonName: deliveryPersonName,
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context, String orderId, String status, Map<String, dynamic> data, String riderUid) async {
    String next = 'Delivered';
    if (status == 'Awaiting Pickup') {
      next = 'Picked Up';
    } else if (status == 'Picked Up') {
      next = 'On the way';
    } else if (status == 'On the way') {
      next = 'Arrived';
    }

    try {
      final riderDoc = await FirebaseFirestore.instance.collection('riders').doc(riderUid).get();
      final riderData = riderDoc.exists
          ? riderDoc.data()
          : (await FirebaseFirestore.instance.collection('users').doc(riderUid).get()).data();

      final riderName = riderData?['fullName'] ?? riderData?['name'] ?? "Rider";
      final riderPhone = riderData?['phone'] ?? "";

      final freshSnap = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final freshData = freshSnap.data();
      if (freshData != null &&
          freshData['deliveryId'] != null &&
          freshData['deliveryId'] != "" &&
          freshData['deliveryId'] != riderUid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order already accepted by another rider"), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': next,
        'deliveryId': riderUid,
        'deliveryName': riderName, 
        'deliveryPhone': riderPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final shortId = orderId.substring(0, min(6, orderId.length));
      final customerId = data['userId'];

      if (customerId != null) {
        String title = 'Order Update';
        String body = 'Order #$shortId status is $next';

        if (next == 'Picked Up') {
          title = 'Order Picked Up';
          body = 'Rider has picked up package #$shortId';
        } else if (next == 'On the way') {
          title = 'On The Way';
          body = 'Rider is coming with package #$shortId';
        } else if (next == 'Arrived') {
          title = 'Rider Arrived';
          body = 'Your rider has reached the location. Please collect package #$shortId';
        } else if (next == 'Delivered') {
          title = 'Delivered';
          body = 'Package #$shortId has been dropped off';
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Status is now $next"), backgroundColor: _kGreen)
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }
}

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