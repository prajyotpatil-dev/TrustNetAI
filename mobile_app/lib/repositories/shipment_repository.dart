import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';
import '../services/firestore_shipment_service.dart';
import '../services/lr_generator_service.dart';

class ShipmentRepository {
  final FirestoreShipmentService _firestoreService = FirestoreShipmentService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LRGeneratorService _lrGeneratorService = LRGeneratorService();

  Stream<List<ShipmentModel>> streamShipmentsByTransporter(String transporterId, {int limit = 20, bool fallbackNoOrder = false}) {
    return _firestoreService.streamShipmentsByTransporter(transporterId, limit: limit, fallbackNoOrder: fallbackNoOrder).map(
      (snapshot) => snapshot.docs.map((doc) => ShipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Stream<List<ShipmentModel>> streamShipmentsByBusiness(String businessId, {int limit = 20, bool fallbackNoOrder = false}) {
    return _firestoreService.streamShipmentsByBusiness(businessId, limit: limit, fallbackNoOrder: fallbackNoOrder).map(
      (snapshot) => snapshot.docs.map((doc) => ShipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Stream<List<ShipmentModel>> streamMarketplaceShipments({int limit = 20, bool fallbackNoOrder = false}) {
    return _firestoreService.streamMarketplaceShipments(limit: limit, fallbackNoOrder: fallbackNoOrder).map(
      (snapshot) => snapshot.docs.map((doc) => ShipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Future<String> createShipment({
    required String fromCity,
    required String toCity,
    String? transporterId,
    String? businessId,
  }) async {
    final newId = _firestoreService.getNewDocId();
    final lrNumber = await _lrGeneratorService.generateLRNumber('TR');

    final shipment = ShipmentModel(
      shipmentId: newId,
      lrNumber: lrNumber,
      fromCity: fromCity,
      toCity: toCity,
      status: transporterId == null ? ShipmentStatus.pending : ShipmentStatus.created,
      transporterId: transporterId,
      businessId: businessId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveShipment(shipment);
    return lrNumber;
  }

  Future<void> assignTransporter(String shipmentId, String transporterId) async {
    await _firestoreService.updateShipment(shipmentId, {
      'transporterId': transporterId,
    });
  }

  Future<void> acceptMarketplaceShipment(String shipmentId, String transporterId) async {
    await _firestoreService.updateShipment(shipmentId, {
      'transporterId': transporterId,
      'status': ShipmentStatus.assigned.firestoreValue,
    });
  }

  double calculateTrustScore(ShipmentStatus currentStatus, ShipmentStatus newStatus, double currentScore) {
    if (currentStatus == newStatus) return currentScore;
    if (newStatus == ShipmentStatus.delivered) return currentScore + 5.0;
    if (newStatus == ShipmentStatus.delayed) return currentScore - 10.0;
    return currentScore;
  }

  Future<void> updateStatus(String shipmentId, ShipmentStatus newStatus, {String? remarks}) async {
    final docSnap = await _firestoreService.getShipmentDocRef(shipmentId).get();
    if (!docSnap.exists) throw Exception("Shipment missing.");
    
    final data = docSnap.data() as Map<String,dynamic>?;
    final currentScore = (data?['trustScore'] as num?)?.toDouble() ?? 0.0;
    final String statusStr = data?['status'] as String? ?? 'created';
    final currentStatus = ShipmentStatusExtension.fromString(statusStr);
    
    final newScore = calculateTrustScore(currentStatus, newStatus, currentScore);

    await _firestoreService.updateShipment(shipmentId, {
      'status': newStatus.firestoreValue,
      'trustScore': newScore,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }

  Future<void> uploadEPOD(String shipmentId, File imageFile, {String? remarks}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'epod/$shipmentId/$timestamp.jpg';
    final ref = _storage.ref().child(path);
    
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();

    final docSnap = await _firestoreService.getShipmentDocRef(shipmentId).get();
    if (!docSnap.exists) throw Exception("Shipment missing.");

    final data = docSnap.data() as Map<String,dynamic>?;
    final currentScore = (data?['trustScore'] as num?)?.toDouble() ?? 0.0;
    final newScore = currentScore + 10.0; // Bonus for successful ePOD

    await _firestoreService.updateShipment(shipmentId, {
      'epodUrl': downloadUrl,
      'status': ShipmentStatus.delivered.firestoreValue,
      'trustScore': newScore,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }
}
