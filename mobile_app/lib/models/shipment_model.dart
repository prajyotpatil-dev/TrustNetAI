import 'package:cloud_firestore/cloud_firestore.dart';

class ShipmentModel {
  final String shipmentId;
  final String lrNumber;
  final String fromCity;
  final String toCity;
  final String status;
  final String transporterId;
  final String? businessId; // Optional if not assigned immediately
  final String? epodUrl;
  final double trustScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShipmentModel({
    required this.shipmentId,
    required this.lrNumber,
    required this.fromCity,
    required this.toCity,
    required this.status,
    required this.transporterId,
    this.businessId,
    this.epodUrl,
    this.trustScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShipmentModel.fromMap(Map<String, dynamic> map, String id) {
    return ShipmentModel(
      shipmentId: id,
      lrNumber: map['lrNumber'] as String? ?? 'UNKNOWN',
      fromCity: map['fromCity'] as String? ?? '',
      toCity: map['toCity'] as String? ?? '',
      status: map['status'] as String? ?? 'created',
      transporterId: map['transporterId'] as String? ?? '',
      businessId: map['businessId'] as String?,
      epodUrl: map['epodUrl'] as String?,
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shipmentId': shipmentId,
      'lrNumber': lrNumber,
      'fromCity': fromCity,
      'toCity': toCity,
      'status': status,
      'transporterId': transporterId,
      if (businessId != null) 'businessId': businessId,
      if (epodUrl != null) 'epodUrl': epodUrl,
      'trustScore': trustScore,
      'createdAt': createdAt.toIso8601String(), // Saving as ISO String to be consistent with user's date format
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
