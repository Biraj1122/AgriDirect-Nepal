import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String? userId;
  final String? userName;
  final double total;
  final double adminRevenue;
  final double farmerRevenue;
  final double deliveryRevenue;
  final String status;
  final DateTime? createdAt;
  final List<dynamic>? items;

  OrderModel({
    required this.id,
    this.userId,
    this.userName,
    required this.total,
    this.adminRevenue = 0.0,
    this.farmerRevenue = 0.0,
    this.deliveryRevenue = 0.0,
    required this.status,
    this.createdAt,
    this.items,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    var rawPrice = data['totalPrice'] ?? data['total'] ?? 0;
    double price = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0;

    var rawAdminRevenue = data['adminRevenue'] ?? 0;
    double adminRevenue = rawAdminRevenue is num ? rawAdminRevenue.toDouble() : double.tryParse(rawAdminRevenue.toString()) ?? 0;

    var rawFarmerRevenue = data['farmerRevenue'] ?? 0;
    double farmerRevenue = rawFarmerRevenue is num ? rawFarmerRevenue.toDouble() : double.tryParse(rawFarmerRevenue.toString()) ?? 0;

    var rawDeliveryRevenue = data['deliveryRevenue'] ?? 0;
    double deliveryRevenue = rawDeliveryRevenue is num ? rawDeliveryRevenue.toDouble() : double.tryParse(rawDeliveryRevenue.toString()) ?? 0;

    return OrderModel(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      total: price,
      adminRevenue: adminRevenue,
      farmerRevenue: farmerRevenue,
      deliveryRevenue: deliveryRevenue,
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
      'adminRevenue': adminRevenue,
      'farmerRevenue': farmerRevenue,
      'deliveryRevenue': deliveryRevenue,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'items': items,
    };
  }
}
