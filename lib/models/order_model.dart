import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String? userId;
  final String? userName;
  final double total;
  final String status;
  final DateTime? createdAt;
  final List<dynamic>? items;

  OrderModel({
    required this.id,
    this.userId,
    this.userName,
    required this.total,
    required this.status,
    this.createdAt,
    this.items,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    var rawPrice = data['totalPrice'] ?? data['total'] ?? 0;
    double price = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0;

    return OrderModel(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      total: price,
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      items: data['items'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'total': total,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'items': items,
    };
  }
}
