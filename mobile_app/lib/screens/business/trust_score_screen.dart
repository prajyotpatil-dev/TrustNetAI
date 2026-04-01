import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../providers/ai_provider.dart';

/// Trust Score Screen — Live Firestore data with weighted formula display
class TrustScoreScreen extends StatelessWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'transporter')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final transporters = <Map<String, dynamic>>[];
          int excellentCount = 0;
          int goodCount = 0;
          int poorCount = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final score = (data['trustScore'] as num?)?.toDouble() ?? 0.0;
            final name = data['name'] as String? ?? 'Transporter';
            final trips = (data['completedTrips'] as num?)?.toInt() ?? 0;
            final onTime = (data['onTimeRate'] as num?)?.toDouble() ?? 100.0;
            final epod = (data['epodComplianceRate'] as num?)?.toDouble() ?? 0.0;
            final gps = (data['gpsReliability'] as num?)?.toDouble() ?? 100.0;
            final delays = (data['totalDelays'] as num?)?.toInt() ?? 0;

            if (score >= 80) excellentCount++;
            else if (score >= 60) goodCount++;
            else poorCount++;

            transporters.add({
              'id': doc.id,
              'name': name,
              'score': score,
              'trips': trips,
              'onTime': onTime,
              'epod': epod,
              'gps': gps,
              'delays': delays,
            });
          }

          // Sort by score descending
          transporters.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Trust Scores', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('AI-powered transporter ratings', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),

                // ── Formula Card ──────────────────────────────────────────
                Card(
                  elevation: 0,
                  color: const Color(0xFFF5F3FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.purple, size: 20),
                            SizedBox(width: 8),
                            Text('AI Trust Formula', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _formulaRow('On-time Delivery', '40%', Colors.green),
                        _formulaRow('ePOD Compliance', '20%', Colors.blue),
                        _formulaRow('GPS Reliability', '20%', Colors.indigo),
                        _formulaRow('Delay Penalty', '-20%', Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Summary Chips ─────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  children: [
                    _summaryChip('$excellentCount Excellent (80+)', Colors.green),
                    _summaryChip('$goodCount Good (60-79)', Colors.orange),
                    _summaryChip('$poorCount Poor (<60)', Colors.red),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Transporter Cards ─────────────────────────────────────
                if (transporters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No transporters found.', style: TextStyle(color: Colors.black54))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transporters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final t = transporters[i];
                      final score = (t['score'] as double);
                      final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
                      final riskLabel = score >= 80 ? 'Low Risk' : score >= 60 ? 'Medium Risk' : 'High Risk';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Header
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.12),
                                    child: Text(
                                      (t['name'] as String)[0],
                                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(riskLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      score.toStringAsFixed(0),
                                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Score bar
                              LinearProgressIndicator(
                                value: score / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 14),

                              // Metrics grid
                              Row(
                                children: [
                                  _metricTile(Icons.inventory_2, '${t['trips']}', 'Trips', Colors.blue),
                                  _metricTile(Icons.access_time, '${(t['onTime'] as double).toStringAsFixed(0)}%', 'On-time', Colors.green),
                                  _metricTile(Icons.camera_alt, '${(t['epod'] as double).toStringAsFixed(0)}%', 'ePOD', Colors.indigo),
                                  _metricTile(Icons.gps_fixed, '${(t['gps'] as double).toStringAsFixed(0)}%', 'GPS', Colors.teal),
                                ],
                              ),

                              // Delays warning
                              if ((t['delays'] as int) > 0) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${t['delays']} delays recorded',
                                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ── Generate AI Report Button ───────────────
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showAIReport(context, t),
                                  icon: const Icon(Icons.auto_awesome, size: 16),
                                  label: const Text('Generate AI Report', style: TextStyle(fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(color: Colors.purple),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAIReport(BuildContext context, Map<String, dynamic> transporter) {
    final ai = context.read<AIProvider>();
    ai.fetchGeminiReport(
      transporterName: transporter['name'] as String,
      trustScore: transporter['score'] as double,
      totalDelays: transporter['delays'] as int,
      onTimeRate: transporter['onTime'] as double,
      completedTrips: transporter['trips'] as int,
      epodCompliance: transporter['epod'] as double,
      gpsReliability: transporter['gps'] as double,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Consumer<AIProvider>(
          builder: (ctx, ai, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'AI Trust Report — ${transporter['name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (ai.isLoadingReport)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.purple),
                          SizedBox(height: 16),
                          Text('Gemini is analyzing...', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  else if (ai.reportError != null)
                    Text('Error: ${ai.reportError}', style: const TextStyle(color: Colors.red))
                  else if (ai.geminiReport != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SelectableText(
                        ai.geminiReport!,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formulaRow(String label, String weight, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(weight, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _metricTile(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }
}
