import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'product.dart';
import 'user_data.dart';

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
    if (UserData.defaultLat == null || UserData.defaultLng == null) return 0;

    // Set to store unique farm UIDs and their distances
    final Set<String> uniqueFarms = {};
    double totalDeliveryFee = 0;

    for (var item in _items) {
      final product = item.product;
      if (product.farmerUid != null && !uniqueFarms.contains(product.farmerUid)) {
        uniqueFarms.add(product.farmerUid!);

        // Calculate distance from user to this specific farm
        double distance = 0;
        if (product.farmerLat != null && product.farmerLng != null) {
          distance = Geolocator.distanceBetween(
                UserData.defaultLat!,
                UserData.defaultLng!,
                product.farmerLat!,
                product.farmerLng!,
              ) / 1000;
        } else {
          // Fallback to HQ distance if farm coordinates are missing
          distance = UserData.distanceToHq;
        }

        // Rs. 15 per km + Rs. 40 base fee
        totalDeliveryFee += 40 + (distance * 15);
      }
    }

    return totalDeliveryFee;
  }

  double get total => subtotal + deliveryFee;
}

final cartModel = CartModel();