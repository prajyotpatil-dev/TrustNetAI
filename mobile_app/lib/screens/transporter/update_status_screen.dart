import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../providers/shipment_provider.dart';

class UpdateStatusScreen extends StatefulWidget {
  final String shipmentId;
  const UpdateStatusScreen({super.key, required this.shipmentId});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  String _selectedStatus = 'in_transit';
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  final statuses = [
    {'value': 'pickup', 'label': 'Picked Up', 'icon': Icons.inventory_2, 'color': Color(0xFFF59E0B)},
    {'value': 'in_transit', 'label': 'In Transit', 'icon': Icons.local_shipping, 'color': Color(0xFF2563EB)},
    {'value': 'out_for_delivery', 'label': 'Out for Delivery', 'icon': Icons.delivery_dining, 'color': Color(0xFF8B5CF6)},
    {'value': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle, 'color': Color(0xFF16A34A)},
    {'value': 'delayed', 'label': 'Delayed', 'icon': Icons.access_time_filled, 'color': Color(0xFFDC2626)},
  ];

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      await context.read<ShipmentProvider>().updateShipmentStatus(widget.shipmentId, _selectedStatus, remarks: _remarksController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green),
      );
      context.go('/transporter/dashboard');
    } catch(e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Update Status', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Shipment #${widget.shipmentId}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          const Text('Select Current Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...statuses.map((s) {
            final isSelected = _selectedStatus == s['value'];
            final color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _selectedStatus = s['value'] as String),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
                    color: isSelected ? color.withOpacity(0.08) : Colors.white,
                  ),
                  child: Row(children: [
                    Icon(s['icon'] as IconData, color: isSelected ? color : Colors.black38, size: 24),
                    const SizedBox(width: 14),
                    Text(s['label'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? color : Colors.black87, fontSize: 16)),
                    const Spacer(),
                    if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'e.g. Reached checkpoint, slight delay due to traffic...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}
