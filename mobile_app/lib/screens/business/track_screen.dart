import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_layout.dart';
import '../../models/shipment_status.dart';

/// Track Screen - lists all shipments owned by the current business user.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Track Shipments',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                            Text('Your shipments in real time',
                                style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('No shipments found.',
                              style: TextStyle(color: Colors.black54)),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final data = docs[index].data()
                                  as Map<String, dynamic>;
                              final docId = docs[index].id;
                              final lrNumber =
                                  data['lrNumber'] as String? ?? 'Unknown';
                              final fromCity =
                                  data['fromCity'] as String? ?? '';
                              final toCity = data['toCity'] as String? ?? '';
                              final statusStr =
                                  data['status'] as String? ?? 'created';
                              final status =
                                  ShipmentStatusExtension.fromString(
                                      statusStr);
                              final statusColor =
                                  _getStatusColor(status);
                              final statusLabel =
                                  _getStatusLabel(status);
                              final trustScore =
                                  (data['trustScore'] as num?)
                                          ?.toStringAsFixed(0) ??
                                      '0';

                              return Card(
                                elevation: 0,
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey.shade200)),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.all(16),
                                  title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(lrNumber,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        Chip(
                                          label: Text(statusLabel,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                          backgroundColor: statusColor,
                                          padding: EdgeInsets.zero,
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                      ]),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('$fromCity → $toCity'),
                                        const SizedBox(height: 6),
                                        Text('Trust: $trustScore',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green
                                                    .shade700)),
                                      ]),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () => context
                                      .push('/business/track/$docId'),
                                ),
                              );
                            },
                            childCount: docs.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return Colors.grey;
      case ShipmentStatus.assigned:
        return Colors.cyan;
      case ShipmentStatus.created:
        return Colors.orange;
      case ShipmentStatus.inTransit:
        return Colors.blue;
      case ShipmentStatus.delivered:
        return Colors.green;
      case ShipmentStatus.delayed:
        return Colors.red;
    }
  }

  String _getStatusLabel(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return 'Pending';
      case ShipmentStatus.assigned:
        return 'Assigned';
      case ShipmentStatus.created:
        return 'Created';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.delayed:
        return 'Delayed';
    }
  }
}
