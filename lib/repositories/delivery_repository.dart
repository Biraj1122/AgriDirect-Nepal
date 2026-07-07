import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserLocation(String uid, double lat, double lng) {
    return _firestore.collection('users').doc(uid).update({
      'lat': lat,
      'lng': lng,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) {
    return _firestore.collection('users').doc(uid).update({'isOnline': isOnline});
  }

  Future<void> updateUserProfileImage(String uid, String url) {
    return _firestore.collection('users').doc(uid).update({'profileImageUrl': url});
  }

  Future<void> updateRiderAddress(String uid, String address, double lat, double lng) {
    return _firestore.collection('users').doc(uid).update({
      'address': address,
      'lat': lat,
      'lng': lng,
    });
  }

  Stream<QuerySnapshot> getActiveOrderStream(String uid) {
    return _firestore
        .collection('orders')
        .where('deliveryId', isEqualTo: uid)
        .where('status', whereIn: ['Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived'])
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getAvailableOrdersStream() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Farmer Accepted')
        .where('deliveryId', isNull: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getOrdersByStatusStream(List<String> statuses) {
    return _firestore
        .collection('orders')
        .where('status', whereIn: statuses)
        .snapshots();
  }

  Stream<QuerySnapshot> getHistoryOrdersStream(String uid) {
    return _firestore
        .collection('orders')
        .where('deliveryId', isEqualTo: uid)
        .where('status', whereIn: ['Delivered', 'Cancelled'])
        .snapshots();
  }

  Future<void> acceptOrder(String orderId, String uid, String name, String phone) {
    return _firestore.collection('orders').doc(orderId).update({
      'deliveryId': uid,
      'deliveryName': name,
      'deliveryPhone': phone,
      'status': 'Awaiting Pickup',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unassignOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).update({
      'deliveryId': null,
      'deliveryName': null,
      'deliveryPhone': null,
      'status': 'Farmer Accepted',
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();
}
