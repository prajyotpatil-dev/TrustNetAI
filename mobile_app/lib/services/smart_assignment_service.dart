import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Smart Transporter Assignment — RL Simulation
/// Ranks transporters by composite: trustScore (60%) + proximity (40%)
class SmartAssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Known city coordinates for proximity calculation (expandable)
  static const Map<String, List<double>> _cityCoordinates = {
    'mumbai': [19.0760, 72.8777],
    'delhi': [28.6139, 77.2090],
    'pune': [18.5204, 73.8567],
    'bangalore': [12.9716, 77.5946],
    'chennai': [13.0827, 80.2707],
    'hyderabad': [17.3850, 78.4867],
    'kolkata': [22.5726, 88.3639],
    'ahmedabad': [23.0225, 72.5714],
    'jaipur': [26.9124, 75.7873],
    'lucknow': [26.8467, 80.9462],
    'nagpur': [21.1458, 79.0882],
    'indore': [22.7196, 75.8577],
    'surat': [21.1702, 72.8311],
    'nashik': [19.9975, 73.7898],
    'vadodara': [22.3072, 73.1812],
  };

  /// Rank all available transporters for a given shipment origin
  Future<List<Map<String, dynamic>>> rankTransporters(String fromCity) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'transporter')
          .get();

      if (snapshot.docs.isEmpty) return [];

      final rankings = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final trustScore = (data['trustScore'] as num?)?.toDouble() ?? 50.0;
        final name = data['name'] as String? ?? 'Unknown';
        final completedTrips = (data['completedTrips'] as num?)?.toInt() ?? 0;
        final onTimeRate = (data['onTimeRate'] as num?)?.toDouble() ?? 80.0;

        // Calculate proximity score (0–100) based on city matching
        double proximityScore = _calculateProximityScore(fromCity, data);

        // Composite score: 60% trust + 40% proximity
        final compositeScore = (trustScore * 0.6) + (proximityScore * 0.4);

        // Generate recommendation reason
        final reason = _generateReason(trustScore, proximityScore, completedTrips, onTimeRate);

        rankings.add({
          'transporterId': doc.id,
          'name': name,
          'trustScore': trustScore,
          'proximityScore': proximityScore,
          'compositeScore': double.parse(compositeScore.toStringAsFixed(1)),
          'completedTrips': completedTrips,
          'onTimeRate': onTimeRate,
          'reason': reason,
          'isTopPick': false, // Will be set after sorting
        });
      }

      // Sort by composite score (highest first)
      rankings.sort((a, b) =>
          (b['compositeScore'] as double).compareTo(a['compositeScore'] as double));

      // Mark top pick
      if (rankings.isNotEmpty) {
        rankings[0]['isTopPick'] = true;
      }

      return rankings;
    } catch (e) {
      debugPrint('[SmartAssignment] Error ranking transporters: $e');
      return [];
    }
  }

  /// Calculate proximity score based on transporter's last known location vs origin
  double _calculateProximityScore(String fromCity, Map<String, dynamic> transporterData) {
    // Check if transporter has last known location
    final lastLocation = transporterData['lastLocation'] as Map<String, dynamic>?;
    final fromCityNormalized = fromCity.toLowerCase().trim();
    final fromCoords = _cityCoordinates[fromCityNormalized];

    if (lastLocation != null && fromCoords != null) {
      final lat = (lastLocation['lat'] as num?)?.toDouble();
      final lng = (lastLocation['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final distance = _simpleDistance(lat, lng, fromCoords[0], fromCoords[1]);
        // Convert distance to score: 0km = 100, 1000km+ = 0
        return (100 - (distance / 10)).clamp(0.0, 100.0);
      }
    }

    // Fallback: try to match based on any city field
    final transporterCity = (transporterData['city'] as String?)?.toLowerCase().trim();
    if (transporterCity != null && transporterCity == fromCityNormalized) {
      return 90.0; // Same city
    }

    // Default moderate proximity for unknown locations
    return 50.0;
  }

  /// Simple distance approximation (good enough for ranking)
  double _simpleDistance(double lat1, double lng1, double lat2, double lng2) {
    // Approximate: 1 degree ≈ 111km
    final dLat = (lat2 - lat1) * 111;
    final dLng = (lng2 - lng1) * 111 * 0.85; // cos correction for Indian latitudes
    return (dLat * dLat + dLng * dLng);
  }

  /// Generate human-readable recommendation reason
  String _generateReason(double trustScore, double proximityScore, int trips, double onTimeRate) {
    final reasons = <String>[];

    if (trustScore >= 80) {
      reasons.add('Highly trusted (${trustScore.toStringAsFixed(0)}/100)');
    } else if (trustScore >= 60) {
      reasons.add('Reliable (${trustScore.toStringAsFixed(0)}/100)');
    }

    if (proximityScore >= 80) {
      reasons.add('Nearest to pickup');
    }

    if (trips >= 50) {
      reasons.add('Experienced ($trips trips)');
    }

    if (onTimeRate >= 90) {
      reasons.add('${onTimeRate.toStringAsFixed(0)}% on-time');
    }

    return reasons.isEmpty ? 'Available for assignment' : reasons.join(' • ');
  }

  /// Get a single best transporter recommendation
  Future<Map<String, dynamic>?> getBestTransporter(String fromCity) async {
    final rankings = await rankTransporters(fromCity);
    return rankings.isNotEmpty ? rankings.first : null;
  }
}
