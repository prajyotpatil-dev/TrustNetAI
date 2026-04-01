import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_layout.dart';
import '../../providers/ai_provider.dart';



/// Smart Transporter Assignment — AI-ranked recommendations
class SmartAssignmentScreen extends StatefulWidget {
  const SmartAssignmentScreen({super.key});

  @override
  State<SmartAssignmentScreen> createState() => _SmartAssignmentScreenState();
}

class _SmartAssignmentScreenState extends State<SmartAssignmentScreen> {
  final _cityController = TextEditingController(text: 'Mumbai');


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRankings();
    });
  }

  void _loadRankings() {
    context.read<AIProvider>().getSmartAssignments(_cityController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Smart Assignment', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('AI-recommended transporters for your shipment', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            // ── City Input ────────────────────────────────────────────────
            Card(
              elevation: 0,
              color: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup City',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _loadRankings(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _loadRankings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Find', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── AI Formula Card ───────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.purple.shade100),
              ),
              color: Colors.purple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ranking = Trust Score (60%) + Proximity (40%)',
                        style: TextStyle(fontSize: 13, color: Colors.purple, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Rankings List ─────────────────────────────────────────────
            Consumer<AIProvider>(
              builder: (context, ai, child) {
                if (ai.isLoadingRankings) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('AI is analyzing transporters...', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                }

                final rankings = ai.transporterRankings;
                if (rankings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No transporters found. Try a different city.', style: TextStyle(color: Colors.black54)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = rankings[i];
                    final compositeScore = (t['compositeScore'] as double);
                    final trustScore = (t['trustScore'] as double);
                    final isTopPick = t['isTopPick'] as bool;
                    final scoreColor = compositeScore >= 70 ? Colors.green : compositeScore >= 50 ? Colors.orange : Colors.red;

                    return Card(
                      elevation: isTopPick ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isTopPick ? Colors.green.shade400 : Colors.grey.shade200,
                          width: isTopPick ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header row
                            Row(
                              children: [
                                // Rank badge
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == 0 ? Colors.amber : i == 1 ? Colors.grey.shade400 : i == 2 ? Colors.brown.shade300 : Colors.grey.shade200,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: i < 3 ? Colors.white : Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (isTopPick) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.green.shade300),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.star, size: 12, color: Colors.green),
                                                  SizedBox(width: 2),
                                                  Text('AI Pick', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(t['reason'] as String, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      compositeScore.toStringAsFixed(0),
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scoreColor),
                                    ),
                                    const Text('score', style: TextStyle(fontSize: 10, color: Colors.black38)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Score bars
                            Row(
                              children: [
                                Expanded(
                                  child: _scoreBar('Trust', trustScore, Colors.blue),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _scoreBar('Proximity', (t['proximityScore'] as double), Colors.purple),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Metrics row
                            Row(
                              children: [
                                _metric(Icons.inventory_2, '${t['completedTrips']} trips'),
                                const SizedBox(width: 16),
                                _metric(Icons.access_time, '${(t['onTimeRate'] as double).toStringAsFixed(0)}% on-time'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            Text('${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
