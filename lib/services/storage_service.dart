import 'dart:io';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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
      debugPrint('StorageService Error: $e');
      return null;
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
