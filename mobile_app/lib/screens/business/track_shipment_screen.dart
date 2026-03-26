import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_layout.dart';

class TrackShipmentScreen extends StatelessWidget {
  final String shipmentId;
  const TrackShipmentScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                Text('Shipment #$shipmentId', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 20),
            // Live Map Placeholder
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Container(
                height: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFE0F2FE)),
                child: const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.map, size: 48, color: Color(0xFF0369A1)),
                    SizedBox(height: 8),
                    Text('Live Map Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                    Text('(Integrate Google Maps for live tracking)', style: TextStyle(fontSize: 12, color: Colors.black38)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Journey Timeline
            const Text('Journey Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimeline(),
            const SizedBox(height: 20),
            // Shipment Details
            const Text('Shipment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _detailRow('LR Number', 'LR-$shipmentId'),
                  _detailRow('Origin', 'Mumbai, MH'),
                  _detailRow('Destination', 'Delhi, DL'),
                  _detailRow('Consignor', 'ABC Traders'),
                  _detailRow('Consignee', 'XYZ Pvt Ltd'),
                  _detailRow('Weight', '450 kg'),
                  _detailRow('Trust Score', '88/100', valueColor: Colors.green.shade700),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: const Color(0xFFEFF6FF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('In Transit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E40AF))),
            Text('Last updated: 2 hrs ago', style: TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
          const Spacer(),
          const Chip(
            label: Text('On Track', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'label': 'Picked Up', 'loc': 'Mumbai Warehouse', 'done': true},
      {'label': 'In Transit', 'loc': 'Nashik Checkpoint', 'done': true},
      {'label': 'On the way', 'loc': 'Current Location', 'done': false},
      {'label': 'To be Delivered', 'loc': 'Delhi Hub', 'done': false},
    ];
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final done = s['done'] as bool;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF2563EB) : Colors.grey.shade200,
              ),
              child: Icon(done ? Icons.check : Icons.circle_outlined, color: done ? Colors.white : Colors.grey, size: 16),
            ),
            if (i < steps.length - 1)
              Container(width: 2, height: 40, color: done ? const Color(0xFF2563EB) : Colors.grey.shade200),
          ]),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['label'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: done ? Colors.black87 : Colors.black38)),
              Text(s['loc'] as String, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
      ]),
    );
  }
}
