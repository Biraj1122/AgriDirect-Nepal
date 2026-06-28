import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'disease_library_screen.dart';
import 'ai_settings_screen.dart';
import '../../utils/translations.dart';
import '../../utils/ai_helper.dart';
import '../../utils/gemini_helper.dart';
import '../../services/storage_service.dart';

class CropHealthScreen extends StatefulWidget {
  const CropHealthScreen({super.key});

  @override
  State<CropHealthScreen> createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  XFile? _imageFile;
  bool _isAnalyzing = false;
  String? _diagnosisResult;
  double? _confidence;
  bool _isNepali = false;
  final AIHelper _aiHelper = AIHelper();
  final GeminiHelper _geminiHelper = GeminiHelper();
  String? _geminiAnalysis;
  bool _isGeminiLoading = false;

  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isChatLoading = false;

  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  Future<void> _saveScanToHistory(String? imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _diagnosisResult == null) return;

    try {
      await FirebaseFirestore.instance.collection('research_submissions').add({
        'userId': user.uid,
        'diagnosis': _diagnosisResult,
        'confidence': _confidence,
        'timestamp': FieldValue.serverTimestamp(),
        'isNepali': _isNepali,
        'platform': kIsWeb ? 'web' : 'mobile',
        'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  Future<void> _analyzeWithExpert() async {
    if (_imageFile == null) return;

    setState(() {
      _isGeminiLoading = true;
    });

    try {
      final result = await _geminiHelper.analyzeCropHealth(_imageFile!, _isNepali, localLabel: _diagnosisResult);
      
      if (mounted) {
        setState(() {
          _isGeminiLoading = false;
          _geminiAnalysis = result['analysis'];
          if (_geminiAnalysis != null) {
            _chatMessages.add({"role": "assistant", "content": _geminiAnalysis!});
          }
        });
      }
    } catch (e) {
      setState(() {
        _isGeminiLoading = false;
        _geminiAnalysis = "Analysis failed. Please try again.";
      });
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _isChatLoading) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatMessages.add({"role": "user", "content": userMessage});
      _chatController.clear();
      _isChatLoading = true;
    });

    try {
      final response = await _geminiHelper.askFollowUp(
        userMessage, 
        _geminiAnalysis ?? _diagnosisResult ?? "General Agriculture", 
        _isNepali
      );

      if (mounted) {
        setState(() {
          _isChatLoading = false;
          _chatMessages.add({"role": "assistant", "content": response ?? (_isNepali ? "जवाफ पाउन सकिएन।" : "Could not get a response.")});
        });
      }
    } catch (e) {
      setState(() => _isChatLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _diagnosisResult = null;
          _confidence = null;
          _geminiAnalysis = null;
          _chatMessages.clear();
        });
        _analyzeImage();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      String? imageUrl;
      if (!kIsWeb && _imageFile != null) {
        imageUrl = await _storageService.uploadImage(File(_imageFile!.path), 'scans');
      }

      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));
        final mockResults = [
          {"label": "Bitter Gourd: Fruit Fly", "confidence": 0.96},
          {"label": "Potato: Late Blight", "confidence": 0.94},
          {"label": "Tomato: Bacterial Spot", "confidence": 0.88},
          {"label": "Cattle: Lumpy Skin", "confidence": 0.82},
          {"label": "Poultry: Coccidiosis", "confidence": 0.79},
        ];
        final result = mockResults[DateTime.now().second % mockResults.length];
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _diagnosisResult = result['label'] as String;
            _confidence = result['confidence'] as double;
          });
          _saveScanToHistory(imageUrl);
        }
      } else {
        final result = await _aiHelper.runInference(_imageFile!);
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _diagnosisResult = result['label'];
            _confidence = result['confidence'];
          });
          _saveScanToHistory(imageUrl);
        }
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _diagnosisResult = "Analysis Failed";
          _confidence = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text("Agri-Vet AI Doctor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.green),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AISettingsScreen())),
          ),
          Switch(
            value: _isNepali,
            onChanged: (val) => setState(() => _isNepali = val),
            activeThumbColor: Colors.green,
          ),
          const Center(child: Text("ने  ", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_imageFile != null) _buildAnalysisSection(),
            if (_imageFile == null) _buildInitialButtons(),
            const SizedBox(height: 20),
            _buildDatabaseInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              _isNepali 
                ? "तपाईंको फार्मको व्यक्तिगत डाक्टर। बाली, फलफूल र पशुपन्छीको जाँच गर्नुहोस्।" 
                : "Your personal Farm Doctor. Analyze crops, fruits, and livestock instantly.",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showPickerOptions(),
          icon: const Icon(Icons.camera_alt),
          label: Text(_isNepali ? "स्क्यान सुरु गर्नुहोस्" : "Start New Scan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseLibraryScreen())),
          icon: const Icon(Icons.library_books),
          label: Text(_isNepali ? "रोग पुस्तकालय हेर्नुहोस्" : "Browse Disease Library"),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb 
              ? CachedNetworkImage(
                  imageUrl: _imageFile!.path,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 15),
          if (_isAnalyzing) const CircularProgressIndicator(),
          if (_diagnosisResult != null) ...[
            Text(
              AppTranslations.translate(_diagnosisResult!, 'name_ne', isNepali: _isNepali),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            Text("${(_confidence! * 100).toStringAsFixed(1)}% Accuracy"),
            const Divider(height: 30),
            if (_geminiAnalysis == null && !_isGeminiLoading)
              ElevatedButton(
                onPressed: _analyzeWithExpert,
                child: Text(_isNepali ? "विस्तृत AI रिपोर्ट र कुराकानी" : "Get Detailed AI Report & Chat"),
              ),
            if (_isGeminiLoading) const CircularProgressIndicator(),
            if (_chatMessages.isNotEmpty) _buildChatWindow(),
          ],
          const SizedBox(height: 10),
          TextButton(onPressed: () => setState(() => _imageFile = null), child: const Text("Clear")),
        ],
      ),
    );
  }

  Widget _buildChatWindow() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isUser = msg['role'] == 'user';
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUser ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(msg['content']!, style: const TextStyle(fontSize: 13)),
              );
            },
          ),
        ),
        if (_isChatLoading) const LinearProgressIndicator(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: _isNepali ? "थप प्रश्न सोध्नुहोस्..." : "Ask a follow-up question...",
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: _sendChatMessage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatabaseInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Unified Agriculture Database Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            _isNepali 
              ? "तितो करेला, स्याउ, धान, गहुँ, अदुवा, बेसार, बाख्रा, गाईवस्तु र कुखुराको रगतमासी सम्बन्धी जानकारी उपलब्ध छ।"
              : "Supports Bitter Gourd, Apple, Rice, Wheat, Ginger, Turmeric, Goats, Cattle, and Poultry diseases.",
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Camera"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text("Gallery"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }
}
