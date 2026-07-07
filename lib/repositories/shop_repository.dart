import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/models/product.dart';

class ShopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Product>> getMasterCatalog() {
    return _firestore.collection('master_catalog').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return Product.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  Stream<List<String>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snap) {
      return snap.docs.map((doc) => (doc.data()['name'] ?? '').toString()).toList();
    });
  }

  Future<void> toggleFavourite(String userId, Map<String, dynamic> productData, bool isCurrentlyFavourite) async {
    final favRef = _firestore.collection('users').doc(userId).collection('favourites');

    if (isCurrentlyFavourite) {
      final snap = await favRef.where('title', isEqualTo: productData['title']).get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } else {
      await favRef.add({
        ...productData,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getUserFavourites(String userId) {
    return _firestore.collection('users').doc(userId).collection('favourites').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
