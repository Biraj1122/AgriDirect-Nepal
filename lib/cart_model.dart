import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product.dart';

class CartModel extends ChangeNotifier {
  final List<Product> _items = [];
  double _distanceInKm = 0;
  bool _isLoading = false;

  List<Product> get items => _items;
  bool get isLoading => _isLoading;

  CartModel() {
    // Listen for auth changes to load/clear cart
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchCartFromFirestore();
      } else {
        _items.clear();
        notifyListeners();
      }
    });
  }

  Future<void> fetchCartFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      _items.clear();
      for (var doc in snapshot.docs) {
        _items.add(Product.fromMap(doc.data()));
      }
    } catch (e) {
      debugPrint("Error fetching cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Product product) async {
    _items.add(product);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .add(product.toMap());
      } catch (e) {
        debugPrint("Error adding to Firestore cart: $e");
      }
    }
  }

  Future<void> removeAt(int index) async {
    final removedProduct = _items.removeAt(index);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .where('title', isEqualTo: removedProduct.title)
            .where('price', isEqualTo: removedProduct.price)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.delete();
        }
      } catch (e) {
        debugPrint("Error removing from Firestore cart: $e");
      }
    }
  }

  void setDistance(double distance) {
    _distanceInKm = distance;
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _distanceInKm = 0;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');
        final snapshots = await collection.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error clearing Firestore cart: $e");
      }
    }
  }

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + double.parse(item.price),
    );
  }

  double get deliveryFee {
    if (_items.isEmpty) return 0;
    // Base fee 40 + 5 per km
    return 40 + (_distanceInKm * 5);
  }

  double get total => subtotal + deliveryFee;
}

final cartModel = CartModel();
