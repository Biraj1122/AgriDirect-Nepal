import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmtech_agridirect/repositories/shop_repository.dart';
import 'package:farmtech_agridirect/models/product.dart';

class ShopViewModel extends ChangeNotifier {
  final ShopRepository _repository = ShopRepository();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Product> _allProducts = [];
  List<Map<String, dynamic>> _favourites = [];
  bool _loading = true;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get loading => _loading;
  List<Map<String, dynamic>> get favourites => _favourites;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  ShopViewModel() {
    _init();
  }

  void _init() {
    if (userId != null) {
      _repository.getUserFavourites(userId!).listen((favs) {
        _favourites = favs;
        notifyListeners();
      });
    }
    
    _repository.getMasterCatalog().listen((prods) {
      _allProducts = prods;
      _loading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<Product> get filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || p.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Stream<List<String>> getCategories() => _repository.getCategories();

  bool isFavourite(Product product) {
    return _favourites.any((f) => f['title'] == product.title);
  }

  Future<void> toggleFavourite(Product product) async {
    if (userId == null) return;
    final currentlyFav = isFavourite(product);
    await _repository.toggleFavourite(userId!, product.toMap(), currentlyFav);
  }
}
