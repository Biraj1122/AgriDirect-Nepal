import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String title;
  final String content;
  final DateTime? updatedAt;

  AnnouncementModel({
    required this.title,
    required this.content,
    this.updatedAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return AnnouncementModel(
      title: data?['title'] ?? '',
      content: data?['content'] ?? '',
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
