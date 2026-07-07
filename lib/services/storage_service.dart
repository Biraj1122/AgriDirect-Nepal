import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:cloudinary_public/cloudinary_public.dart';

/// Service to handle file uploads to different storage providers.
class StorageService {
  // Cloudinary Configuration
  // Using a generic cloud name and unsigned upload preset for ease of use.
  static const String _cloudName = 'dwu54m8er'; // generic cloud name for AgriDirect Nepal
  static const String _uploadPreset = 'agridirect_unsigned'; 

  final CloudinaryPublic _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  /// Uploads an image to Cloudinary (Primary) with Firebase Storage as fallback.
  Future<String?> uploadImage(XFile xFile, String folder) async {
    try {
      debugPrint('Cloudinary: Starting upload for ${xFile.name} into $folder...');
      
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          xFile.path,
          folder: 'agridirect/$folder',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      if (response.secureUrl.isNotEmpty) {
        debugPrint('Cloudinary Upload Success: ${response.secureUrl}');
        return response.secureUrl;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      debugPrint('Attempting Firebase Storage Fallback...');
      return await _uploadToFirebase(xFile, folder);
    }
    return null;
  }

  /// Internal method for Firebase Storage upload (Fallback).
  Future<String?> _uploadToFirebase(XFile xFile, String folder) async {
    try {
      final String fileName = _generateFileName(xFile);
      final storageRef = FirebaseStorage.instance.ref().child(folder).child(fileName);

      final String ext = p.extension(xFile.name).toLowerCase();
      final metadata = SettableMetadata(contentType: _getContentType(ext));
      
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        final TaskSnapshot uploadTask = await storageRef.putData(bytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } else {
        final file = File(xFile.path);
        final TaskSnapshot uploadTask = await storageRef.putFile(file, metadata);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Firebase Storage Fallback Error: $e');
      return null;
    }
  }

  /// Generates a unique filename based on the current timestamp and original extension.
  String _generateFileName(XFile xFile) {
    final String ext = p.extension(xFile.name).toLowerCase();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$timestamp${ext.isEmpty ? ".jpg" : ext}';
  }

  /// Maps file extensions to MIME content types.
  String _getContentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Cleanup local temporary files if needed.
  Future<void> cleanup(XFile xFile) async {
    try {
      if (!kIsWeb) {
        final file = File(xFile.path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Cleanup Error: $e');
    }
  }
}
