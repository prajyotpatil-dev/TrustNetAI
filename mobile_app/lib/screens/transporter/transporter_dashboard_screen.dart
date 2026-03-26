import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/shipment_provider.dart';
import '../../models/shipment_model.dart';

class TransporterDashboardScreen extends StatelessWidget {
  const TransporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
             context.read<ShipmentProvider>().loadMore();
          }
          return false;
        },
        child: SingleChildScrollView(
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
                _buildStatCard('Active Shipments', '8', 'In transit & pickup', Icons.inventory_2, Colors.blue),
                _buildStatCard('Completed', '24', 'This month', Icons.check_circle, Colors.green),
                _buildStatCard('Trust Score', '85', '', Icons.star, Colors.purple, showProgress: true, progressValue: 0.85),
                _buildStatCard('On-Time Rate', '92%', 'Above average', Icons.trending_up, Colors.green),
              ],
            ),
            
            const SizedBox(height: 24),

            // Quick Action Card
            Card(
              elevation: 4,
              shadowColor: Colors.green.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)], // green-500 to green-600
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create New Shipment', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Generate digital LR/bilty and start tracking', style: TextStyle(color: Color(0xFFDCFCE7))),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/transporter/create-shipment'),
                      icon: const Icon(Icons.add_circle, color: Color(0xFF16A34A)),
                      label: const Text('Create Shipment', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
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
                  : Consumer<ShipmentProvider>(
                      builder: (context, shipmentProvider, child) {
                        if (shipmentProvider.isLoading && shipmentProvider.shipments.isEmpty) {
                          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                        }
                        if (shipmentProvider.error != null) {
                          return Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Error: ${shipmentProvider.error}')));
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
                                      OutlinedButton(
                                        onPressed: () => context.go('/transporter/update-status/${shipment.shipmentId}'),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Update Status'),
                                      ),
                                      const SizedBox(width: 8),
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
            
            if (context.watch<ShipmentProvider>().isLoading && context.watch<ShipmentProvider>().shipments.isNotEmpty)
               const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            
            const SizedBox(height: 24),

            // Performance Metrics
            const Text('Your Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildPerformanceRow('Trust Score', '85/100', 0.85, Colors.purple),
                    const SizedBox(height: 16),
                    _buildPerformanceRow('On-Time Delivery', '92%', 0.92, Colors.green),
                    const SizedBox(height: 16),
                    _buildPerformanceRow('ePOD Compliance', '96%', 0.96, Colors.blue),
                    const SizedBox(height: 16),
                    _buildPerformanceRow('Customer Rating', '4.8/5.0', 0.96, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
        },
      ),
      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created': return Colors.orange; // matches yellow requested via orange enum/shade
      case 'in_transit': return Colors.blue;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'created': return 'Created';
      case 'in_transit': return 'In Transit';
      case 'delivered': return 'Delivered';
      default: return status.toUpperCase();
    }
  }
}
