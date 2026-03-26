import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';

class TrustScoreScreen extends StatelessWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transporters = [
      {'name': 'Rajesh Logistics', 'score': 92, 'trips': 145, 'onTime': '97%'},
      {'name': 'Singh Carriers', 'score': 86, 'trips': 89, 'onTime': '91%'},
      {'name': 'Kumar Transport', 'score': 74, 'trips': 210, 'onTime': '82%'},
      {'name': 'Delhi Express', 'score': 68, 'trips': 56, 'onTime': '76%'},
      {'name': 'Fast Freight Co', 'score': 55, 'trips': 34, 'onTime': '68%'},
    ];

    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Trust Scores', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Monitor your partner transporters', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          // Summary Chips
          Row(children: [
            _summaryChip('Excellent (80+)', 2, Colors.green),
            const SizedBox(width: 8),
            _summaryChip('Good (60-79)', 2, Colors.orange),
            const SizedBox(width: 8),
            _summaryChip('Poor (<60)', 1, Colors.red),
          ]),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transporters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = transporters[i];
              final score = t['score'] as int;
              final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Text('${(t['name'] as String)[0]}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: score / 100, backgroundColor: Colors.grey.shade200, color: color, minHeight: 6),
                    const SizedBox(height: 12),
                    Row(children: [
                      _scoreMetric(Icons.inventory_2, '${t['trips']} trips', Colors.blue),
                      const SizedBox(width: 16),
                      _scoreMetric(Icons.access_time, '${t['onTime']} on-time', Colors.green),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$count $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _scoreMetric(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ]);
  }
}
