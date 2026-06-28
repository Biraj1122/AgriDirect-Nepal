import 'dart:io';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class StorageService {
  // Cloudflare R2 credentials (S3-compatible)
  // Note: For production, these should be handled securely (e.g., via a proxy/worker or pre-signed URLs)
  static const String _accountId = 'YOUR_CLOUDFLARE_ACCOUNT_ID';
  static const String _accessKey = 'YOUR_ACCESS_KEY';
  static const String _secretKey = 'YOUR_SECRET_KEY';
  static const String _bucketName = 'agridirect-uploads';
  static const String _customDomain = 'https://pub-xxxx.r2.dev'; // Your R2 Public Bucket URL or Custom Domain
  static const String _region = 'auto'; // R2 uses 'auto'

  /// Uploads a file to Cloudflare R2 and returns the public URL
  Future<String?> uploadImage(File file, String folder) async {
    File? tempFile;
    try {
      if (!await file.exists()) {
        debugPrint('Upload Error: File does not exist at ${file.path}');
        return null;
      }

      final extension = p.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // We must rename the file locally because the package uses the local filename as the S3 object key
      final String tempPath = p.join(Directory.systemTemp.path, fileName);
      tempFile = await file.copy(tempPath);

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      final extLower = extension.toLowerCase();
      if (extLower == '.png') {
        contentType = 'image/png';
      } else if (extLower == '.gif') {
        contentType = 'image/gif';
      } else if (extLower == '.webp') {
        contentType = 'image/webp';
      }

      final cleanFolder = folder.trim().replaceAll(RegExp(r'^/|/$'), '');

      // Using AwsS3.uploadFile from aws_s3_upload package
      // Note: The current package version (1.5.0) uses the AWS S3 endpoint by default.
      // For Cloudflare R2, if this method fails, a manual implementation using the S3 API is required.
      final String? result = await AwsS3.uploadFile(
        accessKey: _accessKey,
        secretKey: _secretKey,
        file: tempFile,
        bucket: _bucketName,
        region: _region,
        destDir: cleanFolder,
        contentType: contentType,
      );

      if (result != null) {
        // Construct the URL using the custom domain and path
        final String folderPath = cleanFolder.isEmpty ? "" : "$cleanFolder/";
        return '$_customDomain/$folderPath$fileName';
      }
      return null;
    } catch (e) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }
    }
  }
}
