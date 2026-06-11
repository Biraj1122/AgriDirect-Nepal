import 'package:image_picker/image_picker.dart';

class AIHelper {
  Future<void> loadModel() async {
    // No-op on web
    print('AI Model skipped on Web');
  }

  Future<Map<String, dynamic>> runInference(XFile imageFile) async {
    // On web, we return a mock result because TFLite FFI is not available
    return {
      'label': 'Web Preview: Mock Result',
      'confidence': 0.99,
    };
  }
}
