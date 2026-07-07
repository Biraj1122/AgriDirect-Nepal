import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmtech_agridirect/models/order_model.dart';
import 'package:farmtech_agridirect/models/product.dart';

class FarmerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> getFarmerData() async {
    if (currentUid == null) return null;
    final doc = await _firestore.collection('users').doc(currentUid).get();
    return doc.exists ? doc.data() : null;
  }

  Stream<List<OrderModel>> getNewOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Pending Farmer')
        .snapshots()
        .map((snap) => snap.docs
            .where((d) {
              final data = d.data();
              return data['farmerUid'] == null || data['farmerUid'] == "";
            })
            .map((d) => OrderModel.fromFirestore(d))
            .toList());
  }

  Stream<List<OrderModel>> getFarmerOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('farmerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  Stream<List<Product>> getFarmerProducts(String uid) {
    return _firestore
        .collection('products')
        .where('farmerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Product.fromMap(d.data(), docId: d.id)).toList());
  }

  Future<void> acceptOrder(String orderId, Map<String, dynamic> updateData) async {
    await _firestore.collection('orders').doc(orderId).update(updateData);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    await _firestore.collection('products').add(data);
  }

  Future<void> requestPriceUpdate(Map<String, dynamic> data) async {
    await _firestore.collection('price_requests').add(data);
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  Future<void> updateProfileImage(String uid, String url) async {
    await _firestore.collection('users').doc(uid).update({'profileImageUrl': url});
  }

  Future<void> updateFarmLocation(String uid, String address, double lat, double lng) async {
    await _firestore.collection('users').doc(uid).update({
      'farmLocation': address,
      'farmLat': lat,
      'farmLng': lng,
    });
  }

  Future<void> addNotification(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).collection('notifications').add(data);
  }

  Future<List<String>> getDeliveryPersonIds() async {
    final ridersSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Delivery Person')
        .get();
    return ridersSnap.docs.map((d) => d.id).toList();
  }
}
