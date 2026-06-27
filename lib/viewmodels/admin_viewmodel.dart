import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/admin_repository.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../models/research_submission_model.dart';
import '../models/announcement_model.dart';
import '../models/price_request_model.dart';
import 'dart:developer' as developer;

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();

  int _currentIndex = 0;
  bool _isCheckingRole = true;
  String? _adminEmail;
  bool _showPendingOnly = false;

  int get currentIndex => _currentIndex;
  bool get isCheckingRole => _isCheckingRole;
  String? get adminEmail => _adminEmail;
  bool get showPendingOnly => _showPendingOnly;

  AdminViewModel() {
    _adminEmail = FirebaseAuth.instance.currentUser?.email;
    _checkRole();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    _showPendingOnly = false;
    notifyListeners();
  }

  void setShowPendingOnly(bool value) {
    _showPendingOnly = value;
    notifyListeners();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isCheckingRole = false;
      notifyListeners();
      return;
    }

    try {
      // Hardcoded check for super admin
      if (user.email == 'agrifarmadmin@gmail.com') {
        _isCheckingRole = false;
        notifyListeners();
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final role = doc.data()?['role'];
        if (role == 'Admin') {
          _isCheckingRole = false;
          notifyListeners();
          return;
        }
      }
      
      // If not admin, logout or stay in loading state (should probably logout)
      developer.log("User ${user.email} is not an admin. Role: ${doc.data()?['role']}");
      _isCheckingRole = false; // Stop loading even if not admin to show unauthorized or redirect
      notifyListeners();
    } catch (e) {
      developer.log("Admin check error: $e");
      _isCheckingRole = false;
      notifyListeners();
    }
  }

  Stream<List<OrderModel>> getOrders() => _repository.getOrders();
  Stream<List<Product>> getProducts() => _repository.getProducts();
  Stream<List<UserModel>> getUsers() => _repository.getUsers();
  Stream<List<ResearchSubmissionModel>> getResearchSubmissions() => _repository.getResearchSubmissions();
  Stream<List<PriceRequestModel>> getPriceRequests() => _repository.getPriceRequests();

  Future<void> approvePriceRequest(PriceRequestModel request) async {
    await _repository.approvePriceRequest(request);
  }

  Future<void> declinePriceRequest(PriceRequestModel request) async {
    await _repository.declinePriceRequest(request.id, request.farmerUid, request.productName);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _repository.updateOrderStatus(id, status);
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _repository.addProduct(productData);
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
  }

  Future<void> updateAnnouncement(String title, String content) async {
    await _repository.updateAnnouncement(AnnouncementModel(title: title, content: content));
  }

  Future<void> sendGlobalNotification(String title, String body) async {
    await _repository.sendGlobalNotification(title, body);
  }

  Future<void> seedDatabase() async {
    await _repository.seedDatabase();
  }

  void logout(BuildContext context, Widget loginScreen) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => loginScreen),
      (route) => false,
    );
  }
}
