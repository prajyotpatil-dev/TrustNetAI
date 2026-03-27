import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? 'Transporter';
            // Fallback scores/trips if not present in user doc yet
            final score = (data['trustScore'] as num?)?.toInt() ?? 85; 
            final trips = (data['completedTrips'] as num?)?.toInt() ?? 0;
            
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
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Network Trust', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Your transporter partner network', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              // Network Stats
              Row(children: [
                Expanded(child: _networkStatCard('${partners.length}', 'Partners', Icons.people, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _networkStatCard('$verifiedCount', 'Verified', Icons.verified, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _networkStatCard('$flaggedCount', 'Flagged', Icons.flag, Colors.red)),
              ]),
              const SizedBox(height: 24),
              // Partner List
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
                            backgroundColor: scoreColor.withValues(alpha: 0.15),
                            child: Text((p['name'] as String)[0], style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18)),
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
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ])),
                          Column(children: [
                            Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor)),
                            const Text('score', style: TextStyle(fontSize: 11, color: Colors.black38)),
                          ]),
                        ]),
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
