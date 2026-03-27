import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/app_layout.dart';
import '../../models/shipment_model.dart';
import '../../models/shipment_status.dart';

/// ShipmentDetailsScreen — fetches a single shipment by Firestore document ID
/// and shows a live Google Map with the truck marker.
class TrackShipmentScreen extends StatefulWidget {
  final String shipmentId;
  const TrackShipmentScreen({super.key, required this.shipmentId});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  GoogleMapController? _mapController;

  // Default center (India) if no GPS data yet
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'business',
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shipments')
            .doc(widget.shipmentId)
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
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Shipment not found.',
                  style: TextStyle(color: Colors.black54)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final shipment = ShipmentModel.fromMap(data, snapshot.data!.id);

          // Extract live GPS from Firestore
          final locationData = data['currentLocation'] as Map<String, dynamic>?;
          final double? lat = (locationData?['lat'] as num?)?.toDouble();
          final double? lng = (locationData?['lng'] as num?)?.toDouble();
          final LatLng? truckPosition =
              (lat != null && lng != null) ? LatLng(lat, lng) : null;

          // Animate camera when position changes
          if (truckPosition != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(truckPosition),
            );
          }

          final Set<Marker> markers = truckPosition != null
              ? {
                  Marker(
                    markerId: const MarkerId('truck'),
                    position: truckPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                    infoWindow: InfoWindow(
                      title: shipment.lrNumber,
                      snippet: '${shipment.fromCity} → ${shipment.toCity}',
                    ),
                  ),
                }
              : {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: Text('Shipment #${shipment.lrNumber}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusCard(shipment),
                const SizedBox(height: 20),

                // ── Live Map ──────────────────────────────────────────────
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: truckPosition ?? _defaultCenter,
                              zoom: truckPosition != null ? 14.0 : 5.0,
                            ),
                            markers: markers,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                          ),
                          // Live indicator overlay
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: truckPosition != null
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    truckPosition != null
                                        ? Icons.location_on
                                        : Icons.location_off,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    truckPosition != null
                                        ? 'Live'
                                        : 'Awaiting GPS',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Journey Timeline
                const Text('Journey Timeline',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTimeline(shipment.status),
                const SizedBox(height: 20),

                // Shipment Details
                const Text('Shipment Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _detailRow('LR Number', shipment.lrNumber),
                      _detailRow('Origin', shipment.fromCity),
                      _detailRow('Destination', shipment.toCity),
                      _detailRow('Status', _getStatusLabel(shipment.status)),
                      if (truckPosition != null) ...[
                        _detailRow('Last Lat',
                            lat!.toStringAsFixed(5)),
                        _detailRow('Last Lng',
                            lng!.toStringAsFixed(5)),
                      ],
                      if (shipment.transporterId != null)
                        _detailRow('Transporter ID', shipment.transporterId!),
                      _detailRow(
                          'Trust Score',
                          '${shipment.trustScore.toStringAsFixed(0)}/100',
                          valueColor: _scoreColor(shipment.trustScore)),
                      _detailRow('Created', _formatDate(shipment.createdAt)),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ShipmentModel shipment) {
    final isOnTrack = shipment.status != ShipmentStatus.delayed &&
        shipment.status != ShipmentStatus.delivered;
    final label = _getStatusLabel(shipment.status);
    return Card(
      color: const Color(0xFFEFF6FF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E40AF))),
            const Text('Real-time Firestore stream',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
          const Spacer(),
          Chip(
            label: Text(isOnTrack ? 'On Track' : label,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: isOnTrack ? Colors.green : Colors.red,
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeline(ShipmentStatus currentStatus) {
    const allSteps = [
      {'label': 'Created', 'status': ShipmentStatus.created},
      {'label': 'Assigned', 'status': ShipmentStatus.assigned},
      {'label': 'In Transit', 'status': ShipmentStatus.inTransit},
      {'label': 'Delivered', 'status': ShipmentStatus.delivered},
    ];
    final statusOrder = [
      ShipmentStatus.created,
      ShipmentStatus.assigned,
      ShipmentStatus.inTransit,
      ShipmentStatus.delivered,
    ];
    final currentIdx = statusOrder.indexOf(currentStatus);

    return Column(
      children: List.generate(allSteps.length, (i) {
        final stepStatus = allSteps[i]['status'] as ShipmentStatus;
        final done = statusOrder.indexOf(stepStatus) <= currentIdx;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    done ? const Color(0xFF2563EB) : Colors.grey.shade200,
              ),
              child: Icon(done ? Icons.check : Icons.circle_outlined,
                  color: done ? Colors.white : Colors.grey, size: 16),
            ),
            if (i < allSteps.length - 1)
              Container(
                  width: 2,
                  height: 40,
                  color: done
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade200),
          ]),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(allSteps[i]['label'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.black87 : Colors.black38)),
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
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87),
              textAlign: TextAlign.end),
        ),
      ]),
    );
  }

  String _getStatusLabel(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending: return 'Pending';
      case ShipmentStatus.assigned: return 'Assigned';
      case ShipmentStatus.created: return 'Created';
      case ShipmentStatus.inTransit: return 'In Transit';
      case ShipmentStatus.delivered: return 'Delivered';
      case ShipmentStatus.delayed: return 'Delayed';
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green.shade700;
    if (score >= 60) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
