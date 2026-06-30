import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service to handle file uploads to different storage providers.
class StorageService {
  // Cloudflare R2 Credentials (Placeholders - to be replaced with production values)
  static const String _accessKey = 'YOUR_ACCESS_KEY';
  static const String _secretKey = 'YOUR_SECRET_KEY';
  static const String _bucket = 'agridirect-uploads';
  static const String _region = 'auto'; // Cloudflare R2 uses 'auto'
  
  // Public URL for accessing uploaded images (Cloudflare R2 Public Bucket/Custom Domain)
  static const String _baseUrl = 'https://pub-your-id.r2.dev';

  /// Uploads an image to Firebase Storage and returns the download URL.
  Future<String?> uploadImage(XFile xFile, String folder) async {
    try {
      final String fileName = _generateFileName(xFile);
      final storageRef = FirebaseStorage.instance.ref().child(folder).child(fileName);

      final String ext = p.extension(xFile.name).toLowerCase();
      final metadata = SettableMetadata(contentType: _getContentType(ext));
      
      if (kIsWeb) {
        // Use putData for Web
        final bytes = await xFile.readAsBytes();
        final TaskSnapshot uploadTask = await storageRef.putData(bytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } else {
        // Use putFile for Mobile/Desktop (more robust for various formats)
        final file = File(xFile.path);
        final TaskSnapshot uploadTask = await storageRef.putFile(file, metadata);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Firebase Storage Error: $e');
      return null;
    }
  }

  /// Alias for [uploadImage] for backward compatibility.
  Future<String?> uploadToFirebase(XFile xFile, String folder) => uploadImage(xFile, folder);

  /// Uploads an image to AWS S3 (or compatible R2) and returns the URL.
  Future<String?> uploadToS3(XFile xFile, String folder) async {
    try {
      final String ext = p.extension(xFile.name).toLowerCase();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? ".jpg" : ext}';
      
      // Note: This implementation may need adjustment for Flutter Web
      // aws_s3_upload 1.5.0 uses File object from dart:io for mobile
      if (!kIsWeb) {
        final File file = File(xFile.path);
        final String? result = await AwsS3.uploadFile(
          accessKey: _accessKey,
          secretKey: _secretKey,
          bucket: _bucket,
          region: _region,
          file: file,
          destDir: folder, 
          filename: fileName,
        );

        if (result != null) {
          final String downloadUrl = '$_baseUrl/$folder/$fileName';
          debugPrint('Upload successful: $downloadUrl');
          return downloadUrl;
        }
      } else {
        debugPrint('AWS S3 upload not fully implemented for Web in this snippet');
      }
      
      return null;
    } catch (e) {
      debugPrint('S3 Upload Error: $e');
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

  /// Optional: Cleanup local temporary files if needed
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
