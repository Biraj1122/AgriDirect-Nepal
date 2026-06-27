import 'package:cloud_firestore/cloud_firestore.dart';

class ResearchSubmissionModel {
  final String id;
  final String? cropName;
  final String? diagnosis;
  final DateTime? createdAt;

  ResearchSubmissionModel({
    required this.id,
    this.cropName,
    this.diagnosis,
    this.createdAt,
  });

  factory ResearchSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResearchSubmissionModel(
      id: doc.id,
      cropName: data['cropName'],
      diagnosis: data['diagnosis'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
