import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/research_submission_model.dart';
import '../utils/db_seeder.dart';

import '../models/price_request_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrders() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  // ... (keep existing methods)

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
    // 1. Update the price_request status
    await _firestore.collection('price_requests').doc(request.id).update({'status': 'approved'});

    // 2. Update the product in 'products' collection
    await _firestore.collection('products').doc(request.productId).update({
      'price': request.newPrice,
      'unit': request.newUnit,
    });

    // 3. Update the product in 'master_catalog' if it exists there
    final masterSnap = await _firestore
        .collection('master_catalog')
        .where('farmerUid', isEqualTo: request.farmerUid)
        .where('title', isEqualTo: request.productName)
        .get();

    for (var doc in masterSnap.docs) {
      await doc.reference.update({
        'price': request.newPrice.toString(),
        'unit': request.newUnit,
      });
    }

    // 4. Notify the farmer
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

  Stream<List<Product>> getPendingProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id)).toList();
    });
  }

  Future<void> approveProduct(Product product) async {
    // 1. Update product status in 'products' collection
    await _firestore.collection('products').doc(product.id).update({'status': 'approved'});

    // 2. Check if it's already in 'master_catalog'
    final masterSnap = await _firestore
        .collection('master_catalog')
        .where('title', isEqualTo: product.title)
        .get();

    if (masterSnap.docs.isEmpty) {
      // Add to master_catalog if unique
      await _firestore.collection('master_catalog').add({
        'name': product.title,
        'title': product.title,
        'price': double.tryParse(product.price) ?? 0,
        'unit': product.unit,
        'image': product.image,
        'imageUrl': product.image,
        'description': product.description,
        'longDescription': product.longDescription,
        'category': product.category ?? 'General',
        'farmerUid': product.farmerUid,
        'farmName': product.farmName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Notify farmer
    if (product.farmerUid != null) {
      await _firestore.collection('users').doc(product.farmerUid).collection('notifications').add({
        'title': 'Product Approved',
        'body': 'Your product "${product.title}" has been approved and added to the catalog.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> rejectProduct(String productId, String? farmerUid, String title) async {
    await _firestore.collection('products').doc(productId).update({'status': 'rejected'});
    
    if (farmerUid != null) {
      await _firestore.collection('users').doc(farmerUid).collection('notifications').add({
        'title': 'Product Rejected',
        'body': 'Your product "$title" was not approved by admin.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
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

  Future<void> seedDatabase({List<String>? selectedProductNames}) async {
    await seedProducts(selectedProductNames: selectedProductNames);
  }
}
