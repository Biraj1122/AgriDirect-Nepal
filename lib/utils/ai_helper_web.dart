import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:math';

class AIHelper {
  Future<void> loadModel() async {
    // No-op on web
    developer.log('AI Model skipped on Web');
  }

  Future<Map<String, dynamic>> runInference(XFile imageFile) async {
    // On web, we return variety of mock results for development testing
    await Future.delayed(const Duration(seconds: 1));
    
    final mockResults = [
      {"label": "Potato: Late Blight", "confidence": 0.94},
      {"label": "Bitter Gourd: Fruit Fly", "confidence": 0.96},
      {"label": "Ginger: Rhizome Rot", "confidence": 0.89},
      {"label": "Cattle: Lumpy Skin", "confidence": 0.91},
      {"label": "Poultry: Coccidiosis", "confidence": 0.85},
      {"label": "Rice: Brown Spot", "confidence": 0.82},
      {"label": "Healthy", "confidence": 0.98},
    ];

    final random = Random();
    final result = mockResults[random.nextInt(mockResults.length)];
    
    return {
      'label': result['label'] as String,
      'confidence': result['confidence'] as double,
    };
  }
}
