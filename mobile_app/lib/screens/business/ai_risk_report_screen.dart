import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../providers/ai_provider.dart';


/// AI Risk Report — Live data + Gemini AI intelligence
class AIRiskReportScreen extends StatefulWidget {
  const AIRiskReportScreen({super.key});

  @override
  State<AIRiskReportScreen> createState() => _AIRiskReportScreenState();
}

class _AIRiskReportScreenState extends State<AIRiskReportScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runScan());
  }

  void _runScan() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    context.read<AIProvider>().scanFraudAlerts(uid);
    context.read<AIProvider>().scanDelays(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return AppLayout(
      role: 'business',
      child: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shipments')
                  .where('businessId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Calculate live metrics
                int totalShipments = 0;
                int activeShipments = 0;
                int delayedShipments = 0;
                int deliveredShipments = 0;
                double totalTrustScore = 0;
                int fraudFlaggedCount = 0;
                final fraudAlerts = <Map<String, dynamic>>[];
                final delayedList = <Map<String, dynamic>>[];

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  totalShipments = docs.length;

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'created';
                    final score = (data['trustScore'] as num?)?.toDouble() ?? 0.0;
                    final flags = (data['fraudFlags'] as List<dynamic>?) ?? [];

                    totalTrustScore += score;

                    if (status == 'delivered') {
                      deliveredShipments++;
                    } else {
                      activeShipments++;
                    }

                    if (status == 'delayed') {
                      delayedShipments++;
                      delayedList.add({
                        'id': doc.id,
                        'lrNumber': data['lrNumber'] ?? 'Unknown',
                        'fromCity': data['fromCity'] ?? '',
                        'toCity': data['toCity'] ?? '',
                      });
                    }

                    if (flags.isNotEmpty) {
                      fraudFlaggedCount++;
                      for (final flag in flags) {
                        fraudAlerts.add({
                          'shipmentId': doc.id,
                          'lrNumber': data['lrNumber'] ?? 'Unknown',
                          'flag': flag.toString(),
                        });
                      }
                    }
                  }
                }

                final avgTrust = totalShipments > 0 ? totalTrustScore / totalShipments : 0.0;
                final onTimeRate = deliveredShipments > 0
                    ? ((deliveredShipments - delayedShipments) / deliveredShipments * 100).clamp(0.0, 100.0)
                    : 100.0;

                // Determine overall risk level
                String riskLevel;
                Color riskColor;
                IconData riskIcon;
                if (fraudAlerts.isNotEmpty || delayedShipments > totalShipments * 0.3) {
                  riskLevel = 'High Risk Level';
                  riskColor = Colors.red;
                  riskIcon = Icons.error_outline;
                } else if (delayedShipments > 0 || avgTrust < 70) {
                  riskLevel = 'Medium Risk Level';
                  riskColor = Colors.orange;
                  riskIcon = Icons.warning_amber_rounded;
                } else {
                  riskLevel = 'Low Risk Level';
                  riskColor = Colors.green;
                  riskIcon = Icons.check_circle_outline;
                }

                final alertCount = fraudAlerts.length + delayedShipments;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Risk Report', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              Text('Powered by predictive intelligence', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                          IconButton(
                            onPressed: _runScan,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Re-scan',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Overall Risk Banner ─────────────────────────────
                      Card(
                        elevation: 0,
                        color: riskColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: Icon(riskIcon, color: riskColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(riskLevel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: riskColor)),
                                    Text(
                                      '$alertCount active alert${alertCount == 1 ? '' : 's'} detected by AI',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Fraud Alerts ────────────────────────────────────
                      if (fraudAlerts.isNotEmpty) ...[
                        const Text('🚨 Fraud Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...fraudAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRiskCard(
                            'Fraud Detected — ${alert['lrNumber']}',
                            alert['flag'] as String,
                            Colors.red,
                            Icons.gpp_bad,
                          ),
                        )),
                        const SizedBox(height: 10),
                      ],

                      // ── Delayed Shipments ───────────────────────────────
                      if (delayedList.isNotEmpty) ...[
                        const Text('⏰ Delayed Shipments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...delayedList.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRiskCard(
                            'Delay Alert — ${d['lrNumber']}',
                            '${d['fromCity']} → ${d['toCity']} has exceeded expected delivery time',
                            Colors.orange,
                            Icons.access_time,
                          ),
                        )),
                        const SizedBox(height: 10),
                      ],

                      if (fraudAlerts.isEmpty && delayedList.isEmpty)
                        Card(
                          elevation: 0,
                          color: Colors.green.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.verified_user, color: Colors.green, size: 40),
                                SizedBox(height: 12),
                                Text('All Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                Text('No active fraud or delay alerts', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── AI Insight ──────────────────────────────────────
                      const Text('🧠 AI Insight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Consumer<AIProvider>(
                        builder: (context, ai, _) {
                          return Card(
                            elevation: 0,
                            color: const Color(0xFFF5F3FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.purple),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ai.isLoadingInsight
                                        ? const Text('Analyzing patterns...', style: TextStyle(color: Colors.purple, fontStyle: FontStyle.italic))
                                        : Text(
                                            ai.dashboardInsight ?? 'Tap refresh to generate AI insights for your shipments.',
                                            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w500),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Gemini Deep Analysis ──────────────────────────────
                      const Text('🤖 Gemini Deep Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Consumer<AIProvider>(
                        builder: (context, ai, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Fraud Analysis Button + Result
                              _buildAIActionCard(
                                title: 'AI Fraud Analysis',
                                subtitle: 'Deep scan for anomalies using Gemini',
                                icon: Icons.security,
                                color: const Color(0xFFDC2626),
                                isLoading: ai.isLoadingFraudAnalysis,
                                result: ai.fraudAnalysisReport,
                                onGenerate: () {
                                  context.read<AIProvider>().fetchFraudAnalysis(transporterId: uid);
                                },
                              ),
                              const SizedBox(height: 12),

                              // Delivery Prediction Button + Result
                              _buildAIActionCard(
                                title: 'AI Delivery Prediction',
                                subtitle: 'Predict delays and failure risks',
                                icon: Icons.trending_up,
                                color: const Color(0xFF7C3AED),
                                isLoading: ai.isLoadingPrediction,
                                result: ai.deliveryPrediction,
                                onGenerate: () {
                                  context.read<AIProvider>().fetchDeliveryPrediction(transporterId: uid);
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Metrics Overview ────────────────────────────────
                      const Text('📊 Risk Score Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _riskMetricRow('Total Shipments', '$totalShipments', Colors.blue),
                              const Divider(height: 24),
                              _riskMetricRow('On-Time Delivery Rate', '${onTimeRate.toStringAsFixed(0)}%', Colors.green),
                              const Divider(height: 24),
                              _riskMetricRow('Average Trust Score', '${avgTrust.toStringAsFixed(0)}/100', Colors.orange),
                              const Divider(height: 24),
                              _riskMetricRow('Fraud Alerts', '$fraudFlaggedCount', Colors.red),
                              const Divider(height: 24),
                              _riskMetricRow('Delayed Shipments', '$delayedShipments', Colors.deepOrange),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Generate Insight Report ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<AIProvider>().fetchDashboardInsight(
                              totalShipments: totalShipments,
                              activeShipments: activeShipments,
                              delayedShipments: delayedShipments,
                              avgTrustScore: avgTrust,
                              fraudAlerts: fraudFlaggedCount,
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, color: Colors.white),
                          label: const Text('Regenerate AI Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRiskCard(String title, String desc, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required String? result,
    required VoidCallback onGenerate,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    disabledBackgroundColor: color.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Generate', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(color: color, backgroundColor: color.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              Text('Gemini is analyzing...', style: TextStyle(fontSize: 12, color: color, fontStyle: FontStyle.italic)),
            ],
            if (result != null && !isLoading) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(result, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _riskMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}
