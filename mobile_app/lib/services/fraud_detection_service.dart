import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fraud Detection Engine — Lightweight rule-based ML
/// Detects: GPS jumps, unrealistic speed, proof image reuse
class FraudDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1️⃣ TELEPORT DETECTION (CRITICAL)
  /// If distance between two GPS points > 10 km in < 2 minutes
  String? detectGPSJump({
    required double prevLat,
    required double prevLng,
    required double currentLat,
    required double currentLng,
    required int timeDeltaMinutes,
  }) {
    final distanceKm = calculateDistance(prevLat, prevLng, currentLat, currentLng);

    if (timeDeltaMinutes <= 2 && distanceKm > 10) {
      return 'GPS Anomaly Detected';
    }

    return null;
  }

  /// 2️⃣ SPEED CHECK
  /// If speed > 120 km/h
  String? detectUnrealisticSpeed(double speed, [double maxAllowed = 120]) {
    if (speed > maxAllowed) {
      return 'Unrealistic speed detected (${speed.toStringAsFixed(1)} km/h)';
    }
    return null;
  }

  /// 3️⃣ ROUTE DEVIATION
  /// If current location deviates > 2 km from expected route
  String? detectRouteDeviation(double currentLat, double currentLng, double expectedLat, double expectedLng) {
    final deviationKm = calculateDistance(currentLat, currentLng, expectedLat, expectedLng);
    if (deviationKm > 2) {
      return 'Route Deviation';
    }
    return null;
  }

  /// 4️⃣ PROOF VALIDATION
  /// If proof location is far (>1 km) from delivery location
  String? validateProofLocation(double proofLat, double proofLng, double deliveryLat, double deliveryLng) {
    final distanceKm = calculateDistance(proofLat, proofLng, deliveryLat, deliveryLng);
    if (distanceKm > 1) {
      return 'Invalid Proof Location';
    }
    return null;
  }


  /// Detect proof image reuse (same image hash used on different shipments)
  Future<String?> detectProofImageReuse(String imageHash, String currentShipmentId) async {
    try {
      final query = await _firestore
          .collection('shipments')
          .where('proofMetadata.imageHash', isEqualTo: imageHash)
          .limit(5)
          .get();

      final reusedDocs = query.docs
          .where((doc) => doc.id != currentShipmentId)
          .toList();

      if (reusedDocs.isNotEmpty) {
        final reusedIds = reusedDocs.map((d) => d.id).join(', ');
        return 'IMAGE_REUSE: Same proof image found on shipments: $reusedIds';
      }
    } catch (e) {
      debugPrint('[FraudDetection] Image reuse check failed: $e');
    }
    return null;
  }

  /// Run all fraud checks for a shipment and return list of flags
  Future<List<String>> runAllChecks({
    required String shipmentId,
    double? prevLat,
    double? prevLng,
    double? currentLat,
    double? currentLng,
    int? timeDeltaMinutes,
    double? speedKmh,
    String? imageHash,
  }) async {
    final flags = <String>[];

    // GPS Jump Detection
    if (prevLat != null && prevLng != null && currentLat != null && currentLng != null && timeDeltaMinutes != null) {
      final gpsFlag = detectGPSJump(
        prevLat: prevLat,
        prevLng: prevLng,
        currentLat: currentLat,
        currentLng: currentLng,
        timeDeltaMinutes: timeDeltaMinutes,
      );
      if (gpsFlag != null) flags.add(gpsFlag);
    }

    // Speed Anomaly Detection
    if (speedKmh != null) {
      final speedFlag = detectUnrealisticSpeed(speedKmh);
      if (speedFlag != null) flags.add(speedFlag);
    }

    // Image Reuse Detection
    if (imageHash != null) {
      final imageFlag = await detectProofImageReuse(imageHash, shipmentId);
      if (imageFlag != null) flags.add(imageFlag);
    }

    // If we found new flags, persist them
    if (flags.isNotEmpty) {
      await _persistFraudFlags(shipmentId, flags);
    }

    return flags;
  }

  /// Persist fraud flags to the shipment document
  Future<void> _persistFraudFlags(String shipmentId, List<String> newFlags) async {
    try {
      await _firestore.collection('shipments').doc(shipmentId).update({
        'fraudFlags': FieldValue.arrayUnion(newFlags),
      });
      debugPrint('[FraudDetection] Flagged shipment $shipmentId: $newFlags');
    } catch (e) {
      debugPrint('[FraudDetection] Failed to persist flags: $e');
    }
  }

  /// Get all fraud flags for a specific transporter's shipments
  Future<Map<String, List<String>>> getTransporterFraudFlags(String transporterId) async {
    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('transporterId', isEqualTo: transporterId)
          .get();

      final flagMap = <String, List<String>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final flags = (data['fraudFlags'] as List<dynamic>?)?.cast<String>() ?? [];
        if (flags.isNotEmpty) {
          flagMap[doc.id] = flags;
        }
      }
      return flagMap;
    } catch (e) {
      debugPrint('[FraudDetection] Error fetching flags: $e');
      return {};
    }
  }

  /// Get total fraud alert count for a business's shipments
  Future<int> getBusinessFraudAlertCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('businessId', isEqualTo: businessId)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        final flags = (doc.data()['fraudFlags'] as List<dynamic>?) ?? [];
        count += flags.length;
      }
      return count;
    } catch (e) {
      debugPrint('[FraudDetection] Error counting alerts: $e');
      return 0;
    }
  }

  /// Calculate distance using Haversine formula (km)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);
}
