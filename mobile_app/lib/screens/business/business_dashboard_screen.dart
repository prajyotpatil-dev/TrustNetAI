import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/business_shipment_provider.dart';
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
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Active Shipments', context.watch<BusinessShipmentProvider>().activeShipmentsCount.toString(), 'In transit & pickup', Icons.inventory_2, Colors.blue),
                _buildStatCard('Delivered', context.watch<BusinessShipmentProvider>().completedShipmentsCount.toString(), 'On time delivery', Icons.check_circle, Colors.green),
                _buildTrustScoreCard(context.watch<BusinessShipmentProvider>().averageTrustScore.toStringAsFixed(0)),
                _buildStatCard('Risk Alerts', context.watch<BusinessShipmentProvider>().riskAlertsCount.toString(), 'Requires attention', Icons.warning_amber_rounded, Colors.red),
              ],
            ),
            
            const SizedBox(height: 24),

            // Active Shipments section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Shipments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
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
                    itemCount: shipments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final shipment = shipments[index];
                      final statusColor = _getStatusColor(shipment.status);
                      final statusLabel = _getStatusLabel(shipment.status);
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(shipment.lrNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                Text(shipment.trustScore.toStringAsFixed(0), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
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
            
            _buildActionCard(context, 'Create Shipment', 'Generate digital LR/bilty', Icons.add_circle, Colors.orange, '/business/create'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'View Trust Scores', 'Monitor partner ratings', Icons.trending_up, Colors.blue, '/business/trust-score'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'AI Risk Report', 'View AI insights', Icons.warning_amber, Colors.purple, '/business/risk-report'),
            const SizedBox(height: 8),
            _buildActionCard(context, 'Network Trust', 'Partner network view', Icons.hub, Colors.green, '/business/network-trust'),
            
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
    int score = int.parse(scoreStr);
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
            Text(scoreStr, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
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
                  color: color.withOpacity(0.1),
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
}
