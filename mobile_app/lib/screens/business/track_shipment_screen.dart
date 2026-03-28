import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' show atan2, pi;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../widgets/app_layout.dart';
import '../../models/shipment_model.dart';
import '../../models/shipment_status.dart';

class TrackShipmentScreen extends StatefulWidget {
  final String shipmentId;
  const TrackShipmentScreen({super.key, required this.shipmentId});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  // --- GPS Tracking States ---
  LatLng? previousPosition;
  LatLng? currentPosition;
  bool isGpsReady = false;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  StreamSubscription<DocumentSnapshot>? _firestoreSub;

  // --- Polyline & ETA State ---
  Set<Polyline> polylines = {};
  String? etaTime;
  bool _isFetchingRoute = false;

  // --- Custom Markers ---
  BitmapDescriptor? truckIcon;

  @override
  void initState() {
    super.initState();
    loadTruckIcon();
    listenToFirestore();
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  // --- ASSET LOADER ---
  Future<BitmapDescriptor> getResizedMarker(String path) async {
    final ByteData data = await rootBundle.load(path);
    final Uint8List bytes = data.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 80 // adjust between 60–100 for best size
    );

    final frame = await codec.getNextFrame();
    final resizedBytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(resizedBytes!.buffer.asUint8List());
  }

  Future<void> loadTruckIcon() async {
    try {
      truckIcon = await getResizedMarker('assets/truck.png');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Failed to load truck icon: $e");
    }
  }

  // --- FIRESTORE REMOTE LISTENER ---
  void listenToFirestore() {
    _firestoreSub = FirebaseFirestore.instance
      .collection('shipments')
      .doc(widget.shipmentId)
      .snapshots()
      .listen((doc) {
        if (!doc.exists || !mounted) return;
        final data = doc.data();
        if (data != null && data['currentLocation'] != null) {
          final loc = data['currentLocation'];
          if (loc['lat'] != null && loc['lng'] != null) {
            LatLng newPos = LatLng(
              (loc['lat'] as num).toDouble(), 
              (loc['lng'] as num).toDouble()
            );
            animateTruck(newPos);
          }
        }
      });
  }

  // --- UBER-LIKE ANIMATION LOGIC ---
  void animateTruck(LatLng newPosition) {
    if (currentPosition == null) {
      currentPosition = newPosition;
      updateMarker(newPosition);
      return;
    }

    // Skip if position hasn't actually shifted
    if (currentPosition!.latitude == newPosition.latitude && 
        currentPosition!.longitude == newPosition.longitude) {
      return;
    }

    previousPosition = currentPosition;
    currentPosition = newPosition;

    const int animationDuration = 1000; // 1 second exact transition
    const int steps = 60;
    int currentStep = 0;

    double totalLatDelta = currentPosition!.latitude - previousPosition!.latitude;
    double totalLngDelta = currentPosition!.longitude - previousPosition!.longitude;

    Timer.periodic(const Duration(milliseconds: animationDuration ~/ steps), (timer) {
      if (!mounted || currentStep >= steps) {
        timer.cancel();
        return;
      }

      // Easing multiplier (Curve)
      double t = currentStep / steps;
      double eased = Curves.easeInOut.transform(t);

      double lat = previousPosition!.latitude + (totalLatDelta * eased);
      double lng = previousPosition!.longitude + (totalLngDelta * eased);

      LatLng interpolatedPosition = LatLng(lat, lng);
      updateMarker(interpolatedPosition);

      currentStep++;
    });
  }

  void updateMarker(LatLng position) {
    if (!mounted) return;
    setState(() {
      isGpsReady = true;
      markers.removeWhere((m) => m.markerId.value == "truck");
      
      markers.add(
        Marker(
          markerId: const MarkerId("truck"),
          position: position,
          icon: truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: getRotation(),
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    });

    // Smooth camera tracking exactly aligned to interpolated coordinates
    mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  double getRotation() {
    if (previousPosition == null || currentPosition == null) return 0;
    double deltaLng = currentPosition!.longitude - previousPosition!.longitude;
    double deltaLat = currentPosition!.latitude - previousPosition!.latitude;
    
    return atan2(deltaLng, deltaLat) * (180 / pi);
  }

  // --- ETA & DIRECTIONS API ---
  Future<void> getRouteAndETA(LatLng origin, String destinationQuery) async {
    try {
      const apiKey = "AIzaSyAueeoWd2Bh2MKv_XS-HtP13ynfgGO0JSA";
      final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${Uri.encodeComponent(destinationQuery)}&key=$apiKey";
      
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final duration = data['routes'][0]['legs'][0]['duration']['text'];
        final encodedPolyline = data['routes'][0]['overview_polyline']['points'];
        
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
        List<LatLng> routePoints = decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

        if (mounted) {
          setState(() {
            etaTime = duration;
            polylines.add(
              Polyline(
                polylineId: const PolylineId("route"),
                points: routePoints,
                width: 5,
                color: const Color(0xFF2563EB),
              )
            );
          });
          debugPrint("ETA fetched: $duration");
        }
      } else {
        debugPrint("Directions API Error: ${data['status']} - ${data['error_message']}");
      }
    } catch(e) {
      debugPrint("Error fetching ETA and Route: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = true); 
    }
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
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Shipment not found.', style: TextStyle(color: Colors.black54)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final shipment = ShipmentModel.fromMap(data, snapshot.data!.id);

          // Trigger one-time ETA/Polyline draw accurately against the very first Remote coordinates
          if (currentPosition != null && !_isFetchingRoute && shipment.toCity.isNotEmpty) {
            _isFetchingRoute = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              getRouteAndETA(currentPosition!, shipment.toCity);
            });
          }

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
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      height: 300,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(20.5937, 78.9629),
                              zoom: 5,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: markers,
                            polylines: polylines, 
                            onMapCreated: (controller) {
                              mapController = controller;
                              // Upon controller mount, jump straight to the current truck pos 
                              if (currentPosition != null) {
                                mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(currentPosition!, 15),
                                );
                              }
                            },
                          ),
                          
                          // Awaiting GPS Overlay
                          if (!isGpsReady)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14, height: 14, 
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Awaiting Transporter GPS',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ETA Overlay Overlay
                            if (etaTime != null)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, color: Color(0xFF2563EB), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ETA: $etaTime',
                                        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
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
                const Text('Journey Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTimeline(shipment.status),
                const SizedBox(height: 20),

                const Text('Shipment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      if (currentPosition != null) ...[
                        _detailRow('Last Lat', currentPosition!.latitude.toStringAsFixed(5)),
                        _detailRow('Last Lng', currentPosition!.longitude.toStringAsFixed(5)),
                      ],
                      if (shipment.transporterId != null)
                        _detailRow('Transporter ID', shipment.transporterId!),
                      _detailRow('Trust Score', '${shipment.trustScore.toStringAsFixed(0)}/100',
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
    final isOnTrack = shipment.status != ShipmentStatus.delayed && shipment.status != ShipmentStatus.delivered;
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
            decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E40AF))),
            const Text('Remote Track Synced', style: TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
          const Spacer(),
          Chip(
            label: Text(isOnTrack ? 'On Track' : label, style: const TextStyle(color: Colors.white)),
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
    final statusOrder = [ShipmentStatus.created, ShipmentStatus.assigned, ShipmentStatus.inTransit, ShipmentStatus.delivered];
    final currentIdx = statusOrder.indexOf(currentStatus);

    return Column(
      children: List.generate(allSteps.length, (i) {
        final stepStatus = allSteps[i]['status'] as ShipmentStatus;
        final done = statusOrder.indexOf(stepStatus) <= currentIdx;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? const Color(0xFF2563EB) : Colors.grey.shade200),
              child: Icon(done ? Icons.check : Icons.circle_outlined, color: done ? Colors.white : Colors.grey, size: 16),
            ),
            if (i < allSteps.length - 1)
              Container(width: 2, height: 40, color: done ? const Color(0xFF2563EB) : Colors.grey.shade200),
          ]),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(allSteps[i]['label'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: done ? Colors.black87 : Colors.black38)),
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
        Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87), textAlign: TextAlign.end)),
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
