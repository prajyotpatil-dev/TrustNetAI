import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_layout.dart';
import '../../models/shipment_model.dart';
import '../../providers/business_shipment_provider.dart';
import '../../providers/user_provider.dart';

class ViewEPODScreen extends StatelessWidget {
  final String shipmentId;
  const ViewEPODScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shipments')
            .doc(shipmentId)
            .snapshots(),
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child:
                  Text('Shipment not found.', style: TextStyle(color: Colors.black54)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final shipment = ShipmentModel.fromMap(data, snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────────
                const Text(
                  'ePOD Viewer',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Shipment #${shipment.lrNumber}  ·  ${shipment.fromCity} → ${shipment.toCity}',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // ── Verification Status Banner ───────────────────────────
                _VerificationBanner(shipment: shipment),
                const SizedBox(height: 16),

                // ── ePOD Image Card ──────────────────────────────────────
                _EPODImageCard(shipment: shipment),
                const SizedBox(height: 16),

                // ── Metadata Card ────────────────────────────────────────
                if (shipment.epodUrl != null) ...[
                  _MetadataCard(shipment: shipment),
                  const SizedBox(height: 20),
                ],

                // ── Verify Action ────────────────────────────────────────
                if (shipment.epodUrl != null && !shipment.epodVerified)
                  _VerifyButton(shipmentId: shipmentId),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Verification Status Banner
// ═══════════════════════════════════════════════════════════════════════════════
class _VerificationBanner extends StatelessWidget {
  final ShipmentModel shipment;
  const _VerificationBanner({required this.shipment});

  @override
  Widget build(BuildContext context) {
    if (shipment.epodUrl == null) {
      return _buildBanner(
        icon: Icons.hourglass_empty,
        label: 'Awaiting Upload',
        subtitle: 'Transporter has not uploaded ePOD yet',
        color: Colors.grey,
        bgColor: Colors.grey.shade100,
      );
    }

    if (shipment.epodVerified) {
      final verifiedAt = shipment.epodVerifiedAt != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(shipment.epodVerifiedAt!)
          : '';
      return _buildBanner(
        icon: Icons.verified,
        label: 'Verified',
        subtitle: 'Verified on $verifiedAt',
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFECFDF5),
      );
    }

    return _buildBanner(
      icon: Icons.pending_actions,
      label: 'Pending Verification',
      subtitle: 'ePOD uploaded — awaiting your review',
      color: const Color(0xFFD97706),
      bgColor: const Color(0xFFFFFBEB),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ePOD Image Card (with full-screen tap)
// ═══════════════════════════════════════════════════════════════════════════════
class _EPODImageCard extends StatelessWidget {
  final ShipmentModel shipment;
  const _EPODImageCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    if (shipment.epodUrl == null) {
      return _buildEmptyState();
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image Preview ─────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openFullScreen(context, shipment.epodUrl!),
            child: Hero(
              tag: 'epod_${shipment.shipmentId}',
              child: SizedBox(
                height: 280,
                child: Image.network(
                  shipment.epodUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 280,
                      color: Colors.red.shade50,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text('Failed to load image',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // ── Tap hint ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.grey.shade50,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fullscreen, size: 18, color: Colors.black45),
                SizedBox(width: 6),
                Text('Tap image to view full screen',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.image_not_supported_outlined,
                  size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'No ePOD Uploaded Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'The transporter has not uploaded proof of delivery for this shipment. You will see the image here in real-time once it is uploaded.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            imageUrl: imageUrl,
            heroTag: 'epod_${shipment.shipmentId}',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Full-Screen Image Viewer
// ═══════════════════════════════════════════════════════════════════════════════
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  const _FullScreenImageViewer(
      {required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Zoomable Image ──────────────────────────────────────────
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: heroTag,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          // ── Close Button ────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Material(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Metadata Card
// ═══════════════════════════════════════════════════════════════════════════════
class _MetadataCard extends StatelessWidget {
  final ShipmentModel shipment;
  const _MetadataCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final meta = shipment.proofMetadata;
    final uploadedAt = shipment.epodUploadedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(shipment.epodUploadedAt!)
        : 'Unknown';

    final lat = meta?['lat'];
    final lng = meta?['lng'];
    final imageHash = meta?['imageHash'] as String?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('ePOD Metadata',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E40AF))),
              ],
            ),
            const Divider(height: 24),
            _metaRow(Icons.access_time, 'Uploaded At', uploadedAt),
            if (lat != null && lng != null)
              _metaRow(Icons.location_on, 'Geo-tag',
                  '${(lat as num).toDouble().toStringAsFixed(5)}, ${(lng as num).toDouble().toStringAsFixed(5)}'),
            if (imageHash != null)
              _metaRow(
                  Icons.fingerprint,
                  'Image Hash',
                  '${imageHash.substring(0, 16)}…'),
            _metaRow(Icons.local_shipping, 'Status',
                shipment.status.name.toUpperCase()),
            _metaRow(Icons.shield, 'Trust Score',
                '${shipment.trustScore.toStringAsFixed(0)} / 100'),
            if (shipment.remarks != null && shipment.remarks!.isNotEmpty)
              _metaRow(Icons.notes, 'Remarks', shipment.remarks!),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black38),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Verify Button
// ═══════════════════════════════════════════════════════════════════════════════
class _VerifyButton extends StatefulWidget {
  final String shipmentId;
  const _VerifyButton({required this.shipmentId});

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _isVerifying = false;

  Future<void> _handleVerify() async {
    final uid = context.read<UserProvider>().user?.uid;
    if (uid == null || uid.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Color(0xFF16A34A)),
            SizedBox(width: 10),
            Text('Verify ePOD'),
          ],
        ),
        content: const Text(
          'Are you sure you want to mark this proof of delivery as verified? This confirms the delivery was completed successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isVerifying = true);
    try {
      await context
          .read<BusinessShipmentProvider>()
          .verifyEPOD(widget.shipmentId, uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('ePOD verified successfully!')),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isVerifying ? null : _handleVerify,
      icon: _isVerifying
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.verified_user, color: Colors.white),
      label: Text(
        _isVerifying ? 'Verifying…' : 'Mark ePOD as Verified',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
