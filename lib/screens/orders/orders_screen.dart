import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_data.dart';
import '../../services/location_service.dart';
import '../home/navigation_screen.dart';
import '../misc/farmer_screen.dart';
import '../delivery_person_screen.dart';
import '../admin_page.dart';

class OrderScreen extends StatefulWidget {
  final String? orderId;
  final VoidCallback? onBackToHome;
  const OrderScreen({super.key, this.orderId, this.onBackToHome});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  String riderName = "Assigning...";
  String? riderPhone;
  String? deliveryId;
  String status = "Pending";
  MapLibreMapController? mapController;
  final LocationService _locationService = LocationService();
  double distance = 0.0;
  int estimatedTime = 0;

  late AnimationController _riderCardController;
  late Animation<Offset> _riderCardOffsetAnimation;

  Symbol? riderSymbol;
  LatLng? riderPosition;
  Timer? _trackingTimer;
  StreamSubscription? _orderSubscription;

  bool _isLoading = true;
  String? _activeOrderId;
  bool _noActiveOrder = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeOrder();
  }

  Future<void> _initializeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.orderId != null) {
        _activeOrderId = widget.orderId;
        _startTrackingFlow();
      } else {
        final query = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: ['Pending', 'Processing', 'Picked Up', 'On the way', 'Arrived'])
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          _activeOrderId = query.docs.first.id;
          _startTrackingFlow();
        } else {
          if (mounted) {
            setState(() {
              _noActiveOrder = true;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Order Initialization Error: $e");
      if (mounted) {
        setState(() {
          _noActiveOrder = true;
          _isLoading = false;
        });
      }
    }
  }

  void _startTrackingFlow() {
    _listenToOrderUpdates();
    if (mounted) setState(() => _isLoading = false);
  }

  void _listenToOrderUpdates() {
    if (_activeOrderId == null) return;

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(_activeOrderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final newStatus = data['status'] ?? status;
        final newRiderName = data['deliveryName'] ?? "Assigning...";
        final newRiderPhone = data['deliveryPhone'] ?? data['userPhone'];
        final newDeliveryId = data['deliveryId'];

        if (widget.orderId == null && (newStatus == 'Delivered' || newStatus == 'Cancelled')) {
          setState(() {
            _noActiveOrder = true;
          });
          return;
        }

        bool shouldStartSimulation = false;
        if (deliveryId == null && newDeliveryId != null) {
          shouldStartSimulation = true;
        }

        setState(() {
          status = newStatus;
          riderName = newRiderName;
          riderPhone = newRiderPhone;
          deliveryId = newDeliveryId;
        });

        if (shouldStartSimulation) {
          _calculateTrackingDetails();
          _startTrackingSimulation();
        }
      }
    });
  }

  void _setupAnimation() {
    _riderCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _riderCardOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, -2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _riderCardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _calculateTrackingDetails() {
    if (UserData.hasAddress && UserData.defaultLat != null && UserData.defaultLng != null) {
      distance = _locationService.calculateDistance(
        UserData.hqLat,
        UserData.hqLng,
        UserData.defaultLat!,
        UserData.defaultLng!,
      );
      estimatedTime = (distance * 2).round() + 10;
      riderPosition = const LatLng(UserData.hqLat, UserData.hqLng);
    }
  }

  void _startTrackingSimulation() {
    if (!UserData.hasAddress || UserData.defaultLat == null || UserData.defaultLng == null) return;
    if (_trackingTimer != null) return;

    _riderCardController.forward();

    const steps = 50;
    int currentStep = 0;

    _trackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
        return;
      }

      currentStep++;
      double t = currentStep / steps;

      double lat = UserData.hqLat + (UserData.defaultLat! - UserData.hqLat) * t;
      double lng = UserData.hqLng + (UserData.defaultLng! - UserData.hqLng) * t;

      if (mounted) {
        setState(() {
          riderPosition = LatLng(lat, lng);
          double remainingDist = _locationService.calculateDistance(
            lat, lng, UserData.defaultLat!, UserData.defaultLng!,
          );
          distance = remainingDist;
          estimatedTime = (remainingDist * 2).round();
          if (estimatedTime < 1) status = "Arrived";
        });
        _updateRiderMarker();
      }
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _addMarkers();
  }

  Future<void> _addMarkers() async {
    if (mapController == null) return;

    if (UserData.hasAddress && UserData.defaultLat != null && UserData.defaultLng != null) {
      await mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(UserData.defaultLat!, UserData.defaultLng!),
        iconImage: "marker-15",
        iconColor: "#FF0000",
        iconSize: 2.0,
      ));
    }

    await mapController!.addSymbol(SymbolOptions(
      geometry: const LatLng(UserData.hqLat, UserData.hqLng),
      iconImage: "marker-15",
      iconColor: "#00FF00",
      iconSize: 1.5,
    ));

    if (riderPosition != null) {
      riderSymbol = await mapController!.addSymbol(SymbolOptions(
        geometry: riderPosition!,
        iconImage: "airport-15",
        iconRotate: 90,
        iconColor: "#4CAF50",
        iconSize: 2.5,
      ));
    }
  }

  void _updateRiderMarker() {
    if (mapController != null && riderSymbol != null && riderPosition != null) {
      mapController!.updateSymbol(riderSymbol!, SymbolOptions(
        geometry: riderPosition!,
      ));
    }
  }

  @override
  void dispose() {
    _riderCardController.dispose();
    _trackingTimer?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _handleBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      if (widget.onBackToHome != null) {
        widget.onBackToHome!();
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final role = doc.data()?['role'];

          if (mounted) {
            Widget target;
            if (role == 'Farmer') {
              target = const FarmerScreen();
            } else if (role == 'Delivery Person') {
              target = const DeliveryPersonScreen();
            } else if (role == 'Admin') {
              target = const AdminPage();
            } else {
              target = NavigationScreen(userName: user.displayName ?? user.email ?? "User");
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => target),
              (route) => false,
            );
          }
        }
      }
    }
  }

  Future<void> _makeCall() async {
    final String phone = riderPhone ?? "+9779861509463";
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  bool _canCancelOrder() {
    return status != 'Delivered' &&
           status != 'Cancelled' &&
           (deliveryId == null || deliveryId!.isEmpty);
  }

  Future<void> _cancelOrder() async {
    if (_activeOrderId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(_activeOrderId)
            .update({
          'status': 'Cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully"), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_noActiveOrder) {
      return _buildEmptyState();
    }

    final bool hasRider = deliveryId != null && deliveryId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Order", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: _handleBack),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: riderPosition ?? const LatLng(UserData.hqLat, UserData.hqLng),
                    zoom: 13.5,
                  ),
                  onMapCreated: _onMapCreated,
                  styleString: "https://tiles.openfreemap.org/styles/positron",
                ),
                
                if (hasRider)
                  Positioned(
                    top: 20,
                    left: 15,
                    right: 15,
                    child: SlideTransition(
                      position: _riderCardOffsetAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delivery_dining, color: Colors.white)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Rider: $riderName", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(estimatedTime > 0 ? "$estimatedTime mins away" : "Arrived", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: _makeCall, icon: const Icon(Icons.phone, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (!hasRider && status != "Delivered" && status != "Cancelled")
                  Positioned(
                    top: 20,
                    left: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Waiting for rider to accept...",
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 15),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _step(Icons.check_circle, "Order Received", "We have received your order", status != "Cancelled"),
                          _step(Icons.agriculture, "Farm Accepted", "Nearest farm is preparing", status == "Farmer Accepted" || status == "Picked Up" || status == "On the way" || status == "Arrived" || status == "Delivered"),
                          _step(Icons.inventory, "Picked Up", "Rider has picked up items", status == "Picked Up" || status == "On the way" || status == "Arrived" || status == "Delivered"),
                          _step(Icons.local_shipping, "On the way", "Rider is heading to you", status == "On the way" || status == "Arrived" || status == "Delivered"),
                          _step(Icons.home, "Delivered", "Enjoy your produce", status == "Arrived" || status == "Delivered", isLast: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_canCancelOrder())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _cancelOrder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleBack,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("Back to Shopping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "No active orders",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D25),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You don't have any active orders right now.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Start Shopping",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(IconData icon, String title, String subtitle, bool done, {bool isLast = false}) {
    return Row(
      children: [
        Column(
          children: [
            Icon(icon, color: done ? Colors.green : Colors.grey),
            if (!isLast) Container(width: 2, height: 30, color: done ? Colors.green : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}