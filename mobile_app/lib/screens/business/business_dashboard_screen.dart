import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/business_shipment_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/shipment_status.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().user?.uid;
      final role = context.read<UserProvider>().user?.role;
      if (uid != null && uid.isNotEmpty && role == 'business') {
        context.read<BusinessShipmentProvider>().listenShipments(uid);

        // Run full AI scan
        final provider = context.read<BusinessShipmentProvider>();
        context.read<AIProvider>().runFullBusinessScan(
          businessId: uid,
          totalShipments: provider.shipments.length,
          activeShipments: provider.activeShipmentsCount,
          avgTrustScore: provider.averageTrustScore,
        );
      }
    });
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
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Text(
              'Welcome back, Business User',
              style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),

            // ── AI Insight Banner ────────────────────────────────────────
            Consumer<AIProvider>(
              builder: (context, ai, _) {
                if (ai.dashboardInsight == null && !ai.isLoadingInsight) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFF5F3FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ai.isLoadingInsight
                                ? const Text('AI is analyzing...', style: TextStyle(color: Colors.purple, fontStyle: FontStyle.italic, fontSize: 13))
                                : Text(
                                    ai.dashboardInsight ?? '',
                                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Active Shipments', context.watch<BusinessShipmentProvider>().activeShipmentsCount.toString(), 'In transit & pickup', Icons.inventory_2, Colors.blue),
                _buildStatCard('Delivered', context.watch<BusinessShipmentProvider>().completedShipmentsCount.toString(), 'On time delivery', Icons.check_circle, Colors.green),
                _buildTrustScoreCard(context.watch<BusinessShipmentProvider>().averageTrustScore.toStringAsFixed(0)),
                Consumer<AIProvider>(
                  builder: (context, ai, _) {
                    final riskCount = context.watch<BusinessShipmentProvider>().riskAlertsCount + ai.fraudAlertCount;
                    return _buildStatCard('Risk Alerts', '$riskCount', 'Delays + Fraud', Icons.warning_amber_rounded, Colors.red);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Active Shipments section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Shipments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/business/track'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Consumer<BusinessShipmentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.shipments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.error != null) {
                    final isPreparing = provider.error == "Preparing shipment database, please wait...";
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isPreparing ? Icons.storage : Icons.error_outline, 
                              color: isPreparing ? Colors.blue : Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(provider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: isPreparing ? Colors.blue.shade700 : Colors.red, fontWeight: FontWeight.bold)
                            ),
                            if (isPreparing) const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: LinearProgressIndicator(),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final shipments = provider.shipments;
                  if (shipments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No shipments found", style: TextStyle(color: Colors.black54)),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shipments.length > 5 ? 5 : shipments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final shipment = shipments[index];
                      final statusColor = _getStatusColor(shipment.status);
                      final statusLabel = _getStatusLabel(shipment.status);
                      final hasFraud = shipment.fraudFlags.isNotEmpty;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(shipment.lrNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (hasFraud) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.gpp_bad, color: Colors.red, size: 16),
                                  ],
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: statusColor,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${shipment.fromCity} → ${shipment.toCity}', style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Trust Score: ', style: TextStyle(fontSize: 12)),
                                Text(shipment.trustScore.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _scoreColor(shipment.trustScore))),
                                if (shipment.speed > 0) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.speed, size: 14, color: Colors.green.shade600),
                                  const SizedBox(width: 2),
                                  Text('${shipment.speed.toStringAsFixed(0)} km/h',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/business/track/${shipment.shipmentId}'),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            _buildActionCard(context, 'Create Shipment', 'Generate digital LR with QR code', Icons.add_circle, Colors.orange, '/business/create'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'Smart Assignment', 'AI-recommended transporters', Icons.psychology, Colors.purple, '/business/smart-assign'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'View Trust Scores', 'AI-weighted partner ratings', Icons.trending_up, Colors.blue, '/business/trust-score'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'AI Risk Report', 'Fraud detection & delay alerts', Icons.warning_amber, Colors.red, '/business/risk-report'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'Network Trust', 'GNN partner network view', Icons.hub, Colors.green, '/business/network-trust'),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color == Colors.red ? color : Colors.black87)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: color == Colors.red ? color : Colors.black54), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreCard(String scoreStr) {
    final score = double.tryParse(scoreStr) ?? 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Avg Trust Score', style: TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1)),
                Icon(Icons.shield, size: 16, color: Colors.green),
              ],
            ),
            Text(scoreStr, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _scoreColor(score))),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              color: _scoreColor(score),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending: return Colors.grey;
      case ShipmentStatus.assigned: return Colors.cyan;
      case ShipmentStatus.created: return Colors.orange;
      case ShipmentStatus.inTransit: return Colors.blue;
      case ShipmentStatus.delivered: return Colors.green;
      case ShipmentStatus.delayed: return Colors.red;
    }
  }

  String _getStatusLabel(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending: return 'Pending';
      case ShipmentStatus.assigned: return 'Assigned';
      case ShipmentStatus.created: return 'Created';
      case ShipmentStatus.inTransit: return 'In Transit';
      case ShipmentStatus.delivered: return 'Delivered';
      case ShipmentStatus.delayed: return 'Delayed';
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
