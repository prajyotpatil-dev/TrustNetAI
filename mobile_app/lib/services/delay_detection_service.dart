import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'trust_score_service.dart';

/// Delay Detection Service — Real-time delay monitoring
/// Automatically flags shipments that exceed expected delivery time
class DelayDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TrustScoreService _trustScoreService = TrustScoreService();

  /// Check if a shipment is delayed and auto-update status
  Future<bool> checkForDelay(String shipmentId) async {
    try {
      final doc = await _firestore.collection('shipments').doc(shipmentId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final status = data['status'] as String? ?? 'created';

      // Skip if already delivered or already marked delayed
      if (status == 'delivered') return false;

      // Check expected delivery time
      final expectedDeliveryRaw = data['expectedDelivery'];
      if (expectedDeliveryRaw == null) return false;

      DateTime expectedDelivery;
      if (expectedDeliveryRaw is Timestamp) {
        expectedDelivery = expectedDeliveryRaw.toDate();
      } else {
        expectedDelivery = DateTime.tryParse(expectedDeliveryRaw.toString()) ?? DateTime.now().add(const Duration(days: 1));
      }

      final now = DateTime.now();

      if (now.isAfter(expectedDelivery) && status != 'delayed') {
        // Auto-mark as delayed
        await _firestore.collection('shipments').doc(shipmentId).update({
          'status': 'delayed',
          'delayDetectedAt': FieldValue.serverTimestamp(),
        });

        // Update trust score negatively
        await _trustScoreService.quickScoreUpdate(shipmentId, delayed: true);

        debugPrint('[DelayDetection] Shipment $shipmentId auto-marked DELAYED');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[DelayDetection] Error checking delay: $e');
      return false;
    }
  }

  /// Scan all active shipments for a business and detect delays
  Future<List<String>> scanBusinessShipments(String businessId) async {
    final delayedIds = <String>[];

    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: ['in_transit', 'assigned', 'created'])
          .get();

      for (final doc in snapshot.docs) {
        final isDelayed = await checkForDelay(doc.id);
        if (isDelayed) delayedIds.add(doc.id);
      }
    } catch (e) {
      debugPrint('[DelayDetection] Scan error: $e');
    }

    return delayedIds;
  }

  /// Scan all active shipments for a transporter and detect delays
  Future<List<String>> scanTransporterShipments(String transporterId) async {
    final delayedIds = <String>[];

    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('transporterId', isEqualTo: transporterId)
          .where('status', whereIn: ['in_transit', 'assigned'])
          .get();

      for (final doc in snapshot.docs) {
        final isDelayed = await checkForDelay(doc.id);
        if (isDelayed) delayedIds.add(doc.id);
      }
    } catch (e) {
      debugPrint('[DelayDetection] Transporter scan error: $e');
    }

    return delayedIds;
  }

  /// Calculate auto-estimated delivery time based on distance and average speed
  DateTime estimateDeliveryTime({
    required double distanceKm,
    double avgSpeedKmh = 40.0,
  }) {
    // Base ETA in hours
    double etaHours = distanceKm / avgSpeedKmh;

    // Add buffer for stops, loading, breaks (20%)
    etaHours *= 1.2;

    // Add rest time for long hauls (8h rest per 14h driving - regulatory)
    if (etaHours > 14) {
      final restPeriods = (etaHours / 14).floor();
      etaHours += restPeriods * 8;
    }

    return DateTime.now().add(Duration(minutes: (etaHours * 60).round()));
  }

  /// Get count of delayed shipments for a business
  Future<int> getDelayedCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('shipments')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'delayed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
