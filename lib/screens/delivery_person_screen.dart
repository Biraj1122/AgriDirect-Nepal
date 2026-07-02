
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
  StreamSubscription<QuerySnapshot>? _availableOrdersSub;
  final Set<String> _notifiedOrders = {};

  // Lifted state to keep map/routing stable across tabs
  LatLng? _driverPos;
  Map<String, dynamic>? _activeOrderData;
  StreamSubscription<QuerySnapshot>? _activeOrderSub;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _setupFCM();
    _startGlobalLocationTracking();
    _listenForAvailableOrders();
    _listenToActiveOrder();
  }

  Future<void> _startGlobalLocationTracking() async {
    bool granted = await _locationService.requestPermission();
    if (!granted) return;

    // Initial position
    final p = await _locationService.getCurrentLocation();
    if (p != null && mounted) {
      setState(() => _driverPos = LatLng(p.latitude, p.longitude));
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      if (mounted) {
        setState(() => _driverPos = LatLng(pos.latitude, pos.longitude));
      }
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

  void _listenToActiveOrder() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _activeOrderSub = FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryId', isEqualTo: user.uid)
        .where('status', whereIn: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'])
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        if (mounted) {
          setState(() => _activeOrderData = data);
        }
      } else {
        if (mounted) {
          setState(() => _activeOrderData = null);
        }
      }
    });
  }

  void _listenForAvailableOrders() {
    _availableOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Farmer Accepted')
        .where('deliveryId', isNull: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (var doc in snapshot.docs) {
        if (!_notifiedOrders.contains(doc.id)) {
          _notifiedOrders.add(doc.id);
          _showNewOrderDialog(doc);
        }
      }
    });
  }

  void _showNewOrderDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining_rounded, color: primaryTeal, size: 28),
            SizedBox(width: 12),
            Text("New Shipment!", style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("A new order is ready for pickup near you.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _dialogInfo(Icons.storefront_rounded, "From: ${data['farmName'] ?? 'Farm'}"),
            _dialogInfo(Icons.location_on_rounded, "To: ${data['deliveryAddress'] ?? 'Customer'}"),
            _dialogInfo(Icons.payments_rounded, "Fee: Rs. ${data['deliveryFee'] ?? 40}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Dismiss", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _acceptAvailableOrder(doc.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Accept Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryTeal),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _acceptAvailableOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final riderDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final riderName = riderDoc.data()?['fullName'] ?? 'Rider';
    final riderPhone = riderDoc.data()?['phone'] ?? '';

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'deliveryId': user.uid,
      'deliveryName': riderName,
      'deliveryPhone': riderPhone,
      'status': 'Awaiting Pickup',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() => _tab = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order accepted! Directions loaded on map."), backgroundColor: primaryTeal),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _availableOrdersSub?.cancel();
    _activeOrderSub?.cancel();
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
      _ShipmentsTab(user: user, onSwitchToMap: () => setState(() => _tab = 0)),
      _EarningsTab(user: user),
      _ProfileTab(user: user, logoutCallback: _logout),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _HomeMapTab(user: user, driverPos: _driverPos, activeOrderData: _activeOrderData),
            _ShipmentsTab(user: user, onSwitchToMap: () => setState(() => _tab = 0)),
            _EarningsTab(user: user),
            _ProfileTab(user: user, logoutCallback: _logout),
          ],
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
  final LatLng? driverPos;
  final Map<String, dynamic>? activeOrderData;
  const _HomeMapTab({required this.user, this.driverPos, this.activeOrderData});

  @override
  State<_HomeMapTab> createState() => _HomeMapTabState();
}

class _HomeMapTabState extends State<_HomeMapTab> {
  final LocationService _locationService = LocationService();
  static const LatLng _kDefaultCenter = LatLng(27.7172, 85.3240);

  LatLng? _lastRouteUpdatePos;
  MapLibreMapController? _mapController;
  Line? _routeLine;
  double? _routeDistance;
  double? _routeDuration;
  String? _targetLabel;

  Symbol? _riderSymbol;
  Symbol? _targetSymbol;
  Circle? _riderCircle;
  Circle? _targetCircle;

  @override
  void didUpdateWidget(_HomeMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force route recalculation if order status changed or new order assigned
    if (widget.activeOrderData != oldWidget.activeOrderData) {
      if (widget.activeOrderData?['id'] != oldWidget.activeOrderData?['id'] ||
          widget.activeOrderData?['status'] != oldWidget.activeOrderData?['status']) {
        _lastRouteUpdatePos = null;
      }
      _updateDirections(force: true);
    } else if (widget.driverPos != oldWidget.driverPos) {
      _updateDirections();
    }
  }

  Future<void> _cancelActiveOrderAssignment() async {
    if (widget.activeOrderData == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unassign Order?"),
        content: const Text("Are you sure you want to remove yourself from this delivery? It will be available for other riders."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Unassign", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final orderId = widget.activeOrderData!['id'];
      if (orderId == null) return;

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'deliveryId': null,
        'deliveryName': null,
        'deliveryPhone': null,
        'status': 'Farmer Accepted',
      });
    }
  }

  void _centerOnDriver() {
    if (widget.driverPos != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(widget.driverPos!, 16));
    }
  }

  Future<void> _updateDirections({bool force = false}) async {
    if (_mapController == null) return;

    // IF NO ORDER: CLEAR MAP AND UI COMPLETELY
    if (widget.activeOrderData == null) {
      if (_routeLine != null) {
        try { await _mapController!.removeLine(_routeLine!); } catch (_) {}
        _routeLine = null;
      }
      if (mounted) {
        setState(() {
          _routeDistance = null;
          _routeDuration = null;
          _targetLabel = null;
          _lastRouteUpdatePos = null;
        });
      }
      // Remove all symbols and circles to reset the map to a clean state
      if (_mapController != null) {
        if (_targetSymbol != null) { try { await _mapController!.removeSymbol(_targetSymbol!); } catch (_) {} _targetSymbol = null; }
        if (_targetCircle != null) { try { await _mapController!.removeCircle(_targetCircle!); } catch (_) {} _targetCircle = null; }
        if (_riderSymbol != null) { try { await _mapController!.removeSymbol(_riderSymbol!); } catch (_) {} _riderSymbol = null; }
        if (_riderCircle != null) { try { await _mapController!.removeCircle(_riderCircle!); } catch (_) {} _riderCircle = null; }
      }
      return;
    }

    if (widget.driverPos == null) return;

    // Debounce/Optimization: only update route if moved > 50m
    if (!force && _lastRouteUpdatePos != null) {
      final dist = Geolocator.distanceBetween(
          widget.driverPos!.latitude, widget.driverPos!.longitude,
          _lastRouteUpdatePos!.latitude, _lastRouteUpdatePos!.longitude
      );
      if (dist < 50) return;
    }

    try {
      LatLng startPos = widget.driverPos!;
      LatLng? target;
      String label = "";

      final data = widget.activeOrderData!;
      final status = data['status'];

      // Diagnostic print to debug missing coordinates
      debugPrint("Processing directions for status: $status");

      final fLat = (data['farmerLat'] as num?)?.toDouble();
      final fLng = (data['farmerLng'] as num?)?.toDouble();
      final cLat = (data['customerLat'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble();
      final cLng = (data['customerLng'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble();

      if (status == 'Farmer Accepted' || status == 'Awaiting Pickup') {
        if (fLat != null && fLng != null) {
          target = LatLng(fLat, fLng);
          label = "Farm (Pickup)";
        }
      } else if (status == 'Picked Up' || status == 'On the way' || status == 'Arrived' || status == 'Confirm Received') {
        if (cLat != null && cLng != null) {
          target = LatLng(cLat, cLng);
          label = "Customer (Delivery)";
        }
      }

      // If the specific target coordinates are missing, fallback to generic order location if available
      if (target == null && (cLat != null && cLng != null)) {
        target = LatLng(cLat, cLng);
        label = "Destination";
      }

      if (target != null) {
        final routeData = await _locationService.getRouteData(
          startPos.latitude, startPos.longitude,
          target.latitude, target.longitude,
        );

        final List<LatLng> polyline = (routeData['points'] as List).map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();

        if (mounted) {
          setState(() {
            _routeDistance = routeData['distance'];
            _routeDuration = routeData['duration'];
            _targetLabel = label;
            _lastRouteUpdatePos = startPos;
          });
        }

        if (_routeLine == null) {
          _routeLine = await _mapController!.addLine(LineOptions(
            geometry: polyline,
            lineColor: "#2E5BFF",
            lineWidth: 5,
            lineOpacity: 0.8,
            lineJoin: "round",
          ));
        } else {
          await _mapController!.updateLine(_routeLine!, LineOptions(geometry: polyline));
        }
      } else {
        if (_routeLine != null) {
          try { await _mapController!.removeLine(_routeLine!); } catch (_) {}
          _routeLine = null;
        }
        if (mounted) {
          setState(() {
            _routeDistance = null;
            _routeDuration = null;
            _targetLabel = null;
          });
        }
      }

      _updateMarkers(widget.driverPos, target, label);
    } catch (e) {
      debugPrint("Error updating rider directions: $e");
    }
  }

  Future<void> _updateMarkers(LatLng? rider, LatLng? target, String label) async {
    if (_mapController == null) return;

    // Update Rider Marker
    if (rider != null) {
      if (_riderSymbol == null) {
        try {
          _riderCircle = await _mapController!.addCircle(CircleOptions(
            geometry: rider, circleRadius: 10, circleColor: "#2E5BFF", circleStrokeWidth: 3, circleStrokeColor: "#FFFFFF",
          ));
          _riderSymbol = await _mapController!.addSymbol(SymbolOptions(
            geometry: rider, textField: "Me (Rider)", textSize: 12, textColor: "#2E5BFF", textHaloColor: "#FFFFFF", textHaloWidth: 2, textOffset: const Offset(0, -2), textAnchor: "bottom",
          ));
        } catch (e) {
          debugPrint("Error adding rider marker: $e");
        }
      } else {
        _mapController!.updateSymbol(_riderSymbol!, SymbolOptions(geometry: rider));
        if (_riderCircle != null) {
          _mapController!.updateCircle(_riderCircle!, CircleOptions(geometry: rider));
        }
      }
    }

    // Update Target Marker (Farm or Customer)
    if (target != null) {
      final String colorHex = label.contains("Farm") ? "#F59E0B" : "#EF4444";

      if (_targetSymbol == null) {
        try {
          _targetCircle = await _mapController!.addCircle(CircleOptions(
            geometry: target, circleRadius: 12, circleColor: colorHex, circleStrokeWidth: 3, circleStrokeColor: "#FFFFFF",
          ));
          _targetSymbol = await _mapController!.addSymbol(SymbolOptions(
            geometry: target, textField: label, textSize: 12, textColor: colorHex, textHaloColor: "#FFFFFF", textHaloWidth: 2, textOffset: const Offset(0, -2), textAnchor: "bottom",
          ));
        } catch (e) {
          debugPrint("Error adding target marker: $e");
        }
      } else {
        _mapController!.updateSymbol(_targetSymbol!, SymbolOptions(
          geometry: target, textField: label, textColor: colorHex,
        ));
        if (_targetCircle != null) {
          _mapController!.updateCircle(_targetCircle!, CircleOptions(
            geometry: target, circleColor: colorHex,
          ));
        }
      }
    } else {
      // Clear target markers if no target
      if (_targetSymbol != null) {
        try { await _mapController!.removeSymbol(_targetSymbol!); } catch (_) {}
        _targetSymbol = null;
      }
      if (_targetCircle != null) {
        try { await _mapController!.removeCircle(_targetCircle!); } catch (_) {}
        _targetCircle = null;
      }
    }

    // Adjust camera to fit markers
    _fitCamera(rider, target);
  }

  void _fitCamera(LatLng? rider, LatLng? target) {
    if (_mapController == null || rider == null) return;

    if (target == null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(rider, 16));
      return;
    }

    List<LatLng> points = [rider, target];

    double south = points[0].latitude, north = points[0].latitude, west = points[0].longitude, east = points[0].longitude;
    for (var p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    // Add padding
    if (south == north) { south -= 0.001; north += 0.001; }
    if (west == east) { west -= 0.001; east += 0.001; }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
      left: 70, right: 70, top: 160, bottom: 100,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          initialCameraPosition: CameraPosition(target: widget.driverPos ?? _kDefaultCenter, zoom: 14),
          myLocationEnabled: true,
          styleString: "https://tiles.openfreemap.org/styles/positron",
          onMapCreated: (controller) {
            _mapController = controller;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _updateDirections(force: true);
                _centerOnDriver();
              }
            });
          },
          onMapClick: (point, latlng) => _centerOnDriver(),
        ),

        if (_routeDistance != null)
          Positioned(
            top: 100, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D25),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: secondaryBlue, child: Icon(Icons.navigation_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Heading to ${_targetLabel ?? 'Destination'}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("${_routeDistance!.toStringAsFixed(1)} km • ${_routeDuration!.toStringAsFixed(0)} mins",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.white54, size: 24),
                    onPressed: _cancelActiveOrderAssignment,
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          top: 20, left: 20, right: 20,
          child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final isOnline = userData?['isOnline'] ?? true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
                  child: Row(
                    children: [
                      IconBadge(teal: isOnline ? primaryTeal : Colors.grey, blue: isOnline ? secondaryBlue : Colors.grey.shade700, icon: Icons.delivery_dining_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Status: ${isOnline ? 'Online' : 'Offline'}",
                                style: TextStyle(fontWeight: FontWeight.w800, color: isOnline ? primaryTeal : Colors.grey)),
                            Text(_routeDistance != null ? "Current Task: $_targetLabel" : (isOnline ? "Waiting for new orders..." : "Go online to see orders"),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
          ),
        ),
      ],
    );
  }
}

class _ShipmentsTab extends StatelessWidget {
  final User user;
  final VoidCallback onSwitchToMap;
  const _ShipmentsTab({required this.user, required this.onSwitchToMap});

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
                _buildOrderList(context, ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived', 'Confirm Received'], true),
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
                  _locationActionRow(
                    context,
                    Icons.storefront_rounded,
                    "Pickup: ${data['farmName'] ?? 'Farm'}",
                    data['status'] == 'Farmer Accepted' || data['status'] == 'Awaiting Pickup',
                    isMyOrder,
                    onSwitchToMap,
                  ),
                  const SizedBox(height: 8),
                  _locationActionRow(
                    context,
                    Icons.location_on_rounded,
                    "Deliver: ${data['deliveryAddress'] ?? 'Customer'}",
                    data['status'] == 'Picked Up' || data['status'] == 'On the way' || data['status'] == 'Arrived' || data['status'] == 'Confirm Received',
                    isMyOrder,
                    onSwitchToMap,
                  ),
                  if (isActionable) ...[
                    const SizedBox(height: 16),
                    if (!isMyOrder)
                      GradientButton(
                          label: "Accept Shipment",
                          icon: Icons.check_rounded,
                          isLoading: false,
                          teal: primaryTeal, blue: secondaryBlue,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Accept Shipment?"),
                                content: const Text("Are you sure you want to accept this delivery?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                                    child: const Text("Accept", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _acceptOrder(context, docs[i].id, user.uid);
                              onSwitchToMap();
                            }
                          }
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

  Widget _locationActionRow(BuildContext context, IconData icon, String text, bool isCurrentTarget, bool isMyOrder, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTarget ? secondaryBlue.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrentTarget ? secondaryBlue.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isCurrentTarget ? secondaryBlue : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrentTarget ? FontWeight.bold : FontWeight.normal,
                color: isCurrentTarget ? Colors.black87 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMyOrder)
            TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: isCurrentTarget ? secondaryBlue : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.directions_rounded, size: 16),
              label: Text(isCurrentTarget ? "Navigate" : "View Map", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
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
      case 'Farmer Accepted': return 'Mark as Picked Up';
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
    if (current == 'Farmer Accepted' || current == 'Awaiting Pickup') {
      next = 'Picked Up';
    } else if (current == 'Picked Up') {
      next = 'On the way';
    } else if (current == 'On the way') {
      next = 'Arrived';
    } else if (current == 'Arrived') {
      next = 'Confirm Received';
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
  bool _isUploadingPhoto = false;
  String _currentAddress = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _fetchCurrentAddress();
  }

  Future<void> _fetchCurrentAddress() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final address = await LocationService().getAddressFromLatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentAddress = address);
    } catch (e) {
      if (mounted) setState(() => _currentAddress = "Location unavailable");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadImage(image, 'profile_pics');
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
          'profileImageUrl': url,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: primaryTeal.withValues(alpha: 0.1),
                            backgroundImage: (data?['profileImageUrl'] != null && data!['profileImageUrl'].toString().isNotEmpty)
                                ? CachedNetworkImageProvider(data['profileImageUrl']) : null,
                            child: (data?['profileImageUrl'] == null || data!['profileImageUrl'].toString().isEmpty)
                                ? const Icon(Icons.person_rounded, size: 60, color: primaryTeal) : null,
                          ),
                          if (_isUploadingPhoto)
                            const Positioned.fill(child: CircularProgressIndicator(color: primaryTeal)),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
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
              const FieldLabel(label: "AVAILABILITY"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.power_settings_new_rounded, color: (data?['isOnline'] ?? true) ? primaryTeal : Colors.grey, size: 20),
                    const SizedBox(width: 16),
                    const Expanded(child: Text("Online Status", style: TextStyle(fontWeight: FontWeight.w600))),
                    Switch(
                      value: data?['isOnline'] ?? true,
                      activeThumbColor: Colors.white,
                      activeTrackColor: primaryTeal,
                      onChanged: (val) async {
                        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'isOnline': val});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel(label: "CURRENT LOCATION"),
              const SizedBox(height: 12),
              _profileItem(Icons.location_on_rounded, _currentAddress, onTap: _fetchCurrentAddress),
              const SizedBox(height: 24),
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

class _VerificationSheet extends StatefulWidget {
  final String uid;
  final Map<String, dynamic>? currentData;
  const _VerificationSheet({required this.uid, this.currentData});

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  XFile? licenseFront, citizenshipFront, citizenshipBack;
  bool isUploading = false;
  int step = 1;

  Future<void> _pickImage(String type) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() {
        if (type == 'lf') licenseFront = img;
        if (type == 'cf') citizenshipFront = img;
        if (type == 'cb') citizenshipBack = img;
      });
    }
  }

  Future<void> _submit() async {
    if (licenseFront == null || citizenshipFront == null || citizenshipBack == null) return;

    setState(() => isUploading = true);
    try {
      final storage = StorageService();
      final lfUrl = await storage.uploadImage(licenseFront!, 'verification/${widget.uid}');
      final cfUrl = await storage.uploadImage(citizenshipFront!, 'verification/${widget.uid}');
      final cbUrl = await storage.uploadImage(citizenshipBack!, 'verification/${widget.uid}');

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'licenseFront': lfUrl,
        'citizenshipFront': cfUrl,
        'citizenshipBack': cbUrl,
        'verificationStatus': 'pending',
        'documentsUploadedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'verification',
        'title': 'New Rider Verification',
        'body': 'A rider has uploaded documents for verification.',
        'riderId': widget.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
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
            _uploadBox("License Front", licenseFront, () => _pickImage('lf')),
            const SizedBox(height: 32),
            GradientButton(label: "Next Step", icon: Icons.arrow_forward_rounded, isLoading: false, teal: primaryTeal, blue: secondaryBlue, onTap: () => setState(() => step = 2)),
          ] else ...[
            _uploadBox("Citizenship Front", citizenshipFront, () => _pickImage('cf')),
            const SizedBox(height: 16),
            _uploadBox("Citizenship Back", citizenshipBack, () => _pickImage('cb')),
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
