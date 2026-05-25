import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user_data.dart';
import '../location_service.dart';
import '../navigation_screen.dart';

class OrderScreen extends StatefulWidget {
  final String? orderId;
  final VoidCallback? onBackToHome;
  const OrderScreen({super.key, this.orderId, this.onBackToHome});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _calculateTrackingDetails();
    _setupAnimation();
    _startTrackingSimulation();
    _listenToOrderUpdates();
  }

  void _listenToOrderUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.orderId == null) return;

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          status = data['status'] ?? status;
        });
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

    _riderCardController.forward();
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
    if (!UserData.hasAddress) return;

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
            lat, lng, UserData.defaultLat!, UserData.defaultLng!
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

    if (UserData.hasAddress) {
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

  void _handleBack() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavigationScreen(userName: "User")),
        (route) => false,
      );
    }
  }

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:+9779800000000');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    zoom: 12,
                  ),
                  onMapCreated: _onMapCreated,
                  styleString: "https://tiles.openfreemap.org/styles/liberty",
                ),
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
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
                                const Text("Rider: Suresh K.", style: TextStyle(fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _step(Icons.check_circle, "Order Received", "We have received your order", true),
                  _step(Icons.local_shipping, "On the way", "Rider is heading to you", status == "On the way" || status == "Arrived"),
                  _step(Icons.home, "Delivered", "Enjoy your fresh produce!", status == "Arrived", isLast: true),
                  const Spacer(),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ],
    );
  }
}
