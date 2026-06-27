import 'package:cloud_firestore/cloud_firestore.dart';

class PriceRequestModel {
  final String id;
  final String productId;
  final String productName;
  final String farmerUid;
  final String farmName;
  final double oldPrice;
  final double newPrice;
  final String oldUnit;
  final String newUnit;
  final String status; // 'pending', 'approved', 'declined'
  final DateTime? createdAt;

  PriceRequestModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.farmerUid,
    required this.farmName,
    required this.oldPrice,
    required this.newPrice,
    required this.oldUnit,
    required this.newUnit,
    required this.status,
    this.createdAt,
  });

  factory PriceRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PriceRequestModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      farmerUid: data['farmerUid'] ?? '',
      farmName: data['farmName'] ?? '',
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0.0,
      newPrice: (data['newPrice'] as num?)?.toDouble() ?? 0.0,
      oldUnit: data['oldUnit'] ?? '',
      newUnit: data['newUnit'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'farmerUid': farmerUid,
      'farmName': farmName,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'oldUnit': oldUnit,
      'newUnit': newUnit,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
