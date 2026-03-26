import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';

class AIRiskReportScreen extends StatelessWidget {
  const AIRiskReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('AI Risk Report', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Powered by predictive intelligence', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          // Overall Risk Banner
          Card(
            elevation: 0,
            color: const Color(0xFFFFF7ED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Medium Risk Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                  Text('2 active alerts require your attention', style: TextStyle(color: Colors.black54)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          // Risk Alerts
          const Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRiskCard('Delay Risk', 'Shipment LR-00123 may be delayed due to weather conditions along NH48.', Colors.orange, Icons.access_time),
          const SizedBox(height: 12),
          _buildRiskCard('Trust Score Drop', 'Fast Freight Co\'s score dropped 12 points in the last 30 days.', Colors.red, Icons.trending_down),
          const SizedBox(height: 20),
          // AI Insights
          const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInsightCard('Best Performing Route', 'Mumbai → Pune has a 98% on-time delivery rate this month.', Icons.route, Colors.green),
          const SizedBox(height: 12),
          _buildInsightCard('Recommended Transporter', 'Rajesh Logistics (Score: 92) is recommended for your next Delhi shipment.', Icons.thumb_up, Colors.blue),
          const SizedBox(height: 12),
          _buildInsightCard('Cost Optimization', 'Consolidating 3 pending shipments could save ₹4,200 in freight costs.', Icons.savings, Colors.purple),
          const SizedBox(height: 20),
          // Risk Score History
          const Text('Risk Score Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _riskMetricRow('Total Shipments This Month', '57', Colors.blue),
                const Divider(height: 24),
                _riskMetricRow('On-Time Delivery Rate', '89%', Colors.green),
                const Divider(height: 24),
                _riskMetricRow('Average Trust Score', '78/100', Colors.orange),
                const Divider(height: 24),
                _riskMetricRow('Disputes Raised', '2', Colors.red),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRiskCard(String title, String desc, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ])),
        ]),
      ),
    );
  }

  Widget _riskMetricRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.black54)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
    ]);
  }
}
