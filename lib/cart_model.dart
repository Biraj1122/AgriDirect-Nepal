import 'package:flutter/material.dart';
import 'product.dart';

class CartModel extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  void add(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  double get subtotal {
    return _items.fold(
      0,
          (sum, item) => sum + double.parse(item.price),
    );
  }

  double get deliveryFee => _items.isEmpty ? 0 : 40;

  double get total => subtotal + deliveryFee;
}

final cartModel = CartModel();