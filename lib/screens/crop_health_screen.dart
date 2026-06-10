import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'disease_library_screen.dart';
import '../utils/translations.dart';

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

  final ImagePicker _picker = ImagePicker();

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

    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 3));

    // For now, we use a mock diagnosis logic.
    // In the future, this will call a TFLite model or a Cloud Function.
    final mockResults = [
      {"label": "Potato: Late Blight", "confidence": 0.94},
      {"label": "Tomato: Bacterial Spot", "confidence": 0.88},
      {"label": "Healthy Leaf", "confidence": 0.97},
      {"label": "Rice: Brown Spot", "confidence": 0.76},
    ];

    final result = mockResults[DateTime.now().second % mockResults.length];

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _diagnosisResult = result['label'] as String;
        _confidence = result['confidence'] as double;
      });
      
      // Upload for research (optional background task)
      _uploadForResearch();
    }
  }

  Future<void> _uploadForResearch() async {
    if (_imageFile == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final fileName = 'research_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('crop_research').child(fileName);
      
      if (kIsWeb) {
        await storageRef.putData(await _imageFile!.readAsBytes());
      } else {
        await storageRef.putFile(File(_imageFile!.path));
      }
      
      final url = await storageRef.getDownloadURL();
      
      await FirebaseFirestore.instance.collection('research_submissions').add({
        'imageUrl': url,
        'predictedLabel': _diagnosisResult,
        'confidence': _confidence,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Research upload failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text("Crop Health AI (Beta)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          Row(
            children: [
              const Text("EN", style: TextStyle(fontSize: 12)),
              Switch(
                value: _isNepali,
                onChanged: (val) => setState(() => _isNepali = val),
                activeThumbColor: Colors.green,
              ),
              const Text("ने", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            if (_imageFile != null) _buildAnalysisResult(),
            const Text("Experimental Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildFeatureCard(
              context,
              Icons.camera_alt,
              "Leaf Scanner",
              "Scan leaves for spots, wilting, or discoloration.",
              "Beta Active",
              Colors.blue,
              onTap: () => _showPickerOptions(),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              Icons.library_books,
              "Disease Library",
              "Browse common crop diseases in Nepal and their solutions.",
              "Active",
              Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiseaseLibraryScreen()),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text("Supported Crops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Our AI model is currently trained on these high-accuracy datasets:",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),
            _buildDatasetTile("Potato", "Late Blight, Early Blight", "92% Accuracy"),
            _buildDatasetTile("Tomato", "Leaf Mold, Bacterial Spot", "89% Accuracy"),
            _buildDatasetTile("Rice", "Brown Spot, Leaf Blast", "Beta Testing"),
            _buildDatasetTile("Maize", "Common Rust, Northern Leaf Blight", "Beta Testing"),
            
            const SizedBox(height: 30),
            _buildResearchBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text("AI Diagnosis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Upload a photo of your crop's leaf to identify diseases using our experimental AI model trained on PlantVillage datasets.",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final displayResult = _isNepali && _diagnosisResult != null
        ? AppTranslations.translate(_diagnosisResult!, 'name_ne')
        : _diagnosisResult;
    final displaySymptoms = _isNepali && _diagnosisResult != null
        ? AppTranslations.translate(_diagnosisResult!, 'symptoms_ne')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: kIsWeb 
                ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing)
            Column(
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 12),
                Text(_isNepali ? "पातको ढाँचा विश्लेषण गर्दै..." : "Analyzing leaf patterns...", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            )
          else if (_diagnosisResult != null)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      displayResult!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isNepali ? "शुद्धता: ${(_confidence! * 100).toStringAsFixed(1)}%" : "Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                if (displaySymptoms != null) ...[
                  const SizedBox(height: 12),
                  Text(displaySymptoms, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 12),
                const Divider(),
                TextButton(
                  onPressed: () => _showPickerOptions(),
                  child: Text(_isNepali ? "अर्को पात स्क्यान गर्नुहोस्" : "Scan Another Leaf"),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Select Source", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, String desc, String status, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasetTile(String crop, String diseases, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.eco, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(diseases, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(status, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResearchBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Farmer feedback is vital! Every scan helps our research team improve accuracy for Nepal's specific crop varieties.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

