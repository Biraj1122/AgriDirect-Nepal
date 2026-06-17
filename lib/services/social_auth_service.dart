import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // More stable for Web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        await _updateUserData(userCredential.user);
        return userCredential;
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        await _updateUserData(userCredential.user);
        return userCredential;
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // Use Firebase Popup for Web to avoid plugin issues
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(facebookProvider);
        await _updateUserData(userCredential.user);
        return userCredential;
      } else {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final AuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          await _updateUserData(userCredential.user);
          return userCredential;
        }
        return null;
      }
    } catch (e) {
      debugPrint("Facebook Sign-In Error: $e");
      rethrow;
    }
  }

  // Update or create user data in Firestore
  Future<void> _updateUserData(User? user) async {
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': user.displayName ?? "User",
        'role': 'Customer', // Default role for social login
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'phone': user.phoneNumber ?? "",
      });
    } else {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }
}
