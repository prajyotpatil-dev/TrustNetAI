import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini AI Service — Real API integration for AI-generated trust reports
class GeminiService {
  // Replace with your actual Gemini API key
  static const String _apiKey = 'GEMINI_API_KEY_HERE';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Generate a comprehensive trust report for a transporter
  Future<String> generateTrustReport({
    required String transporterName,
    required double trustScore,
    required int totalDelays,
    required double onTimeRate,
    required int completedTrips,
    required double epodCompliance,
    required double gpsReliability,
  }) async {
    final prompt = '''
You are an AI logistics analyst for TrustNet AI, an intelligent logistics platform.
Analyze this transporter and generate a professional trust assessment report.

TRANSPORTER DATA:
- Name: $transporterName
- Trust Score: ${trustScore.toStringAsFixed(1)}/100
- On-time Delivery Rate: ${onTimeRate.toStringAsFixed(1)}%
- Total Completed Trips: $completedTrips
- Total Delays: $totalDelays
- ePOD Compliance Rate: ${epodCompliance.toStringAsFixed(1)}%
- GPS Reliability: ${gpsReliability.toStringAsFixed(1)}%

Generate a report with the following sections (use plain text, no markdown):
1. OVERALL ASSESSMENT (2-3 sentences summarizing reliability)
2. STRENGTHS (bullet points of what they do well)
3. RISK FACTORS (any concerns based on the data)
4. RECOMMENDATION (whether recommended for high-value, medium-risk, or low-risk shipments)
5. SUGGESTED ACTIONS (specific improvement suggestions)

Be specific and data-driven. Reference the actual numbers provided.
''';

    return _callGemini(prompt);
  }

  /// Generate a risk analysis for a specific shipment
  Future<String> generateShipmentRiskAnalysis({
    required String shipmentId,
    required String fromCity,
    required String toCity,
    required String status,
    required double trustScore,
    required List<String> fraudFlags,
    required bool isDelayed,
    required double speed,
  }) async {
    final fraudInfo = fraudFlags.isEmpty
        ? 'No fraud alerts'
        : 'FRAUD ALERTS: ${fraudFlags.join(", ")}';

    final prompt = '''
You are an AI logistics risk analyst for TrustNet AI.
Analyze this shipment and provide a brief risk assessment.

SHIPMENT DATA:
- Shipment ID: $shipmentId
- Route: $fromCity → $toCity
- Current Status: $status
- Trust Score: ${trustScore.toStringAsFixed(1)}/100
- Current Speed: ${speed.toStringAsFixed(1)} km/h
- Is Delayed: ${isDelayed ? "YES" : "NO"}
- $fraudInfo

Provide:
1. Risk Level (LOW / MEDIUM / HIGH / CRITICAL)
2. Key Observations (2-3 bullet points)
3. Recommended Action (1 sentence)

Be concise and actionable. Maximum 150 words.
''';

    return _callGemini(prompt);
  }

  /// Generate a one-liner AI insight for the dashboard
  Future<String> generateDashboardInsight({
    required int totalShipments,
    required int activeShipments,
    required int delayedShipments,
    required double avgTrustScore,
    required int fraudAlerts,
  }) async {
    final prompt = '''
You are an AI logistics analyst. Based on this business dashboard data, generate ONE concise insight sentence (max 20 words):
- Total shipments: $totalShipments
- Active: $activeShipments  
- Delayed: $delayedShipments
- Average trust score: ${avgTrustScore.toStringAsFixed(0)}/100
- Fraud alerts: $fraudAlerts

Example format: "3 shipments at risk of delay — consider reassigning Delhi route to higher-rated transporters."
''';

    return _callGemini(prompt);
  }

  /// Core API call to Gemini
  Future<String> _callGemini(String prompt) async {
    try {
      if (_apiKey == 'GEMINI_API_KEY_HERE') {
        return _generateFallbackReport(prompt);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString();
        }
        return _generateFallbackReport(prompt);
      } else {
        debugPrint('[GeminiService] API error ${response.statusCode}: ${response.body}');
        return _generateFallbackReport(prompt);
      }
    } catch (e) {
      debugPrint('[GeminiService] Error: $e');
      return _generateFallbackReport(prompt);
    }
  }

  /// Rule-based fallback when Gemini API is unavailable
  String _generateFallbackReport(String prompt) {
    // Extract score from prompt
    final scoreMatch = RegExp(r'Trust Score: (\d+\.?\d*)').firstMatch(prompt);
    final score = scoreMatch != null ? double.tryParse(scoreMatch.group(1)!) ?? 50 : 50;

    final delayMatch = RegExp(r'Total Delays: (\d+)').firstMatch(prompt);
    final delays = delayMatch != null ? int.tryParse(delayMatch.group(1)!) ?? 0 : 0;

    final onTimeMatch = RegExp(r'On-time.*?Rate: (\d+\.?\d*)').firstMatch(prompt);
    final onTimeRate = onTimeMatch != null ? double.tryParse(onTimeMatch.group(1)!) ?? 80 : 80;

    String riskLevel;
    String assessment;
    String recommendation;

    if (score >= 80) {
      riskLevel = 'LOW RISK';
      assessment = 'Transporter demonstrates excellent reliability with a trust score of ${score.toStringAsFixed(0)}/100. '
          'On-time delivery rate of ${onTimeRate.toStringAsFixed(0)}% indicates consistent performance.';
      recommendation = 'Recommended for high-value and time-sensitive shipments.';
    } else if (score >= 60) {
      riskLevel = 'MEDIUM RISK';
      assessment = 'Transporter shows moderate reliability with a trust score of ${score.toStringAsFixed(0)}/100. '
          '$delays delays recorded. Performance is adequate but has room for improvement.';
      recommendation = 'Suitable for standard shipments. Monitor closely for time-critical deliveries.';
    } else {
      riskLevel = 'HIGH RISK';
      assessment = 'Transporter has a concerning trust score of ${score.toStringAsFixed(0)}/100. '
          '$delays delays recorded with ${onTimeRate.toStringAsFixed(0)}% on-time rate. Significant reliability concerns.';
      recommendation = 'Not recommended for high-value shipments. Consider for low-priority routes only.';
    }

    return '''
OVERALL ASSESSMENT — $riskLevel
$assessment

STRENGTHS
${score >= 60 ? '• Has completed shipments successfully\n• Maintains GPS tracking during transit' : '• GPS tracking available'}
${onTimeRate >= 70 ? '• Above-average on-time delivery rate' : ''}

RISK FACTORS
${delays > 0 ? '• $delays delivery delays recorded' : '• No delay data available yet'}
${score < 60 ? '• Trust score below acceptable threshold' : ''}
${onTimeRate < 80 ? '• On-time rate below 80% target' : ''}

RECOMMENDATION
$recommendation

SUGGESTED ACTIONS
${score < 80 ? '• Increase ePOD compliance to improve trust score\n• Maintain consistent GPS tracking during all shipments' : '• Continue current performance level\n• Consider for premium route assignments'}
${delays > 2 ? '• Review route planning to reduce delays\n• Consider load optimization' : ''}
''';
  }
}
