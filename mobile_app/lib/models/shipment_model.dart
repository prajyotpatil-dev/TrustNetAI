import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipment_status.dart';

class ShipmentModel {
  final String shipmentId;
  final String lrNumber;
  final String fromCity;
  final String toCity;
  final ShipmentStatus status;
  final String? transporterId;
  final String? businessId;
  final String? epodUrl;
  final double trustScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── AI Enhancement Fields ──────────────────────────────────────────────
  final DateTime? expectedDelivery;
  final double speed;           // Current speed in km/h (from GPS)
  final double heading;         // GPS heading in degrees
  final Map<String, dynamic>? proofMetadata; // {lat, lng, timestamp, imageHash}
  final List<String> fraudFlags; // Detected fraud indicators
  final DateTime? delayDetectedAt;
  final double? distanceKm;     // Total route distance
  final String? remarks;

  ShipmentModel({
    required this.shipmentId,
    required this.lrNumber,
    required this.fromCity,
    required this.toCity,
    required this.status,
    this.transporterId,
    this.businessId,
    this.epodUrl,
    this.trustScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
    // AI fields
    this.expectedDelivery,
    this.speed = 0.0,
    this.heading = 0.0,
    this.proofMetadata,
    this.fraudFlags = const [],
    this.delayDetectedAt,
    this.distanceKm,
    this.remarks,
  });

  factory ShipmentModel.fromMap(Map<String, dynamic> map, String id) {
    return ShipmentModel(
      shipmentId: id,
      lrNumber: map['lrNumber'] as String? ?? 'UNKNOWN',
      fromCity: map['fromCity'] as String? ?? '',
      toCity: map['toCity'] as String? ?? '',
      status: ShipmentStatusExtension.fromString(map['status'] as String? ?? 'created'),
      transporterId: map['transporterId'] as String?,
      businessId: map['businessId'] as String?,
      epodUrl: map['epodUrl'] as String?,
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      // AI fields
      expectedDelivery: map['expectedDelivery'] != null ? _parseDateTime(map['expectedDelivery']) : null,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      proofMetadata: map['proofMetadata'] as Map<String, dynamic>?,
      fraudFlags: (map['fraudFlags'] as List<dynamic>?)?.cast<String>() ?? const [],
      delayDetectedAt: map['delayDetectedAt'] != null ? _parseDateTime(map['delayDetectedAt']) : null,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      remarks: map['remarks'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'shipmentId': shipmentId,
      'lrNumber': lrNumber,
      'fromCity': fromCity,
      'toCity': toCity,
      'status': status.firestoreValue,
      'transporterId': transporterId,
      if (businessId != null) 'businessId': businessId,
      if (epodUrl != null) 'epodUrl': epodUrl,
      'trustScore': trustScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // AI fields
      if (expectedDelivery != null) 'expectedDelivery': expectedDelivery!.toIso8601String(),
      'speed': speed,
      'heading': heading,
      if (proofMetadata != null) 'proofMetadata': proofMetadata,
      if (fraudFlags.isNotEmpty) 'fraudFlags': fraudFlags,
      if (delayDetectedAt != null) 'delayDetectedAt': delayDetectedAt!.toIso8601String(),
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (remarks != null) 'remarks': remarks,
    };
  }

  /// Create a copy with modified fields
  ShipmentModel copyWith({
    String? shipmentId,
    String? lrNumber,
    String? fromCity,
    String? toCity,
    ShipmentStatus? status,
    String? transporterId,
    String? businessId,
    String? epodUrl,
    double? trustScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expectedDelivery,
    double? speed,
    double? heading,
    Map<String, dynamic>? proofMetadata,
    List<String>? fraudFlags,
    DateTime? delayDetectedAt,
    double? distanceKm,
    String? remarks,
  }) {
    return ShipmentModel(
      shipmentId: shipmentId ?? this.shipmentId,
      lrNumber: lrNumber ?? this.lrNumber,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      status: status ?? this.status,
      transporterId: transporterId ?? this.transporterId,
      businessId: businessId ?? this.businessId,
      epodUrl: epodUrl ?? this.epodUrl,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      proofMetadata: proofMetadata ?? this.proofMetadata,
      fraudFlags: fraudFlags ?? this.fraudFlags,
      delayDetectedAt: delayDetectedAt ?? this.delayDetectedAt,
      distanceKm: distanceKm ?? this.distanceKm,
      remarks: remarks ?? this.remarks,
    );
  }
}
