import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:go_router/go_router.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

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
                _buildStatCard('Active Shipments', '12', 'In transit & pickup', Icons.inventory_2, Colors.blue),
                _buildStatCard('Delivered', '45', 'On time delivery', Icons.check_circle, Colors.green),
                _buildTrustScoreCard('85'),
                _buildStatCard('Risk Alerts', '2', 'Requires attention', Icons.warning_amber_rounded, Colors.red),
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LR-00123', style: TextStyle(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text('In Transit', style: TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        const Text('Mumbai → Delhi', style: TextStyle(color: Colors.black87)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Trust Score: ', style: TextStyle(fontSize: 12)),
                            Text('88', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/business/track/SH001'),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
}
