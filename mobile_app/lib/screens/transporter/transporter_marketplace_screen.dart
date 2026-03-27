import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/transporter_shipment_provider.dart';
import '../../models/shipment_status.dart';

class TransporterMarketplaceScreen extends StatefulWidget {
  const TransporterMarketplaceScreen({super.key});

  @override
  State<TransporterMarketplaceScreen> createState() => _TransporterMarketplaceScreenState();
}

class _TransporterMarketplaceScreenState extends State<TransporterMarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransporterShipmentProvider>().listenMarketplaceShipments();
    });
  }

  void _acceptShipment(String shipmentId) async {
    try {
      await context.read<TransporterShipmentProvider>().acceptMarketplaceShipment(shipmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shipment Accepted! It is now in your Active dashboard.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      context.go('/transporter/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept shipment: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/transporter/dashboard'),
                ),
                const SizedBox(width: 8),
                const Text('Open Marketplace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Browse and accept newly broadcasted loads from Business owners.', style: TextStyle(fontSize: 16, color: Color(0xFF475569))),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<TransporterShipmentProvider>(
                builder: (context, provider, child) {
                  final marketplaceShipments = provider.marketplaceShipments;
                  
                  if (marketplaceShipments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No open loads currently', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Check back later for new shipments', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: marketplaceShipments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shipment = marketplaceShipments[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(shipment.lrNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Chip(
                                    label: Text('Open', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    backgroundColor: Color(0xFFDBEAFE),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(shipment.fromCity, style: const TextStyle(fontSize: 14)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                  ),
                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(shipment.toCity, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _acceptShipment(shipment.shipmentId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Accept Shipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
