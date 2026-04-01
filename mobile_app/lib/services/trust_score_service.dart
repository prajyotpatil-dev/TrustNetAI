import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// AI Trust Score Engine
/// Implements the weighted formula:
///   trustScore = (onTimeDelivery * 0.4) + (proofCompliance * 0.2)
///                + (gpsAccuracy * 0.2) + (delayPenalty * -0.2)
class TrustScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate trust score for a single shipment event
  double calculateShipmentTrustScore({
    required bool wasOnTime,
    required bool hasEpod,
    required double gpsAccuracyPercent, // 0–100
    required bool wasDelayed,
  }) {
    final onTimeScore = wasOnTime ? 100.0 : 0.0;
    final proofScore = hasEpod ? 100.0 : 0.0;
    final gpsScore = gpsAccuracyPercent.clamp(0.0, 100.0);
    final delayPenalty = wasDelayed ? 100.0 : 0.0;

    final score = (onTimeScore * 0.4) +
        (proofScore * 0.2) +
        (gpsScore * 0.2) +
        (delayPenalty * -0.2);

    return score.clamp(0.0, 100.0);
  }

  /// Calculate aggregate transporter trust score from all their shipments
  Future<Map<String, dynamic>> calculateTransporterTrustScore(String transporterId) async {
    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('transporterId', isEqualTo: transporterId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'trustScore': 0.0,
          'completedTrips': 0,
          'onTimeRate': 100.0,
          'totalDelays': 0,
          'epodComplianceRate': 0.0,
          'gpsReliability': 100.0,
        };
      }

      int totalTrips = snapshot.docs.length;
      int completedTrips = 0;
      int onTimeTrips = 0;
      int delayedTrips = 0;
      int withEpod = 0;
      double totalGpsReliability = 0.0;
      int gpsDataPoints = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'created';

        if (status == 'delivered') {
          completedTrips++;
          // Check if delivered without delay flag
          if (data['delayDetectedAt'] == null) {
            onTimeTrips++;
          }
        }

        if (status == 'delayed' || data['delayDetectedAt'] != null) {
          delayedTrips++;
        }

        if (data['epodUrl'] != null && (data['epodUrl'] as String).isNotEmpty) {
          withEpod++;
        }

        // GPS reliability from location accuracy data
        final currentLocation = data['currentLocation'] as Map<String, dynamic>?;
        if (currentLocation != null) {
          gpsDataPoints++;
          // If we have location data, it's considered reliable
          totalGpsReliability += 100.0;
        }
      }

      final onTimeRate = completedTrips > 0
          ? (onTimeTrips / completedTrips * 100.0)
          : 100.0;
      final epodRate = completedTrips > 0
          ? (withEpod / completedTrips * 100.0)
          : 0.0;
      final gpsReliability = gpsDataPoints > 0
          ? (totalGpsReliability / gpsDataPoints)
          : 100.0;

      // Apply the weighted formula
      final trustScore = calculateShipmentTrustScore(
        wasOnTime: onTimeRate >= 80,
        hasEpod: epodRate >= 50,
        gpsAccuracyPercent: gpsReliability,
        wasDelayed: delayedTrips > (totalTrips * 0.3),
      );

      // Blend shipment-level score with volume bonus
      final volumeBonus = (completedTrips / 50.0).clamp(0.0, 10.0);
      final finalScore = (trustScore + volumeBonus).clamp(0.0, 100.0);

      return {
        'trustScore': double.parse(finalScore.toStringAsFixed(1)),
        'completedTrips': completedTrips,
        'onTimeRate': double.parse(onTimeRate.toStringAsFixed(1)),
        'totalDelays': delayedTrips,
        'epodComplianceRate': double.parse(epodRate.toStringAsFixed(1)),
        'gpsReliability': double.parse(gpsReliability.toStringAsFixed(1)),
      };
    } catch (e) {
      debugPrint('[TrustScoreService] Error calculating score: $e');
      return {
        'trustScore': 0.0,
        'completedTrips': 0,
        'onTimeRate': 100.0,
        'totalDelays': 0,
        'epodComplianceRate': 0.0,
        'gpsReliability': 100.0,
      };
    }
  }

  /// Recalculate and persist to both shipment and user docs
  Future<void> recalculateAndStore(String transporterId) async {
    final stats = await calculateTransporterTrustScore(transporterId);

    try {
      await _firestore.collection('users').doc(transporterId).update({
        'trustScore': stats['trustScore'],
        'completedTrips': stats['completedTrips'],
        'onTimeRate': stats['onTimeRate'],
        'totalDelays': stats['totalDelays'],
        'epodComplianceRate': stats['epodComplianceRate'],
        'gpsReliability': stats['gpsReliability'],
      });
      debugPrint('[TrustScoreService] Updated user $transporterId with score: ${stats['trustScore']}');
    } catch (e) {
      debugPrint('[TrustScoreService] Failed to update user doc: $e');
    }
  }

  /// Quick score update after a shipment event (delivery, delay, ePOD)
  Future<double> quickScoreUpdate(String shipmentId, {
    bool delivered = false,
    bool delayed = false,
    bool epodUploaded = false,
  }) async {
    try {
      final doc = await _firestore.collection('shipments').doc(shipmentId).get();
      if (!doc.exists) return 0.0;

      final data = doc.data()!;
      double currentScore = (data['trustScore'] as num?)?.toDouble() ?? 50.0;

      // Incremental adjustments
      if (delivered) currentScore += 8.0;
      if (delayed) currentScore -= 15.0;
      if (epodUploaded) currentScore += 5.0;

      currentScore = currentScore.clamp(0.0, 100.0);

      await _firestore.collection('shipments').doc(shipmentId).update({
        'trustScore': currentScore,
      });

      // Also recalculate transporter aggregate
      final transporterId = data['transporterId'] as String?;
      if (transporterId != null) {
        recalculateAndStore(transporterId); // Fire and forget
      }

      return currentScore;
    } catch (e) {
      debugPrint('[TrustScoreService] Quick update error: $e');
      return 0.0;
    }
  }
}
