import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  Future<User?> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _repository.signIn(email, password);
      _setLoading(false);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _setLoading(false);
      return null;
    } catch (e) {
      _error = "An unexpected error occurred: $e";
      _setLoading(false);
      return null;
    }
  }

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _repository.getUserDoc(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> handleMasterAdmin(User user, String email) async {
    await _repository.createUserDoc(user.uid, {
      'email': email,
      'role': 'Admin',
      'fullName': 'Super Admin',
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email': return "The email address is badly formatted.";
      case 'user-disabled': return "This user account has been disabled.";
      case 'user-not-found': return "No user found with this email.";
      case 'wrong-password': return "Incorrect password. Please try again.";
      case 'invalid-credential': return "Incorrect email or password.";
      case 'too-many-requests': return "Too many attempts. Please try again later.";
      case 'network-request-failed': return "Network error. Please check your connection.";
      default: return "Login failed. Please try again.";
    }
  }
}
