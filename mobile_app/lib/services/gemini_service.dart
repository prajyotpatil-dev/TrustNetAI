import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Gemini AI Service — Routes all AI through Firebase Cloud Functions
/// No client-side API key — all calls go through the secure backend
class GeminiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate a comprehensive trust report for a transporter
  Future<String> generateTrustReport({
    required String transporterId,
    // Kept for fallback compatibility
    String? transporterName,
    double? trustScore,
    int? totalDelays,
    double? onTimeRate,
    int? completedTrips,
    double? epodCompliance,
    double? gpsReliability,
  }) async {
    return _callCloudFunction(
      type: 'trust_report',
      transporterId: transporterId,
      fallbackData: {
        'trustScore': trustScore ?? 0,
        'totalDelays': totalDelays ?? 0,
        'onTimeRate': onTimeRate ?? 0,
        'completedTrips': completedTrips ?? 0,
        'epodCompliance': epodCompliance ?? 0,
        'gpsReliability': gpsReliability ?? 0,
      },
    );
  }

  /// Generate fraud analysis for a transporter
  Future<String> generateFraudAnalysis({
    required String transporterId,
  }) async {
    return _callCloudFunction(
      type: 'fraud_analysis',
      transporterId: transporterId,
    );
  }

  /// Generate delivery prediction for a transporter
  Future<String> generateDeliveryPrediction({
    required String transporterId,
  }) async {
    return _callCloudFunction(
      type: 'delivery_prediction',
      transporterId: transporterId,
    );
  }

  /// Generate a one-liner AI insight for the dashboard
  /// This still uses the direct prompt approach for speed
  Future<String> generateDashboardInsight({
    required int totalShipments,
    required int activeShipments,
    required int delayedShipments,
    required double avgTrustScore,
    required int fraudAlerts,
  }) async {
    // Dashboard insight is lightweight — use local generation for speed
    return _generateLocalInsight(
      totalShipments: totalShipments,
      activeShipments: activeShipments,
      delayedShipments: delayedShipments,
      avgTrustScore: avgTrustScore,
      fraudAlerts: fraudAlerts,
    );
  }

  /// Core Cloud Function caller
  Future<String> _callCloudFunction({
    required String type,
    required String transporterId,
    Map<String, dynamic>? fallbackData,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateAIReport',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'type': type,
        'transporterId': transporterId,
      });

      final data = result.data;
      if (data['success'] == true && data['report'] != null) {
        return data['report'] as String;
      }

      return _generateFallbackReport(type, fallbackData);
    } catch (e) {
      debugPrint('[GeminiService] Cloud Function error: $e');
      return _generateFallbackReport(type, fallbackData);
    }
  }

  /// Local dashboard insight (no Cloud Function needed)
  String _generateLocalInsight({
    required int totalShipments,
    required int activeShipments,
    required int delayedShipments,
    required double avgTrustScore,
    required int fraudAlerts,
  }) {
    if (totalShipments == 0) {
      return 'No shipments yet — create your first shipment to start building trust intelligence.';
    }

    final parts = <String>[];

    if (delayedShipments > 0) {
      parts.add('$delayedShipments shipment${delayedShipments > 1 ? 's' : ''} delayed');
    }
    if (fraudAlerts > 0) {
      parts.add('$fraudAlerts fraud alert${fraudAlerts > 1 ? 's' : ''} detected');
    }
    if (avgTrustScore < 60) {
      parts.add('avg trust score below threshold (${avgTrustScore.toStringAsFixed(0)})');
    }

    if (parts.isEmpty) {
      if (avgTrustScore >= 80) {
        return 'All systems healthy — $activeShipments active shipments on track with strong ${avgTrustScore.toStringAsFixed(0)} trust score.';
      }
      return '$activeShipments active shipments tracking normally. Average trust score: ${avgTrustScore.toStringAsFixed(0)}/100.';
    }

    return '⚠ ${parts.join(' · ')} — review recommended.';
  }

  /// Rule-based fallback when Cloud Function is unavailable
  String _generateFallbackReport(String type, Map<String, dynamic>? data) {
    switch (type) {
      case 'trust_report':
        return _fallbackTrustReport(data);
      case 'fraud_analysis':
        return _fallbackFraudAnalysis();
      case 'delivery_prediction':
        return _fallbackDeliveryPrediction(data);
      default:
        return 'AI analysis is temporarily unavailable. Please try again later.';
    }
  }

  String _fallbackTrustReport(Map<String, dynamic>? data) {
    final score = (data?['trustScore'] as num?)?.toDouble() ?? 50;
    final onTime = (data?['onTimeRate'] as num?)?.toDouble() ?? 80;
    final delays = (data?['totalDelays'] as num?)?.toInt() ?? 0;

    String riskLevel;
    String assessment;
    String recommendation;

    if (score >= 80) {
      riskLevel = 'LOW RISK';
      assessment = 'Transporter demonstrates excellent reliability with a trust score of ${score.toStringAsFixed(0)}/100. '
          'On-time delivery rate of ${onTime.toStringAsFixed(0)}% indicates consistent performance.';
      recommendation = 'Recommended for high-value and time-sensitive shipments.';
    } else if (score >= 60) {
      riskLevel = 'MEDIUM RISK';
      assessment = 'Transporter shows moderate reliability with a trust score of ${score.toStringAsFixed(0)}/100. '
          '$delays delays recorded. Performance adequate but room for improvement.';
      recommendation = 'Suitable for standard shipments. Monitor closely for time-critical deliveries.';
    } else {
      riskLevel = 'HIGH RISK';
      assessment = 'Trust score of ${score.toStringAsFixed(0)}/100 raises significant reliability concerns. '
          '$delays delays recorded with ${onTime.toStringAsFixed(0)}% on-time rate.';
      recommendation = 'Not recommended for high-value shipments. Consider for low-priority routes only.';
    }

    return '''OVERALL ASSESSMENT — $riskLevel
$assessment

STRENGTHS
${score >= 60 ? '• Has completed shipments successfully\n• Maintains GPS tracking during transit' : '• GPS tracking available'}
${onTime >= 70 ? '• Above-average on-time delivery rate' : ''}

RISK FACTORS
${delays > 0 ? '• $delays delivery delays recorded' : '• No delay data available yet'}
${score < 60 ? '• Trust score below acceptable threshold' : ''}

RECOMMENDATION
$recommendation

SUGGESTED ACTIONS
${score < 80 ? '• Increase ePOD compliance to improve trust score\n• Maintain consistent GPS tracking' : '• Continue current performance level'}
${delays > 2 ? '• Review route planning to reduce delays' : ''}''';
  }

  String _fallbackFraudAnalysis() {
    return '''FRAUD RISK LEVEL: PENDING ANALYSIS

Unable to connect to AI analysis engine. Please check your connection and try again.

In the meantime, review the fraud flags listed on your dashboard for any manual assessment.''';
  }

  String _fallbackDeliveryPrediction(Map<String, dynamic>? data) {
    final score = (data?['trustScore'] as num?)?.toDouble() ?? 50;

    String risk;
    if (score >= 80) {
      risk = 'LOW';
    } else if (score >= 60) {
      risk = 'MEDIUM';
    } else {
      risk = 'HIGH';
    }

    return '''DELAY PROBABILITY: ${score >= 80 ? '< 10%' : score >= 60 ? '20-35%' : '40-60%'}

FAILURE RISK: $risk
Based on historical trust score of ${score.toStringAsFixed(0)}/100.

EXPECTED BEHAVIOR:
${score >= 80 ? 'Reliable performance expected. Transporter has demonstrated consistent delivery patterns.' : score >= 60 ? 'Moderate gaps may occur. Monitor actively for signs of delay.' : 'High probability of service issues. Recommend backup transporter assignment.'}

Unable to generate full AI prediction. Please try again when connected.''';
  }
}
