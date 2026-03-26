import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';
import 'dart:math';

class ShipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateLRNumber() {
    final random = Random();
    final number = random.nextInt(90000) + 10000; // 5 digit number
    return 'LR-$number';
  }

  Future<String> createShipment({
    required String fromCity,
    required String toCity,
    required String transporterId,
    String? businessId,
  }) async {
    final docRef = _firestore.collection('shipments').doc();
    final lrNumber = _generateLRNumber();
    
    final shipment = ShipmentModel(
      shipmentId: docRef.id,
      lrNumber: lrNumber,
      fromCity: fromCity,
      toCity: toCity,
      status: 'created',
      transporterId: transporterId,
      businessId: businessId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Using Timestamp for Firestore standard, but the model handles iso8601 strings too
    final data = shipment.toMap();
    data['createdAt'] = FieldValue.serverTimestamp(); 
    data['updatedAt'] = FieldValue.serverTimestamp(); 
    
    await docRef.set(data);
    return lrNumber;
  }

  Stream<List<ShipmentModel>> streamTransporterShipments(String transporterId) {
    return _firestore
        .collection('shipments')
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ShipmentModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
