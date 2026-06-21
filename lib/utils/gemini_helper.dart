import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'translations.dart';

class GeminiHelper {
  // IMPORTANT: Do not hardcode API Keys in public repositories.
  // Set your key in the AI Settings screen or use --dart-define during build.
  static const String defaultApiKey = "";

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    return (savedKey != null && savedKey.isNotEmpty) ? savedKey : defaultApiKey;
  }

  Future<Map<String, dynamic>> analyzeCropHealth(XFile imageFile, bool isNepali, {String? localLabel}) async {
    final apiKey = await _getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      return {
        'analysis': isNepali 
            ? "कृपया सेटिङमा गई Gemini API Key राख्नुहोस्।" 
            : "Please set your Gemini API Key in the AI Settings screen first.",
        'isGemini': false,
        'needsKey': true,
      };
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final bytes = await imageFile.readAsBytes();
      
      String prompt = isNepali
          ? "तपाईं नेपालको एक अनुभवी कृषि तथा पशु चिकित्सक (Agri-Vet) विशेषज्ञ हुनुहुन्छ। यो फोटो हेरेर समस्या/रोग पत्ता लगाउनुहोस्।"
          : "You are an experienced Agri-Vet expert specialized in the Nepalese agricultural context. Analyze this image to identify the disease or pest.";

      if (localLabel != null && localLabel.isNotEmpty) {
        prompt += isNepali 
            ? " हाम्रो स्थानीय मोडेलले यसलाई '$localLabel' को रूपमा पहिचान गरेको छ। कृपया यसलाई पुष्टि गर्नुहोस् र विस्तृत जैविक तथा रासायनिक उपचारहरू नेपालीमा बुँदागत रूपमा दिनुहोस्।" 
            : " Our local model suggests this might be '$localLabel'. Please confirm this and provide detailed organic and chemical remedies suitable for Nepal in bullet points.";
      } else {
        prompt += isNepali
            ? " कृपया विस्तृत जैविक तथा रासायनिक उपचार विधिहरू नेपालीमा बुँदागत रूपमा बताउनुहोस्।"
            : " Please provide detailed organic and chemical remedies in bullet points.";
      }

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      if (response.text == null) throw Exception("Empty response from AI");

      return {
        'analysis': response.text!,
        'isGemini': true,
      };
    } catch (e) {
      debugPrint('Gemini Error: $e');
      // Fallback to local analysis if AI fails
      final fallback = _getLocalExpertAnalysis(localLabel, isNepali);
      fallback['error'] = e.toString();
      return fallback;
    }
  }

  Future<bool> testApiKey(String key) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );
      final response = await model.generateContent([Content.text("Hello")]);
      return response.text != null;
    } catch (e) {
      debugPrint("API Key Test Failed: $e");
      return false;
    }
  }

  Future<String?> askFollowUp(String question, String contextAnalysis, bool isNepali) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = isNepali
          ? "तपाईं एक कृषि विज्ञ हुनुहुन्छ। अघिल्लो विश्लेषण यो थियो: '$contextAnalysis'। अब किसानको यो प्रश्नको जवाफ दिनुहोस्: '$question'।"
          : "You are an expert agronomist. The previous analysis was: '$contextAnalysis'. Now answer this farmer's follow-up question: '$question'.";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Gemini Chat Error: $e');
      return null;
    }
  }

  Map<String, dynamic> _getLocalExpertAnalysis(String? label, bool isNepali) {
    if (label == null || label == 'Healthy' || label == 'Healthy Leaf') {
       return {
         'analysis': isNepali ? "बाली स्वस्थ देखिन्छ।" : "The crop appears healthy.",
         'isGemini': false
       };
    }

    final diagnosis = AppTranslations.translate(label, 'name_ne', isNepali: isNepali);
    final symptoms = AppTranslations.translate(label, 'symptoms_ne', isNepali: isNepali);
    final remedy = AppTranslations.translate(label, 'remedy_ne', isNepali: isNepali);

    String text = isNepali
        ? "कृषि विज्ञ रिपोर्ट (स्थानीय):\n• पहिचान: $diagnosis\n• लक्षण: $symptoms\n• उपचार: $remedy"
        : "Expert Report (Local Database):\n• Diagnosis: $diagnosis\n• Symptoms: $symptoms\n• Remedy: $remedy";
    
    return {
      'analysis': text,
      'isGemini': false,
    };
  }
}
