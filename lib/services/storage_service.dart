import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../config/aws_config.dart';

/// Service to handle file uploads to different storage providers.
class StorageService {
  // Cloudflare R2 Credentials (Placeholders - to be replaced with production values)
  static const String _accessKey = 'YOUR_ACCESS_KEY';
  static const String _secretKey = 'YOUR_SECRET_KEY';
  static const String _bucket = 'agridirect-uploads';
  static const String _region = 'auto'; // Cloudflare R2 uses 'auto'
  
  // Public URL for accessing uploaded images (Cloudflare R2 Public Bucket/Custom Domain)
  static const String _baseUrl = 'https://pub-your-id.r2.dev';

  /// Uploads an image to Cloudflare R2 and returns the public URL.
  /// Uses aws_s3_upload: 1.5.0 which does not support 'endpoint' parameter.
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
      final String ext = p.extension(xFile.name).toLowerCase();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? ".jpg" : ext}';
      
      // aws_s3_upload 1.5.0 uses File object from dart:io
      // Note: This implementation may need adjustment for Flutter Web
      final File file = File(xFile.path);

      // Using the specific API of aws_s3_upload: 1.5.0
      // - No 'endpoint' parameter (not defined in this version)
      // - 'destDir' is a non-nullable String
      // - Uses 'filename' to avoid manual copying
      final String? result = await AwsS3.uploadFile(
        accessKey: _accessKey,
        secretKey: _secretKey,
        bucket: _bucket,
        region: _region,
        file: file,
        destDir: folder, 
        filename: fileName,
      );

      // result is the filename/path if successful
      if (result != null) {
        final String downloadUrl = '$_baseUrl/$folder/$fileName';
        debugPrint('Upload successful: $downloadUrl');
        return downloadUrl;
      }
      
      debugPrint('Upload failed: No result from AwsS3.uploadFile');
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
