import 'package:image_picker/image_picker.dart';

class AIHelper {
  Future<void> loadModel() async {
    throw UnimplementedError('Cannot load model without platform implementation');
  }

  Future<Map<String, dynamic>> runInference(XFile imageFile) async {
    throw UnimplementedError('Cannot run inference without platform implementation');
  }
}
