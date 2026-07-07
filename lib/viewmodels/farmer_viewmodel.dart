import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/repositories/farmer_repository.dart';
import 'package:farmtech_agridirect/models/order_model.dart';
import 'package:farmtech_agridirect/models/product.dart';

class FarmerViewModel extends ChangeNotifier {
  final FarmerRepository _repository = FarmerRepository();

  Map<String, dynamic>? _farmerData;
  bool _loading = true;
  int _currentIndex = 0;

  Map<String, dynamic>? get farmerData => _farmerData;
  bool get loading => _loading;
  int get currentIndex => _currentIndex;
  String get uid => _repository.currentUid ?? '';

  FarmerViewModel() {
    loadFarmerData();
  }

  Future<void> loadFarmerData() async {
    _loading = true;
    notifyListeners();
    _farmerData = await _repository.getFarmerData();
    _loading = false;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Stream<List<OrderModel>> getNewOrders() => _repository.getNewOrders();
  
  Stream<List<OrderModel>> getFarmerOrders() => _repository.getFarmerOrders(uid);
  
  Stream<List<Product>> getFarmerProducts() => _repository.getFarmerProducts(uid);

  Future<void> acceptOrder(String orderId, double? lat, double? lng, String farmName) async {
    await _repository.acceptOrder(orderId, {
      'status': 'Farmer Accepted',
      'farmerUid': uid,
      'farmName': farmName,
      'farmerLat': lat,
      'farmerLng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReadyForPickup(String orderId, String? customerId, String farmName) async {
    await _repository.updateOrderStatus(orderId, 'Awaiting Pickup');

    if (customerId != null) {
      await _repository.addNotification(customerId, {
        'title': 'Order Ready for Pickup',
        'body': 'Your order has been packed and is ready for the delivery person.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'delivery_status',
        'status': 'Awaiting Pickup',
        'orderId': orderId,
      });
    }

    final riderIds = await _repository.getDeliveryPersonIds();
    for (var rId in riderIds) {
      await _repository.addNotification(rId, {
        'title': 'New Pickup Available!',
        'body': 'A package is ready for pickup at $farmName.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'pickup_alert',
        'orderId': orderId,
      });
    }
  }

  Future<void> addProduct(Map<String, dynamic> data) => _repository.addProduct(data);
  
  Future<void> requestPriceUpdate(Map<String, dynamic> data) => _repository.requestPriceUpdate(data);
  
  Future<void> deleteProduct(String id) => _repository.deleteProduct(id);

  Future<void> updateProfileImage(String url) async {
    await _repository.updateProfileImage(uid, url);
    await loadFarmerData();
  }

  Future<void> updateFarmLocation(String address, double lat, double lng) async {
    await _repository.updateFarmLocation(uid, address, lat, lng);
    await loadFarmerData();
  }

  void logout(BuildContext context, Widget loginScreen) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => loginScreen),
      (route) => false,
    );
  }
}
