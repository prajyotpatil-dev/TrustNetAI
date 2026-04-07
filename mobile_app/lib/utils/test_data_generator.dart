import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';

class TestDataGenerator {
  static Future<void> generateSampleData(String transporterId) async {
    final db = FirebaseFirestore.instance;

    print("Generating AI Trust Score Sample Data...");

    // 1. Excellent On-Time Delivery with EPOD and GPS
    await _addSampleShipment(
      db,
      transporterId,
      status: ShipmentStatus.delivered,
      delayMinutes: 0,
      epodUploaded: true,
      gpsCount: 12,
      isCancelled: false,
      hoursAgo: 48,
    );

    // 2. Good Delivery but slightly delayed
    await _addSampleShipment(
      db,
      transporterId,
      status: ShipmentStatus.delivered,
      delayMinutes: 30, // 30 mins delay
      epodUploaded: true,
      gpsCount: 10,
      isCancelled: false,
      hoursAgo: 24,
    );

    // 3. Delivered, but missing EPOD
    await _addSampleShipment(
      db,
      transporterId,
      status: ShipmentStatus.delivered,
      delayMinutes: 0,
      epodUploaded: false, // Penalty
      gpsCount: 8,
      isCancelled: false,
      hoursAgo: 12,
    );

    // 4. Cancelled Shipment Penalty
    await _addSampleShipment(
      db,
      transporterId,
      status: ShipmentStatus.delayed, // Since cancelled enum does not exist, but flag will penalize
      delayMinutes: 0,
      epodUploaded: false,
      gpsCount: 2,
      isCancelled: true, // Penalty
      hoursAgo: 6,
    );

    // 5. In Transit (Updating GPS)
    await _addSampleShipment(
      db,
      transporterId,
      status: ShipmentStatus.inTransit,
      delayMinutes: 0,
      epodUploaded: false,
      gpsCount: 5,
      isCancelled: false,
      hoursAgo: 2,
    );
    
    // Also set a baseline User Rating
    await db.collection('users').doc(transporterId).set(
      {'avgRating': 4.8},
      SetOptions(merge: true),
    );

    print("Sample data generated successfully.");
  }

  static Future<void> _addSampleShipment(
    FirebaseFirestore db,
    String transporterId, {
    required ShipmentStatus status,
    required int delayMinutes,
    required bool epodUploaded,
    required int gpsCount,
    required bool isCancelled,
    required int hoursAgo,
  }) async {
    final docRef = db.collection('shipments').doc();
    final now = DateTime.now();
    
    // Simulate timestamps spreading across time
    final createdAt = now.subtract(Duration(hours: hoursAgo + 5));
    final assignedAt = now.subtract(Duration(hours: hoursAgo + 4));
    final pickedUpAt = now.subtract(Duration(hours: hoursAgo + 3));
    final deliveredAt = status == ShipmentStatus.delivered ? now.subtract(Duration(hours: hoursAgo)) : null;
    final expectedDelivery = pickedUpAt.add(const Duration(hours: 3));

    final shipment = ShipmentModel(
      shipmentId: docRef.id,
      lrNumber: 'AI-TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      fromCity: 'Mumbai',
      toCity: 'Pune',
      status: status,
      transporterId: transporterId,
      businessId: 'SAMPLE-BUSINESS',
      epodUrl: epodUploaded ? "https://example.com/sample_epod.jpg" : null,
      trustScore: 0.0,
      createdAt: createdAt,
      updatedAt: now,
      assignedAt: assignedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      expectedDelivery: expectedDelivery,
      delayInMinutes: delayMinutes,
      gpsUpdatesCount: gpsCount,
      cancellationFlag: isCancelled,
    );

    await docRef.set(shipment.toMap());
  }
}
