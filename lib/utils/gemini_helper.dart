import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'translations.dart';

class GeminiHelper {
  // Gemini features reverted for now to avoid build/connectivity errors.
  // Using Local Expert Report logic only.

  Future<Map<String, dynamic>> analyzeCropHealth(XFile imageFile, bool isNepali, {String? localLabel}) async {
    debugPrint('Mocking Gemini Analysis (Local Fallback)...');
    
    // Simulate thinking delay
    await Future.delayed(const Duration(seconds: 1));
    
    return _getLocalExpertAnalysis(localLabel, isNepali);
  }

  Map<String, dynamic> _getLocalExpertAnalysis(String? label, bool isNepali) {
    if (label == null) return {'analysis': isNepali ? "कृपया फोटो खिच्नुहोस्।" : "Please take a photo first."};

    final symptoms = AppTranslations.translate(label, 'symptoms_ne', isNepali: isNepali);
    final remedy = AppTranslations.translate(label, 'remedy_ne', isNepali: isNepali);

    String text = isNepali
        ? "कृषि विज्ञ रिपोर्ट (स्थानीय):\n• पहिचान: $label\n• लक्षण: $symptoms\n• उपचार: $remedy"
        : "Expert Report (Local Database):\n• Diagnosis: $label\n• Symptoms: $symptoms\n• Remedy: $remedy";
    
    return {
      'analysis': text,
      'isGemini': false,
    };
  }
}
