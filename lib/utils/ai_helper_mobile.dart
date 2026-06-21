import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AIHelper {
  // Real TFLite implementation reverted for now to avoid build errors.
  // Using Mock implementation for development stability.

  Future<bool> loadModel() async {
    debugPrint('Mock AI Model loaded (Mobile)');
    return true;
  }

  Future<Map<String, dynamic>> runInference(XFile imageFile) async {
    debugPrint('Running mock inference on Mobile...');
    
    // Artificial delay to simulate processing
    await Future.delayed(const Duration(seconds: 2));

    final mockResults = [
      {"label": "Potato: Late Blight", "confidence": 0.94},
      {"label": "Bitter Gourd: Fruit Fly", "confidence": 0.96},
      {"label": "Ginger: Rhizome Rot", "confidence": 0.89},
      {"label": "Cattle: Lumpy Skin", "confidence": 0.91},
      {"label": "Poultry: Coccidiosis", "confidence": 0.85},
      {"label": "Rice: Brown Spot", "confidence": 0.82},
      {"label": "Healthy", "confidence": 0.98},
    ];

    // Pick a result based on the current time for variety during testing
    final result = mockResults[DateTime.now().second % mockResults.length];
    
    return {
      'label': result['label'] as String,
      'confidence': result['confidence'] as double,
    };
  }
}
