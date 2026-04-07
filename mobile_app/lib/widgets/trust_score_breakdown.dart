import 'package:flutter/material.dart';
import '../models/user_model.dart';

class TrustScoreBreakdownWidget extends StatelessWidget {
  final UserModel user;

  const TrustScoreBreakdownWidget({super.key, required this.user});

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = user.trustBreakdown;

    // If we don't have a breakdown yet, show a fallback or basic stats
    if (breakdown == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Trust Score breakdown unavailable.\nComplete more shipments to generate AI insights.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    final onTimePct = (breakdown['onTimeRate'] as num?)?.toDouble() ?? 1.0;
    final proofPct = (breakdown['proofRate'] as num?)?.toDouble() ?? 1.0;
    final gpsPct = (breakdown['gpsScore'] as num?)?.toDouble() ?? 1.0;
    final cancelPenalty = (breakdown['cancelPenalty'] as num?)?.toDouble() ?? 0.0;
    final avgRating = (breakdown['avgRating'] as num?)?.toDouble() ?? 5.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trust Score Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor(user.trustScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.trustScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: _scoreColor(user.trustScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-generated based on real-time shipment activity.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildPerformanceRow('On-Time Delivery', '${(onTimePct * 100).toStringAsFixed(0)}%', onTimePct, Colors.blue),
            const SizedBox(height: 16),
            _buildPerformanceRow('ePOD Upload Compliance', '${(proofPct * 100).toStringAsFixed(0)}%', proofPct, Colors.purple),
            const SizedBox(height: 16),
            _buildPerformanceRow('GPS Tracking Consistency', '${(gpsPct * 100).toStringAsFixed(0)}%', gpsPct, Colors.teal),
            const SizedBox(height: 16),
            // For cancellation, we want a high score for low cancellation. 
            // Progress = 1 - penalty
            _buildPerformanceRow('Successful Non-Cancelled Trips', '${((1 - cancelPenalty) * 100).toStringAsFixed(0)}%', 1 - cancelPenalty, Colors.green),
            const SizedBox(height: 16),
            _buildPerformanceRow('Customer Rating', '${avgRating.toStringAsFixed(1)} / 5.0', avgRating / 5.0, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          color: color,
        ),
      ],
    );
  }
}
