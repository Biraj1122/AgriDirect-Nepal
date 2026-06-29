import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../config/aws_config.dart';

/// Service to handle file uploads to different storage providers.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image to Firebase Storage and returns the download URL.
  /// This implementation is cross-platform (Web & Mobile) and uses 
  /// the project's default Firebase configuration.
  Future<String?> uploadImage(XFile xFile, String folder) async {
    try {
      final String fileName = _generateFileName(xFile);
      final storageRef = _storage.ref().child(folder).child(fileName);

      final String ext = p.extension(xFile.name).toLowerCase();
      final metadata = SettableMetadata(contentType: _getContentType(ext));
      
      // readAsBytes() works on both Web and Mobile
      final bytes = await xFile.readAsBytes();
      
      // putData is the most reliable cross-platform upload method
      final TaskSnapshot uploadTask = await storageRef.putData(bytes, metadata);
      
      // Get and return the public download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Firebase Storage Error: $e');
      return null;
    }
  }

  /// Uploads an image to Firebase Storage and returns the download URL.
  /// @deprecated Use [uploadImage] instead.
  Future<String?> uploadToFirebase(XFile xFile, String folder) => uploadImage(xFile, folder);

  /// Uploads an image to AWS S3 and returns the s3:// URI.
  /// NOTE: This currently returns the predicted URI for integration. 
  /// For actual binary upload, implement AWS Amplify or pre-signed URLs.
  Future<String?> uploadToS3(XFile xFile, String folder) async {
    try {
      final String fileName = _generateFileName(xFile);
      final String fullPath = '$folder/$fileName';
      
      final String s3Uri = 's3://${AWSConfig.bucketName}/$fullPath';
      debugPrint('S3 URI Generated: $s3Uri');
      
      return s3Uri;
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
}
