import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? address;
  final double? lat;
  final double? lng;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.address,
    this.lat,
    this.lng,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'],
      email: data['email'],
      phone: data['phone'],
      role: data['role'],
      address: data['address'],
      lat: data['lat']?.toDouble(),
      lng: data['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}
