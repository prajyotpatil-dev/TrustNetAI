import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Network Trust Screen — GNN-simulated partner trust graph
class NetworkTrustScreen extends StatelessWidget {
  const NetworkTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'transporter').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading network data: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final partners = <Map<String, dynamic>>[];
          int verifiedCount = 0;
          int flaggedCount = 0;
          double totalTrust = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? 'Transporter';
            final score = (data['trustScore'] as num?)?.toDouble() ?? 0.0;
            final trips = (data['completedTrips'] as num?)?.toInt() ?? 0;
            final onTime = (data['onTimeRate'] as num?)?.toDouble() ?? 100.0;
            final delays = (data['totalDelays'] as num?)?.toInt() ?? 0;
            final epod = (data['epodComplianceRate'] as num?)?.toDouble() ?? 0.0;
            final gps = (data['gpsReliability'] as num?)?.toDouble() ?? 100.0;
            
            totalTrust += score;

            String status = 'Active';
            if (score >= 80) {
              status = 'Verified';
              verifiedCount++;
            } else if (score < 60) {
              status = 'Flagged';
              flaggedCount++;
            }

            partners.add({
              'name': name,
              'trips': trips,
              'score': score,
              'status': status,
              'onTime': onTime,
              'delays': delays,
              'epod': epod,
              'gps': gps,
            });
          }

          // GNN Simulation: Network trust = average of all partner scores
          final networkTrust = partners.isNotEmpty ? totalTrust / partners.length : 0.0;

          // Sort by score descending
          partners.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Network Trust', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('GNN-simulated partner trust graph', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),

              // ── Network Health Score ─────────────────────────────────
              Card(
                elevation: 0,
                color: _networkHealthColor(networkTrust).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Network Health Score', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        networkTrust.toStringAsFixed(0),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _networkHealthColor(networkTrust)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'avg(all partner scores)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: networkTrust / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: _networkHealthColor(networkTrust),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Network Stats ───────────────────────────────────────
              Row(children: [
                Expanded(child: _networkStatCard('${partners.length}', 'Partners', Icons.people, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _networkStatCard('$verifiedCount', 'Verified', Icons.verified, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _networkStatCard('$flaggedCount', 'Flagged', Icons.flag, Colors.red)),
              ]),
              const SizedBox(height: 20),

              // ── GNN Formula Card ────────────────────────────────────
              Card(
                elevation: 0,
                color: const Color(0xFFF5F3FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.hub, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GNN Simulation: partnerTrust = avg(all connected transporter scores)',
                          style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Partner List ────────────────────────────────────────
              const Text('All Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (partners.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No transporters found in network.', style: TextStyle(color: Colors.black54))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: partners.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = partners[i];
                    final score = p['score'] as double;
                    final status = p['status'] as String;
                    final statusColor = status == 'Verified' ? Colors.green : status == 'Active' ? Colors.blue : Colors.red;
                    final scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
                    final delays = p['delays'] as int;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header row
                            Row(children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: scoreColor.withValues(alpha: 0.15),
                                child: Text(
                                  (p['name'] as String)[0],
                                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text('${p['trips']} trips', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                              ])),
                              Column(children: [
                                Text('${score.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor)),
                                const Text('score', style: TextStyle(fontSize: 11, color: Colors.black38)),
                              ]),
                            ]),

                            // Trust breakdown
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _miniMetric('On-time', '${(p['onTime'] as double).toStringAsFixed(0)}%', Colors.green),
                                _miniMetric('ePOD', '${(p['epod'] as double).toStringAsFixed(0)}%', Colors.blue),
                                _miniMetric('GPS', '${(p['gps'] as double).toStringAsFixed(0)}%', Colors.indigo),
                                if (delays > 0)
                                  _miniMetric('Delays', '$delays', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ]),
          );
        },
      ),
    );
  }

  Color _networkHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _networkStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }
}
