
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_screen.dart';
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
  Symbol? customerSymbol;
  Symbol? farmerSymbol;
  Circle? riderCircle;
  Circle? customerCircle;
  Circle? farmerCircle;
  Line? routeLine;
  LatLng? riderPosition;
  LatLng? customerPosition;
  LatLng? farmerPosition;
  Timer? _trackingTimer;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _riderLocationSubscription;

  bool _isLoading = true;
  String? _activeOrderId;
  bool _noActiveOrder = false;
  bool _isConfirmingReceipt = false;

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
        // Fetching without orderBy and sorting in memory to avoid index requirements
        final query = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: ['Pending Farmer', 'Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'])
            .limit(10) // Get recent few
            .get();

        if (query.docs.isNotEmpty) {
          // Sort by createdAt descending in memory
          final docs = query.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          
          _activeOrderId = docs.first.id;
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
        final newDeliveryId = data['deliveryId'];
        
        // Ensure we get rider phone from order or their user doc
        String? newRiderPhone = data['deliveryPhone'];
        
        final double? custLat = (data['customerLat'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble();
        final double? custLng = (data['customerLng'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble();
        final double? fLat = (data['farmerLat'] as num?)?.toDouble();
        final double? fLng = (data['farmerLng'] as num?)?.toDouble();

        if (widget.orderId == null && (newStatus == 'Delivered' || newStatus == 'Cancelled')) {
          setState(() {
            _noActiveOrder = true;
          });
          return;
        }

        bool shouldStartRiderTracking = false;
        if (deliveryId != newDeliveryId && newDeliveryId != null) {
          shouldStartRiderTracking = true;
          // If phone is missing in order, we'll get it from user doc in _listenToRiderLocation
        }

        setState(() {
          status = newStatus;
          riderName = newRiderName;
          if (newRiderPhone != null) riderPhone = newRiderPhone;
          deliveryId = newDeliveryId;
          if (custLat != null && custLng != null) {
            customerPosition = LatLng(custLat, custLng);
            _updateCustomerMarker();
          }
          if (fLat != null && fLng != null) {
            farmerPosition = LatLng(fLat, fLng);
            _updateFarmerMarker();
          }
        });

        if (shouldStartRiderTracking) {
          _listenToRiderLocation(newDeliveryId!);
        }
      }
    });
  }

  void _listenToRiderLocation(String riderId) {
    _riderLocationSubscription?.cancel();
    _riderLocationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(riderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final phone = data['phone']?.toString();

        if (phone != null && riderPhone == null) {
          setState(() => riderPhone = phone);
        }

        if (lat != null && lng != null) {
          final newPos = LatLng(lat, lng);
          setState(() {
            riderPosition = newPos;
            final targetLat = customerPosition?.latitude ?? UserData.defaultLat;
            final targetLng = customerPosition?.longitude ?? UserData.defaultLng;

            if (targetLat != null && targetLng != null) {
              distance = _locationService.calculateDistance(
                lat, lng, targetLat, targetLng,
              );
              estimatedTime = (distance * 2).round();
            }
          });
          _updateRiderMarker();

          if (_riderCardController.status == AnimationStatus.dismissed) {
            _riderCardController.forward();
          }
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

  // Removed simulation logic in favor of real tracking

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _addMarkers();
  }

  Future<void> _addMarkers() async {
    if (mapController == null) return;

    _updateCustomerMarker();
    _updateFarmerMarker();
    _updateRiderMarker();
  }

  void _updateRiderMarker() {
    if (mapController == null || riderPosition == null) return;

    if (riderSymbol == null) {
      // First time adding rider
      mapController!.addCircle(CircleOptions(
        geometry: riderPosition!,
        circleRadius: 10.0,
        circleColor: "#2E7D32",
        circleStrokeWidth: 3.0,
        circleStrokeColor: "#FFFFFF",
      )).then((c) => riderCircle = c);

      mapController!.addSymbol(SymbolOptions(
        geometry: riderPosition!,
        textField: "Rider is Here",
        textSize: 12,
        textColor: "#2E7D32",
        textHaloColor: "#FFFFFF",
        textHaloWidth: 2.0,
        textOffset: const Offset(0, -1.8),
        textAnchor: "bottom",
      )).then((s) {
        riderSymbol = s;
        _fitCameraToMarkers();
      });
    } else {
      // Update existing rider marker
      mapController!.updateSymbol(riderSymbol!, SymbolOptions(
        geometry: riderPosition!,
      ));
      if (riderCircle != null) {
        mapController!.updateCircle(riderCircle!, CircleOptions(
          geometry: riderPosition!,
        ));
      }
    }
    _updateRouteLine();
    _fitCameraToMarkers();
  }

  void _fitCameraToMarkers() {
    if (mapController == null || customerPosition == null || riderPosition == null) return;

    List<LatLng> points = [riderPosition!, customerPosition!];
    if (farmerPosition != null) points.add(farmerPosition!);

    double south = points[0].latitude;
    double north = points[0].latitude;
    double west = points[0].longitude;
    double east = points[0].longitude;

    for (var p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
        left: 80,
        right: 80,
        top: 120,
        bottom: 250,
      ),
    );
  }

  void _updateRouteLine() async {
    if (mapController == null || riderPosition == null || customerPosition == null) return;
    if (status != "On the way" && status != "Arrived" && status != "Picked Up") return;

    final routeData = await _locationService.getRouteData(
      riderPosition!.latitude,
      riderPosition!.longitude,
      customerPosition!.latitude,
      customerPosition!.longitude,
    );

    final List<dynamic> points = routeData['points'];
    final lineCoords = points.map((p) => LatLng(p[0], p[1])).toList();

    if (!mounted) return;

    if (routeLine == null) {
      mapController!.addLine(
        LineOptions(
          geometry: lineCoords,
          lineColor: "#2E7D32",
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      ).then((l) => routeLine = l);
    } else {
      mapController!.updateLine(routeLine!, LineOptions(geometry: lineCoords));
    }
  }

  void _updateCustomerMarker() {
    final lat = customerPosition?.latitude ?? UserData.defaultLat;
    final lng = customerPosition?.longitude ?? UserData.defaultLng;

    if (mapController == null || lat == null || lng == null) return;
    final pos = LatLng(lat, lng);

    if (customerSymbol == null) {
      mapController!.addCircle(CircleOptions(
        geometry: pos,
        circleRadius: 10.0,
        circleColor: "#D32F2F",
        circleStrokeWidth: 3.0,
        circleStrokeColor: "#FFFFFF",
      )).then((c) => customerCircle = c);

      mapController!.addSymbol(SymbolOptions(
        geometry: pos,
        textField: "My Location",
        textSize: 12,
        textColor: "#D32F2F",
        textHaloColor: "#FFFFFF",
        textHaloWidth: 2.0,
        textOffset: const Offset(0, -1.8),
        textAnchor: "bottom",
      )).then((s) {
        customerSymbol = s;
        _fitCameraToMarkers();
      });
    } else {
      mapController!.updateSymbol(customerSymbol!, SymbolOptions(
        geometry: pos,
      ));
      if (customerCircle != null) {
        mapController!.updateCircle(customerCircle!, CircleOptions(
          geometry: pos,
        ));
      }
    }
  }

  void _updateFarmerMarker() {
    if (mapController != null && farmerPosition != null) {
      if (farmerSymbol == null) {
        mapController!.addCircle(CircleOptions(
          geometry: farmerPosition!,
          circleRadius: 10.0,
          circleColor: "#FFA000",
          circleStrokeWidth: 3.0,
          circleStrokeColor: "#FFFFFF",
        )).then((c) => farmerCircle = c);

        mapController!.addSymbol(SymbolOptions(
          geometry: farmerPosition!,
          textField: "Farmer/Hub",
          textSize: 12,
          textColor: "#FFA000",
          textHaloColor: "#FFFFFF",
          textHaloWidth: 2.0,
          textOffset: const Offset(0, -1.8),
          textAnchor: "bottom",
        )).then((s) {
          farmerSymbol = s;
          _fitCameraToMarkers();
        });
      } else {
        mapController!.updateSymbol(farmerSymbol!, SymbolOptions(
          geometry: farmerPosition!,
        ));
        if (farmerCircle != null) {
          mapController!.updateCircle(farmerCircle!, CircleOptions(
            geometry: farmerPosition!,
          ));
        }
      }
    }
  }

  String _getStatusMessage() {
    if (status == 'Pending Farmer') return "Waiting for farm to accept your order...";
    if (status == 'Farmer Accepted') return "Farm is preparing your fresh items...";
    if (status == 'Awaiting Pickup') return "Items packed! Waiting for rider pickup...";
    if (status == 'Picked Up') return "Rider has picked up your order!";
    if (status == 'On the way') return "Rider is heading to your location...";
    if (status == 'Arrived') return "Rider has arrived! Please collect your order.";
    return "Processing your order...";
  }

  @override
  void dispose() {
    _riderCardController.dispose();
    _trackingTimer?.cancel();
    _orderSubscription?.cancel();
    _riderLocationSubscription?.cancel();
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
    return (status == 'Pending Farmer' || status == 'Farmer Accepted');
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

  Future<void> _confirmReceipt() async {
    if (_activeOrderId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Received Order", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Confirm that you have received the items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Received", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isConfirmingReceipt = true);
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(_activeOrderId)
            .update({
          'status': 'Delivered',
          'receivedAt': FieldValue.serverTimestamp(),
        });

        if (deliveryId != null) {
          await FirebaseFirestore.instance.collection('users').doc(deliveryId).collection('notifications').add({
            'title': 'Delivery Confirmed',
            'body': 'Customer has confirmed receipt of order #${_activeOrderId!.substring(0, 6)}',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order completed! Thank you."), backgroundColor: Colors.green),
          );
          _handleBack();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isConfirmingReceipt = false);
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
        actions: [
          if (_activeOrderId != null)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded, color: Colors.green),
              onPressed: () async {
                final doc = await FirebaseFirestore.instance.collection('orders').doc(_activeOrderId).get();
                if (doc.exists && mounted) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: data)),
                  );
                }
              },
              tooltip: "View Details",
            ),
          const SizedBox(width: 8),
        ],
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

                if (status != "Delivered" && status != "Cancelled")
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
                      child: Row(
                        children: [
                          if (!hasRider && status == 'Pending Farmer')
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                            )
                          else
                            const Icon(Icons.info_outline, color: Colors.green),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusMessage(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () async {
                                    final doc = await FirebaseFirestore.instance.collection('orders').doc(_activeOrderId).get();
                                    if (doc.exists && mounted) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      data['id'] = doc.id;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: data)),
                                      );
                                    }
                                  },
                                  child: const Text("View order details", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (hasRider)
                  Positioned(
                    top: 90,
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
                          _step(Icons.agriculture, "Farm Accepted", "Nearest farm is preparing", status != "Pending Farmer" && status != "Cancelled"),
                          _step(Icons.inventory, "Picked Up", "Rider has picked up items", status == "Picked Up" || status == "On the way" || status == "Arrived" || status == "Delivered"),
                          _step(Icons.local_shipping, "On the way", "Rider is heading to you", status == "On the way" || status == "Arrived" || status == "Delivered"),
                          _step(Icons.home, "Delivered", "Enjoy your produce", status == "Delivered", isLast: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (status == "Arrived")
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your rider has arrived! Please collect your items. Once the rider marks as delivered, you can confirm receipt here.",
                                style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (status == "Confirm Received")
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isConfirmingReceipt ? null : _confirmReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isConfirmingReceipt
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("I have Received my Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
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