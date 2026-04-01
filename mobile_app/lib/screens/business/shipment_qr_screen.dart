import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/app_layout.dart';

/// QR Code Display Screen for Digital LR
class ShipmentQRScreen extends StatelessWidget {
  final String shipmentId;
  const ShipmentQRScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    final trackingUrl = 'https://trustnet.ai/track/$shipmentId';

    return AppLayout(
      role: 'business',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Digital LR — QR Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan to track this shipment in real time',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // ── QR Code Card ──────────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: trackingUrl,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Shipment ID
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shipmentId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tracking URL
                    Text(
                      trackingUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Info Cards ────────────────────────────────────────────────
            Card(
              elevation: 0,
              color: const Color(0xFFF0FDF4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Color(0xFF16A34A)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scannable Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          Text('Partners can scan this QR to get live shipment updates', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Color(0xFF2563EB)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tamper-Proof', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                          Text('Each QR is uniquely linked to the digital LR record', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Back to Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
