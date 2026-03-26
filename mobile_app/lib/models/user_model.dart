import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String email;
  final String name;
  final String phone;
  final String? gstin;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.email,
    required this.name,
    required this.phone,
    this.gstin,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      role: map['role'] as String? ?? 'transporter',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? '',
      gstin: map['gstin'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'email': email,
      'name': name,
      'phone': phone,
      if (gstin != null) 'gstin': gstin,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
