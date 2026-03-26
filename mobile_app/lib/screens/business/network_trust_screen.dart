import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';

class NetworkTrustScreen extends StatelessWidget {
  const NetworkTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partners = [
      {'name': 'Rajesh Logistics', 'trips': 145, 'score': 92, 'status': 'Verified'},
      {'name': 'Singh Carriers', 'trips': 89, 'score': 86, 'status': 'Verified'},
      {'name': 'Kumar Transport', 'trips': 210, 'score': 74, 'status': 'Active'},
      {'name': 'Delhi Express', 'trips': 56, 'score': 68, 'status': 'Active'},
      {'name': 'Fast Freight Co', 'trips': 34, 'score': 55, 'status': 'Flagged'},
    ];

    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Network Trust', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Your transporter partner network', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          // Network Stats
          Row(children: [
            Expanded(child: _networkStatCard('5', 'Partners', Icons.people, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _networkStatCard('4', 'Verified', Icons.verified, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _networkStatCard('1', 'Flagged', Icons.flag, Colors.red)),
          ]),
          const SizedBox(height: 24),
          // Partner List
          const Text('All Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: partners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = partners[i];
              final score = p['score'] as int;
              final status = p['status'] as String;
              final statusColor = status == 'Verified' ? Colors.green : status == 'Active' ? Colors.blue : Colors.red;
              final scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scoreColor.withOpacity(0.15),
                      child: Text('${(p['name'] as String)[0]}', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.inventory_2_outlined, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text('${p['trips']} trips', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ])),
                    Column(children: [
                      Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor)),
                      Text('score', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ]),
      ),
    );
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
}
