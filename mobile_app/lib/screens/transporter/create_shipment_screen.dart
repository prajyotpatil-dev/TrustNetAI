import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../services/shipment_service.dart';
import '../../providers/user_provider.dart';

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _consignorController = TextEditingController();
  final _consigneeController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();
  final _goodsController = TextEditingController();
  bool _isLoading = false;

  void _handleCreate() async {
    if (_consignorController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields.')));
      return;
    }
    setState(() => _isLoading = true);
    
    final uid = context.read<UserProvider>().user?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not found.')));
      }
      return;
    }

    try {
      final lrNumber = await ShipmentService().createShipment(
        fromCity: _originController.text.trim(),
        toCity: _destinationController.text.trim(),
        transporterId: uid,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shipment created! LR Number: $lrNumber'), backgroundColor: Colors.green),
      );
      context.go('/transporter/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    context.go('/transporter/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Shipment', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Generate a new digital LR/Bilty', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Consignor & Consignee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildField('Consignor Name *', _consignorController, Icons.business),
                const SizedBox(height: 14),
                _buildField('Consignee Name *', _consigneeController, Icons.person),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Route Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildField('Origin *', _originController, Icons.location_on),
                const SizedBox(height: 14),
                _buildField('Destination *', _destinationController, Icons.flag),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Goods Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildField('Goods Description', _goodsController, Icons.inventory),
                const SizedBox(height: 14),
                _buildField('Weight (kg)', _weightController, Icons.scale, keyboard: TextInputType.number),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Shipment & Generate LR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black45, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          hintText: 'Enter $label',
        ),
      ),
    ]);
  }
}
