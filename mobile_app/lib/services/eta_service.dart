/// Predictive ETA Service — Enhanced estimation with traffic awareness
class ETAService {
  /// Calculate predictive ETA with traffic multipliers
  /// Returns estimated hours to destination
  double calculatePredictiveETA({
    required double distanceKm,
    double avgSpeedKmh = 45.0,
    DateTime? currentTime,
  }) {
    currentTime ??= DateTime.now();
    final hour = currentTime.hour;
    final isWeekend = currentTime.weekday >= 6;

    // Base ETA
    double etaHours = distanceKm / avgSpeedKmh;

    // Traffic multipliers based on time of day
    double trafficMultiplier = 1.0;

    if (hour >= 8 && hour <= 10) {
      // Morning rush
      trafficMultiplier = 1.25; // +25%
    } else if (hour >= 17 && hour <= 20) {
      // Evening rush
      trafficMultiplier = 1.30; // +30%
    } else if (hour >= 23 || hour <= 5) {
      // Night driving (faster, less traffic)
      trafficMultiplier = 0.85; // -15%
    } else if (hour >= 12 && hour <= 14) {
      // Midday moderate
      trafficMultiplier = 1.10; // +10%
    }

    // Weekend adjustment (less commercial traffic)
    if (isWeekend) {
      trafficMultiplier *= 0.90; // 10% faster on weekends
    }

    etaHours *= trafficMultiplier;

    // Add buffer for stops and breaks
    if (etaHours > 6) {
      etaHours += 0.5; // 30min break for long trips
    }
    if (etaHours > 12) {
      etaHours += 1.0; // Additional 1h rest for very long trips
    }

    return etaHours;
  }

  /// Get a human-readable ETA string
  String getETADisplay({
    required double distanceKm,
    double avgSpeedKmh = 45.0,
    DateTime? currentTime,
  }) {
    final etaHours = calculatePredictiveETA(
      distanceKm: distanceKm,
      avgSpeedKmh: avgSpeedKmh,
      currentTime: currentTime,
    );

    if (etaHours < 1) {
      return '${(etaHours * 60).round()} min';
    } else if (etaHours < 24) {
      final hours = etaHours.floor();
      final minutes = ((etaHours - hours) * 60).round();
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final days = (etaHours / 24).floor();
      final remainingHours = (etaHours - (days * 24)).floor();
      return remainingHours > 0 ? '${days}d ${remainingHours}h' : '${days}d';
    }
  }

  /// Get traffic condition label for current time
  String getTrafficCondition({DateTime? currentTime}) {
    currentTime ??= DateTime.now();
    final hour = currentTime.hour;

    if (hour >= 8 && hour <= 10) return 'Heavy Traffic';
    if (hour >= 17 && hour <= 20) return 'Peak Traffic';
    if (hour >= 23 || hour <= 5) return 'Light Traffic';
    if (hour >= 12 && hour <= 14) return 'Moderate Traffic';
    return 'Normal Traffic';
  }

  /// Get traffic condition color hex for UI display
  int getTrafficConditionColor({DateTime? currentTime}) {
    currentTime ??= DateTime.now();
    final hour = currentTime.hour;

    if (hour >= 8 && hour <= 10) return 0xFFE65100;  // Deep orange
    if (hour >= 17 && hour <= 20) return 0xFFD32F2F;  // Red
    if (hour >= 23 || hour <= 5) return 0xFF2E7D32;   // Green
    if (hour >= 12 && hour <= 14) return 0xFFF9A825;   // Yellow
    return 0xFF1976D2;                                  // Blue
  }

  /// Calculate arrival time
  DateTime getArrivalTime({
    required double distanceKm,
    double avgSpeedKmh = 45.0,
    DateTime? departureTime,
  }) {
    departureTime ??= DateTime.now();
    final etaHours = calculatePredictiveETA(
      distanceKm: distanceKm,
      avgSpeedKmh: avgSpeedKmh,
      currentTime: departureTime,
    );
    return departureTime.add(Duration(minutes: (etaHours * 60).round()));
  }
}
