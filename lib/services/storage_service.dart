import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service to handle images without using Firebase Storage (No Premium Required)
/// Stores images as Base64 strings directly in Firestore documents.
class StorageService {
  
  /// Converts image to Base64 string to store in Firestore Database directly.
  Future<String?> uploadImage(XFile xFile, String folder) async {
    try {
      final bytes = await xFile.readAsBytes();
      
      // Check size (Firestore has a 1MB limit per document)
      if (bytes.length > 900000) {
        debugPrint('Image too large for free tier. Please compress more.');
        return null; 
      }

      final String ext = p.extension(xFile.name).toLowerCase().replaceFirst('.', '');
      final String mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';
      
      // This string will be saved in the 'image' or 'imageUrl' field of your Firestore document
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Error converting image to Base64: $e');
      return null;
    }
  }

  // Compatibility aliases
  Future<String?> uploadToFirebase(XFile xFile, String folder) => uploadImage(xFile, folder);
  Future<String?> uploadToS3(XFile xFile, String folder) => uploadImage(xFile, folder);
  
  /// Placeholder for cleanup
  Future<void> cleanup(XFile xFile) async {}
}
