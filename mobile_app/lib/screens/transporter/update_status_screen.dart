import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../providers/transporter_shipment_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/shipment_status.dart';
import '../../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateStatusScreen extends StatefulWidget {
  final String shipmentId;
  const UpdateStatusScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  ShipmentStatus _selectedStatus = ShipmentStatus.inTransit;
  final _remarksController = TextEditingController();
  bool _isLoading = false;
  bool _isTracking = false;
  String? _trackingError;

  final _locationService = LocationService();

  final statuses = [
    {'value': ShipmentStatus.created, 'label': 'Picked Up', 'icon': Icons.inventory_2, 'color': Color(0xFFF59E0B)},
    {'value': ShipmentStatus.inTransit, 'label': 'In Transit', 'icon': Icons.local_shipping, 'color': Color(0xFF2563EB)},
    {'value': ShipmentStatus.delivered, 'label': 'Delivered', 'icon': Icons.check_circle, 'color': Color(0xFF16A34A)},
    {'value': ShipmentStatus.delayed, 'label': 'Delayed', 'icon': Icons.access_time_filled, 'color': Color(0xFFDC2626)},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select inTransit since this is the active update screen
    _selectedStatus = ShipmentStatus.inTransit;
    // Start GPS tracking immediately when the screen opens
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      await _locationService.startTracking(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _isTracking = true;
        _trackingError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTracking = false;
        _trackingError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isLoading = true);
    // Stop tracking if marking delivered
    if (_selectedStatus == ShipmentStatus.delivered) {
      _locationService.stopTracking();
    }
    try {
      await context.read<TransporterShipmentProvider>().updateShipmentStatus(
          widget.shipmentId, _selectedStatus,
          remarks: _remarksController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Update Status',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Shipment #${widget.shipmentId}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),

          // ── Live Tracking indicator ───────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _trackingError != null
                  ? Colors.red.shade50
                  : (_isTracking ? const Color(0xFFECFDF5) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _trackingError != null
                    ? Colors.red.shade200
                    : (_isTracking ? Colors.green.shade300 : Colors.grey.shade300),
              ),
            ),
            child: Row(children: [
              Icon(
                _trackingError != null
                    ? Icons.location_off
                    : (_isTracking ? Icons.location_on : Icons.hourglass_empty),
                color: _trackingError != null
                    ? Colors.red
                    : (_isTracking ? Colors.green.shade700 : Colors.grey),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _trackingError != null
                      ? 'GPS: ${_trackingError!}'
                      : (_isTracking
                          ? 'Live tracking active — location updates every 5s'
                          : 'Starting GPS tracking…'),
                  style: TextStyle(
                    fontSize: 13,
                    color: _trackingError != null
                        ? Colors.red.shade700
                        : (_isTracking ? Colors.green.shade800 : Colors.grey.shade700),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_trackingError != null)
                TextButton(
                  onPressed: _trackingError!.toLowerCase().contains('settings')
                      ? () => openAppSettings()
                      : _startTracking,
                  child: Text(_trackingError!.toLowerCase().contains('settings') ? 'Settings' : 'Retry'),
                ),
            ]),
          ),

          const SizedBox(height: 20),
          const Text('Select Current Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...statuses.map((s) {
            final isSelected = _selectedStatus == s['value'];
            final color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () =>
                    setState(() => _selectedStatus = s['value'] as ShipmentStatus),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1),
                    color: isSelected
                        ? color.withValues(alpha: 0.08)
                        : Colors.white,
                  ),
                  child: Row(children: [
                    Icon(s['icon'] as IconData,
                        color: isSelected ? color : Colors.black38, size: 24),
                    const SizedBox(width: 14),
                    Text(s['label'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? color : Colors.black87,
                            fontSize: 16)),
                    const Spacer(),
                    if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text('Remarks (Optional)',
              style: TextStyle(fontWeight: FontWeight.w500)),
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
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Update Status',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}
