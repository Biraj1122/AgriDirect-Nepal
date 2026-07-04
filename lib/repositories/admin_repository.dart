import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/models/order_model.dart';
import 'package:farmtech_agridirect/models/product.dart';
import 'package:farmtech_agridirect/models/user_model.dart';
import 'package:farmtech_agridirect/models/announcement_model.dart';
import 'package:farmtech_agridirect/models/research_submission_model.dart';
import 'package:farmtech_agridirect/utils/db_seeder.dart';
import 'package:farmtech_agridirect/models/price_request_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrders() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<PriceRequestModel>> getPriceRequests() {
    return _firestore
        .collection('price_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PriceRequestModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> approvePriceRequest(PriceRequestModel request) async {
    await _firestore.collection('price_requests').doc(request.id).update({'status': 'approved'});

    await _firestore.collection('products').doc(request.productId).update({
      'price': request.newPrice,
      'unit': request.newUnit,
    });

    final masterSnap = await _firestore
        .collection('master_catalog')
        .where('farmerUid', isEqualTo: request.farmerUid)
        .where('title', isEqualTo: request.productName)
        .get();

    for (var doc in masterSnap.docs) {
      await doc.reference.update({
        'price': request.newPrice,
        'unit': request.newUnit,
      });
    }

    await _firestore.collection('users').doc(request.farmerUid).collection('notifications').add({
      'title': 'Price Update Approved',
      'body': 'Your request to update ${request.productName} has been approved.',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> declinePriceRequest(String requestId, String farmerUid, String productName) async {
    await _firestore.collection('price_requests').doc(requestId).update({'status': 'declined'});

    await _firestore.collection('users').doc(farmerUid).collection('notifications').add({
      'title': 'Price Update Declined',
      'body': 'Your request to update $productName was declined by admin.',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _firestore.collection('orders').doc(id).update({'status': status});
  }

  Stream<List<Product>> getProducts() {
    return _firestore.collection('master_catalog').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), docId: doc.id)).toList();
    });
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _firestore.collection('master_catalog').add(productData);
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('master_catalog').doc(id).delete();
  }

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    await _firestore.collection('settings').doc('announcement').set(announcement.toMap());
  }

  Stream<List<ResearchSubmissionModel>> getResearchSubmissions() {
    return _firestore.collection('research_submissions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ResearchSubmissionModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendGlobalNotification(String title, String body) async {
    final users = await _firestore.collection('users').get();
    for (var user in users.docs) {
      await user.reference.collection('notifications').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> seedDatabase() async {
    await seedProducts();
  }
}
