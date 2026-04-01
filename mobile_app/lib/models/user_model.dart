import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String email;
  final String name;
  final String phone;
  final String? gstin;
  final DateTime createdAt;

  // ── AI / Trust Analytics Fields ────────────────────────────────────────
  final double trustScore;
  final int completedTrips;
  final double onTimeRate;       // 0.0–100.0 percentage
  final int totalDelays;
  final double epodComplianceRate; // 0.0–100.0 percentage
  final double gpsReliability;     // 0.0–100.0 percentage

  UserModel({
    required this.uid,
    required this.role,
    required this.email,
    required this.name,
    required this.phone,
    this.gstin,
    required this.createdAt,
    this.trustScore = 0.0,
    this.completedTrips = 0,
    this.onTimeRate = 100.0,
    this.totalDelays = 0,
    this.epodComplianceRate = 0.0,
    this.gpsReliability = 100.0,
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
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0.0,
      completedTrips: (map['completedTrips'] as num?)?.toInt() ?? 0,
      onTimeRate: (map['onTimeRate'] as num?)?.toDouble() ?? 100.0,
      totalDelays: (map['totalDelays'] as num?)?.toInt() ?? 0,
      epodComplianceRate: (map['epodComplianceRate'] as num?)?.toDouble() ?? 0.0,
      gpsReliability: (map['gpsReliability'] as num?)?.toDouble() ?? 100.0,
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
      'trustScore': trustScore,
      'completedTrips': completedTrips,
      'onTimeRate': onTimeRate,
      'totalDelays': totalDelays,
      'epodComplianceRate': epodComplianceRate,
      'gpsReliability': gpsReliability,
    };
  }
}
