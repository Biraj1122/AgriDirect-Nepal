import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image to Firebase Storage and returns the download URL.
  /// This implementation is cross-platform (Web & Mobile) and uses 
  /// the project's default Firebase configuration.
  Future<String?> uploadImage(XFile xFile, String folder) async {
    try {
      // Use xFile.name to get the extension as xFile.path can be a blob URL on web
      final String ext = p.extension(xFile.name).toLowerCase();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? ".jpg" : ext}';
      final storageRef = _storage.ref().child(folder).child(fileName);

      // Determine content type for better browser/cloud handling
      String contentType = 'image/jpeg';
      if (ext == '.png') {
        contentType = 'image/png';
      } else if (ext == '.gif') {
        contentType = 'image/gif';
      } else if (ext == '.webp') {
        contentType = 'image/webp';
      }

      final metadata = SettableMetadata(contentType: contentType);
      
      // readAsBytes() works on both Web and Mobile
      final bytes = await xFile.readAsBytes();
      
      // putData is the most reliable cross-platform upload method
      final TaskSnapshot uploadTask = await storageRef.putData(bytes, metadata);
      
      // Get and return the public download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService Error: $e');
      return null;
    }
  }
}
