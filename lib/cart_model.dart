import 'package:flutter/material.dart';
import 'product.dart';

class CartModel extends ChangeNotifier {
  final List<Product> _items = [];
  double _distanceInKm = 0;

  List<Product> get items => _items;

  void add(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void setDistance(double distance) {
    _distanceInKm = distance;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _distanceInKm = 0;
    notifyListeners();
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