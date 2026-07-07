import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:farmtech_agridirect/repositories/delivery_repository.dart';

class DeliveryViewModel extends ChangeNotifier {
  final DeliveryRepository _repository = DeliveryRepository();

  int _tabIndex = 0;
  LatLng? _driverPos;
  Map<String, dynamic>? _activeOrderData;

  int get tabIndex => _tabIndex;
  LatLng? get driverPos => _driverPos;
  Map<String, dynamic>? get activeOrderData => _activeOrderData;
  String? get uid => _repository.currentUser?.uid;

  void setTabIndex(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  void updateDriverPos(LatLng pos) {
    _driverPos = pos;
    notifyListeners();
    if (uid != null) {
      _repository.updateUserLocation(uid!, pos.latitude, pos.longitude);
    }
  }

  void setActiveOrder(Map<String, dynamic>? data) {
    _activeOrderData = data;
    notifyListeners();
  }

  Stream<DocumentSnapshot>? get userStream => uid != null ? _repository.getUserStream(uid!) : null;

  Stream<QuerySnapshot> get activeOrderStream => uid != null 
      ? _repository.getActiveOrderStream(uid!) 
      : const Stream.empty();

  Stream<QuerySnapshot> get availableOrdersStream => _repository.getAvailableOrdersStream();

  Stream<QuerySnapshot> getOrdersByStatuses(List<String> statuses) => _repository.getOrdersByStatusStream(statuses);

  Future<void> acceptOrder(String orderId) async {
    if (uid == null) return;
    final doc = await _repository.getUserDoc(uid!);
    final name = doc.data() is Map ? (doc.data() as Map)['fullName'] ?? 'Rider' : 'Rider';
    final phone = doc.data() is Map ? (doc.data() as Map)['phone'] ?? '' : '';
    await _repository.acceptOrder(orderId, uid!, name, phone);
  }

  Future<void> unassignOrder(String orderId) => _repository.unassignOrder(orderId);

  Future<void> updateOrderStatus(String orderId, String? currentStatus) async {
    String next = 'Delivered';
    if (currentStatus == 'Farmer Accepted' || currentStatus == 'Awaiting Pickup') {
      next = 'Picked Up';
    } else if (currentStatus == 'Picked Up') {
      next = 'On the way';
    } else if (currentStatus == 'On the way') {
      next = 'Arrived';
    } else if (currentStatus == 'Arrived') {
      next = 'Confirm Received';
    }
    await _repository.updateOrderStatus(orderId, next);
  }

  Future<void> updateOnlineStatus(bool val) async {
    if (uid != null) await _repository.updateOnlineStatus(uid!, val);
  }

  Future<void> updateProfileImage(String url) async {
    if (uid != null) await _repository.updateUserProfileImage(uid!, url);
  }

  Future<void> updateRiderAddress(String address, double lat, double lng) async {
    if (uid != null) await _repository.updateRiderAddress(uid!, address, lat, lng);
  }

  Future<void> logout() => _repository.signOut();
}
