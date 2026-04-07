import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transporter_shipment_provider.dart';
import '../../models/shipment_model.dart';
import '../../models/shipment_status.dart';
import '../../widgets/trust_score_breakdown.dart';

class TransporterDashboardScreen extends StatefulWidget {
  const TransporterDashboardScreen({super.key});

  @override
  State<TransporterDashboardScreen> createState() => _TransporterDashboardScreenState();
}

class _TransporterDashboardScreenState extends State<TransporterDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().user?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<TransporterShipmentProvider>().listenShipments(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.user;
            final transporterId = user?.uid ?? '';
            
            return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Transporter Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              'Welcome back, ${user?.name ?? 'Transporter'}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
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
                _buildStatCard('Active Shipments', context.watch<TransporterShipmentProvider>().activeShipmentsCount.toString(), 'In transit & pickup', Icons.inventory_2, Colors.blue),
                _buildStatCard('Completed', context.watch<TransporterShipmentProvider>().completedShipmentsCount.toString(), 'Total lifetime', Icons.check_circle, Colors.green),
                _buildStatCard('Trust Score', (user?.trustScore ?? 0).toStringAsFixed(0), 'AI Computed', Icons.star, Colors.purple, showProgress: true, progressValue: ((user?.trustScore ?? 0) / 100).clamp(0.0, 1.0)),
                _buildStatCard('On-Time Rate', '${(user?.onTimeRate ?? 100.0).toStringAsFixed(0)}%', 'Career avg', Icons.trending_up, Colors.green),
              ],
            ),
            
            const SizedBox(height: 24),

            // Quick Action Card
            Card(
              elevation: 4,
              shadowColor: Colors.blue.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue-500 to blue-600
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Load Marketplace', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Find and accept new shipments', style: TextStyle(color: Color(0xFFDBEAFE))),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/transporter/marketplace'),
                      icon: const Icon(Icons.local_shipping, color: Color(0xFF2563EB)),
                      label: const Text('View Open Loads', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
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
              child: transporterId.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Authenticating...')))
                  : Consumer<TransporterShipmentProvider>(
                      builder: (context, shipmentProvider, child) {
                        if (shipmentProvider.isLoading && shipmentProvider.shipments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: List.generate(3, (index) => _buildSkeletonCard()),
                            ),
                          );
                        }
                        if (shipmentProvider.error != null) {
                          final isPreparing = shipmentProvider.error == "Preparing shipment database, please wait...";
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isPreparing ? Icons.storage : Icons.error_outline, 
                                    color: isPreparing ? Colors.blue : Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(shipmentProvider.error!,
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
                        
                        final shipments = shipmentProvider.shipments;
                        if (shipments.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text('No shipments yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  const Text('Create your first shipment to start tracking', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                                ],
                              ),
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
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(shipment.lrNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Chip(
                                        label: Text(_getStatusLabel(shipment.status), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: _getStatusColor(shipment.status),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${shipment.fromCity} → ${shipment.toCity}', style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (shipment.status != ShipmentStatus.delivered) ...[
                                        OutlinedButton(
                                          onPressed: () => context.go('/transporter/update-status/${shipment.shipmentId}'),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          child: const Text('Update Status'),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      ElevatedButton(
                                        onPressed: () => context.go('/transporter/upload-epod/${shipment.shipmentId}'),
                                        style: ElevatedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Upload ePOD'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            
            if (context.watch<TransporterShipmentProvider>().isLoading && context.watch<TransporterShipmentProvider>().shipments.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),           const SizedBox(height: 24),

            // Performance Metrics
            const Text('Your Performance Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (user != null)
              TrustScoreBreakdownWidget(user: user),

            const SizedBox(height: 16),
            if (user != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/transporter/ai-report'),
                  icon: const Icon(Icons.psychology, color: Colors.white),
                  label: const Text('View AI Performance Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        );
        },
      ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 120, height: 20, color: Colors.grey.shade200),
              Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: MediaQuery.of(context).size.width * 0.6, height: 16, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Container(width: MediaQuery.of(context).size.width * 0.4, height: 16, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, {bool showProgress = false, double progressValue = 0}) {
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
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            if (showProgress)
              LinearProgressIndicator(value: progressValue, backgroundColor: Colors.grey.shade200, color: color)
            else
              Text(subtitle, style: TextStyle(fontSize: 10, color: color == Colors.red ? color : Colors.black54), maxLines: 1),
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
