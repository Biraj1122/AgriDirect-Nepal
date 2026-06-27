import 'package:flutter/material.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _distanceInKm = 0;

  List<CartItem> get items => _items;

  void add(Product product) {
    // Try to find if product already exists in cart
    final index = _items.indexWhere((item) => 
      (item.product.id != null && item.product.id == product.id) || 
      (item.product.title == product.title && item.product.price == product.price)
    );

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void increment(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrement(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
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
      (sum, item) => sum + ((double.tryParse(item.product.price) ?? 0) * item.quantity),
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