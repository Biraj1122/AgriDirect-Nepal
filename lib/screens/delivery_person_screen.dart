import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../Success/exit_wrapper.dart';
import '../Success/shared_widgets.dart';
import '../viewmodels/delivery_viewmodel.dart';
import 'auth/login_screen.dart';
import 'misc/farm_osm_screen.dart';

const Color primaryTeal = Color(0xFF1D9E75);
const Color secondaryBlue = Color(0xFF2E5BFF);
const Color backgroundColor = Color(0xFFF8FAFC);

class DeliveryPersonScreen extends StatefulWidget {
  const DeliveryPersonScreen({super.key});

  @override
  State<DeliveryPersonScreen> createState() => _DeliveryPersonScreenState();
}

class _DeliveryPersonScreenState extends State<DeliveryPersonScreen> {
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<QuerySnapshot>? _availableOrdersSub;
  final Set<String> _notifiedOrders = {};
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
    final vm = context.read<DeliveryViewModel>();
    bool granted = await _locationService.requestPermission();
    if (!granted) return;

    final p = await _locationService.getCurrentLocation();
    if (p != null && mounted) {
      vm.updateDriverPos(LatLng(p.latitude, p.longitude));
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      if (mounted) {
        vm.updateDriverPos(LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  void _listenToActiveOrder() {
    final vm = context.read<DeliveryViewModel>();
    _activeOrderSub = vm.activeOrderStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        data['id'] = snapshot.docs.first.id;
        if (mounted) vm.setActiveOrder(data);
      } else {
        if (mounted) vm.setActiveOrder(null);
      }
    });
  }

  void _listenForAvailableOrders() {
    final vm = context.read<DeliveryViewModel>();
    _availableOrdersSub = vm.availableOrdersStream.listen((snapshot) {
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
    final vm = context.read<DeliveryViewModel>();
    await vm.acceptOrder(orderId);

    if (mounted) {
      vm.setTabIndex(0);
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
    final role = (doc.data()?['role'] ?? '').toString().toLowerCase();

    if (role != 'delivery person') {
      _logout();
    }
  }

  void _logout() {
    if (mounted) {
      final vm = context.read<DeliveryViewModel>();
      vm.logout();
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
    final vm = context.watch<DeliveryViewModel>();
    if (vm.uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryTeal)));
    }

    return DoubleBackExitWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: IndexedStack(
            index: vm.tabIndex,
            children: [
              _HomeMapTab(user: FirebaseAuth.instance.currentUser!, driverPos: vm.driverPos, activeOrderData: vm.activeOrderData),
              _ShipmentsTab(user: FirebaseAuth.instance.currentUser!, onSwitchToMap: () => vm.setTabIndex(0)),
              _EarningsTab(user: FirebaseAuth.instance.currentUser!),
              _ProfileTab(user: FirebaseAuth.instance.currentUser!, logoutCallback: _logout),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: vm.tabIndex,
            onTap: (i) => vm.setTabIndex(i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryTeal,
            unselectedItemColor: Colors.grey.shade400,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map_rounded), label: "Map"),
              BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping_rounded), label: "Shipments"),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: "Wallet"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
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

      final vm = context.read<DeliveryViewModel>();
      await vm.unassignOrder(orderId);
    }
  }

  void _centerOnDriver() {
    if (widget.driverPos != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(widget.driverPos!, 16));
    }
  }

  Future<void> _updateDirections({bool force = false}) async {
    if (_mapController == null) return;

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
      if (_mapController != null) {
        if (_targetSymbol != null) { try { await _mapController!.removeSymbol(_targetSymbol!); } catch (_) {} _targetSymbol = null; }
        if (_targetCircle != null) { try { await _mapController!.removeCircle(_targetCircle!); } catch (_) {} _targetCircle = null; }
        if (_riderSymbol != null) { try { await _mapController!.removeSymbol(_riderSymbol!); } catch (_) {} _riderSymbol = null; }
        if (_riderCircle != null) { try { await _mapController!.removeCircle(_riderCircle!); } catch (_) {} _riderCircle = null; }
      }
      return;
    }

    if (widget.driverPos == null) return;

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
      if (_targetSymbol != null) {
        try { await _mapController!.removeSymbol(_targetSymbol!); } catch (_) {}
        _targetSymbol = null;
      }
      if (_targetCircle != null) {
        try { await _mapController!.removeCircle(_targetCircle!); } catch (_) {}
        _targetCircle = null;
      }
    }
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
          logoEnabled: false,
          styleString: "https://tiles.openfreemap.org/styles/positron",
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onStyleLoadedCallback: () {
            if (mounted) {
              _updateDirections(force: true);
              _centerOnDriver();
            }
          },
          onMapClick: (point, latlng) => _centerOnDriver(),
        ),

        // CENTER ON ME BUTTON
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _centerOnDriver,
            child: const Icon(Icons.my_location_rounded, color: primaryTeal),
          ),
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
          top: 25, left: 25, right: 25,
          child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final isOnline = userData?['isOnline'] ?? true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOnline 
                              ? [const Color(0xFF1D9E75), const Color(0xFF2E5BFF)]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Status: ${isOnline ? 'Online' : 'Offline'}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isOnline ? primaryTeal : Colors.grey.shade600
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _routeDistance != null 
                                ? "Current Task: $_targetLabel" 
                                : (isOnline ? "Waiting for new orders..." : "Go online to see orders"),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
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
          const SizedBox(height: 20),
          const Heading(title: "Shipments", subtitle: "Manage your delivery workload"),
          const SizedBox(height: 10),
          TabBar(
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: primaryTeal,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            dividerColor: Colors.transparent,
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
    final vm = context.watch<DeliveryViewModel>();
    return StreamBuilder<QuerySnapshot>(
      stream: vm.getOrdersByStatuses(statuses),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryTeal));
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map;
          if (isActionable) {
            return data['deliveryId'] == null || data['deliveryId'] == user.uid;
          } else {
            return data['deliveryId'] == user.uid;
          }
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActionable ? Icons.local_shipping_outlined : Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade100),
              const SizedBox(height: 16),
              Text(isActionable ? "No active shipments" : "No delivery history", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order #${docs[i].id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1A1D25))),
                      _statusChip(data['status'] ?? 'Pending'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _locationRow(Icons.storefront_rounded, "Pickup: ${data['farmName'] ?? 'Farm'}"),
                  const SizedBox(height: 12),
                  _locationRow(Icons.location_on_rounded, "Deliver: ${data['deliveryAddress'] ?? 'Customer'}"),
                  const SizedBox(height: 20),
                  if (isActionable) ...[
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text("Accept Shipment?"),
                                content: const Text("Are you sure you want to accept this delivery?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Accept", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await vm.acceptOrder(docs[i].id);
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
                          onTap: () => vm.updateOrderStatus(docs[i].id, data['status'])
                      ),
                  ] else ...[
                    Text("Completed: ${data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate().toString().substring(0, 16) : 'N/A'}",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _locationRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = primaryTeal;
    if (status == 'Cancelled') color = Colors.redAccent;
    if (status == 'Delivered' || status == 'Confirm Received') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  String _getNextStatusLabel(String? current) {
    switch (current) {
      case 'Farmer Accepted': return 'Mark as Picked Up';
      case 'Awaiting Pickup': return 'Mark as Picked Up';
      case 'Picked Up': return 'Start Delivery';
      case 'On the way': return 'I have Arrived';
      case 'Arrived': return 'Confirm Delivery';
      case 'Confirm Received': return 'Customer Acknowledged';
      default: return 'Update Progress';
    }
  }

  Future<void> _acceptOrder(String orderId, String uid) async {
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

  Future<void> _updateStatus(String orderId, String? current) async {
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Order #${docs[i].id.substring(0,8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text("Rs. ${gross.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 32),
                        _incomeRow("Gross Delivery Fee", gross),
                        const SizedBox(height: 8),
                        _incomeRow("Platform Fee (20%)", -fee, isNegative: true),
                        const Divider(height: 32),
                        _incomeRow("Your Net Earnings", net, isBold: true, color: Colors.green),
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
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        Text(
          "${isNegative ? '-' : ''}Rs. ${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, 
            color: color ?? (isNegative ? Colors.redAccent : Colors.black87),
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DeliveryViewModel>();
    return StreamBuilder<QuerySnapshot>(
      stream: vm.getOrdersByStatuses(['Delivered', 'Confirm Received']),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) => (d.data() as Map)['deliveryId'] == user.uid).toList();
        double total = 0;
        for (var d in docs) {
          final data = d.data() as Map;
          total += ((data['deliveryFee'] ?? 40).toDouble() * 0.8);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Heading(title: "My Earnings", subtitle: "Track your delivery revenue and payouts"),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _showRevenueDetails(context, docs, total),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9E75), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Wallet Balance", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 16)),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.6), size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text("Rs. ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "RECENT TRANSACTIONS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ...docs.map((d) {
              final data = d.data() as Map;
              final net = (data['deliveryFee'] ?? 40).toDouble() * 0.8;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Delivery Reward", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1D25))),
                        const SizedBox(height: 2),
                        Text("Order #${d.id.substring(0,6).toUpperCase()}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    )),
                    Text("+Rs. ${net.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
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
  String _currentAddress = "Fetching location...";
  bool _isUploading = false;

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

  Future<void> _updateProfilePhoto() async {
    final vm = context.read<DeliveryViewModel>();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadImage(img, 'profile_pics');
      if (url != null) {
        await vm.updateProfileImage(url);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showChangePasswordDialog() {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F4E8), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Center(
          child: Text(
            "Change Password",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1A1D25)),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(currentPass, "Current Password", Icons.lock_outline_rounded),
            const SizedBox(height: 12),
            _dialogField(newPass, "New Password", Icons.vpn_key_outlined),
            const SizedBox(height: 12),
            _dialogField(confirmPass, "Confirm New Password", Icons.check_circle_outline_rounded),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (newPass.text != confirmPass.text || newPass.text.length < 6) return;
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPass.text,
                      );
                      
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPass.text);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Future<void> _updateLocation() async {
    final vm = context.read<DeliveryViewModel>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final String address = result['address'];
      final double lat = result['lat'];
      final double lng = result['lng'];

      await vm.updateRiderAddress(address, lat, lng);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Current location updated successfully!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DeliveryViewModel>();
    return StreamBuilder<DocumentSnapshot>(
        stream: vm.userStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['fullName'] ?? 'Rider Name';
          final pUrl = data?['profileImageUrl'];
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Heading(title: "My Profile", subtitle: "Manage your rider account settings"),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _updateProfilePhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: primaryTeal.withValues(alpha: 0.1),
                            backgroundImage: (pUrl != null && pUrl.toString().isNotEmpty)
                                ? CachedNetworkImageProvider(pUrl) : null,
                            child: (pUrl == null || pUrl.toString().isEmpty)
                                ? const Icon(Icons.person_rounded, size: 70, color: primaryTeal) : null,
                          ),
                          if (_isUploading)
                            const Positioned.fill(child: CircularProgressIndicator(color: primaryTeal)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
                    const SizedBox(height: 4),
                    Text(widget.user.email ?? '', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 15)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: primaryTeal, size: 18),
                          const SizedBox(width: 8),
                          Text("Verified Partner", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              const FieldLabel(label: "AVAILABILITY"),
              const SizedBox(height: 12),
              _settingsCard(
                icon: Icons.power_settings_new_rounded,
                title: "Online Status",
                trailing: Switch.adaptive(
                  value: data?['isOnline'] ?? true,
                  activeTrackColor: primaryTeal,
                  onChanged: (val) async {
                    await vm.updateOnlineStatus(val);
                  },
                ),
              ),

              const SizedBox(height: 24),
              const FieldLabel(label: "CURRENT LOCATION"),
              const SizedBox(height: 12),
              _settingsCard(
                icon: Icons.location_on_rounded,
                title: data?['address'] ?? _currentAddress,
                onEdit: _updateLocation,
              ),

              const SizedBox(height: 24),
              const FieldLabel(label: "ACCOUNT SETTINGS"),
              const SizedBox(height: 12),
              _settingsCard(icon: Icons.badge_rounded, title: name, onEdit: () {}),
              _settingsCard(icon: Icons.lock_rounded, title: "Change Password", onEdit: _showChangePasswordDialog),
              _settingsCard(icon: Icons.phone_rounded, title: data?['phone'] ?? 'Add phone'),

              const SizedBox(height: 40),
              GradientButton(
                  label: "Logout Account",
                  icon: Icons.logout_rounded,
                  isLoading: false,
                  teal: Colors.redAccent, blue: Colors.red.shade900,
                  onTap: widget.logoutCallback
              ),
              const SizedBox(height: 40),
            ],
          );
        }
    );
  }

  Widget _settingsCard({
    required IconData icon, 
    required String title, 
    Widget? trailing, 
    VoidCallback? onEdit,
    bool isVerified = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1D25)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing
          else if (isVerified) const Icon(Icons.check_circle_rounded, color: primaryTeal, size: 20)
          else if (onEdit != null) IconButton(
            icon: Icon(Icons.edit_rounded, color: Colors.grey.shade300, size: 18),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
