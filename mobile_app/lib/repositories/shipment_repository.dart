import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';
import '../services/firestore_shipment_service.dart';
import '../services/lr_generator_service.dart';
import '../services/trust_score_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/delay_detection_service.dart';
import '../services/eta_service.dart';

class ShipmentRepository {
  final FirestoreShipmentService _firestoreService = FirestoreShipmentService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LRGeneratorService _lrGeneratorService = LRGeneratorService();
  final TrustScoreService _trustScoreService = TrustScoreService();
  final FraudDetectionService _fraudDetectionService = FraudDetectionService();
  final DelayDetectionService _delayDetectionService = DelayDetectionService();
  final ETAService _etaService = ETAService();

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
    double? distanceKm,
  }) async {
    final newId = _firestoreService.getNewDocId();
    final lrNumber = await _lrGeneratorService.generateLRNumber('TR');

    // Auto-calculate expected delivery if distance is provided
    DateTime? expectedDelivery;
    if (distanceKm != null && distanceKm > 0) {
      expectedDelivery = _delayDetectionService.estimateDeliveryTime(distanceKm: distanceKm);
    }

    final shipment = ShipmentModel(
      shipmentId: newId,
      lrNumber: lrNumber,
      fromCity: fromCity,
      toCity: toCity,
      status: transporterId == null ? ShipmentStatus.pending : ShipmentStatus.created,
      transporterId: transporterId,
      businessId: businessId,
      trustScore: 50.0, // Start with a neutral score
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expectedDelivery: expectedDelivery,
      distanceKm: distanceKm,
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
    final docRef = _firestoreService.getShipmentDocRef(shipmentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw Exception("Shipment missing.");
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data?['transporterId'] != null || data?['status'] != ShipmentStatus.pending.firestoreValue) {
        throw Exception("Shipment is already assigned or no longer available.");
      }

      transaction.update(docRef, {
        'transporterId': transporterId,
        'status': ShipmentStatus.assigned.firestoreValue,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Enhanced trust score calculation using AI Trust Score Service
  Future<double> calculateTrustScore(String shipmentId, ShipmentStatus newStatus) async {
    final docSnap = await _firestoreService.getShipmentDocRef(shipmentId).get();
    if (!docSnap.exists) return 0.0;

    final data = docSnap.data() as Map<String, dynamic>?;
    if (data == null) return 0.0;

    final hasEpod = data['epodUrl'] != null && (data['epodUrl'] as String).isNotEmpty;
    final wasDelayed = data['delayDetectedAt'] != null || newStatus == ShipmentStatus.delayed;
    final currentLocation = data['currentLocation'] as Map<String, dynamic>?;
    final gpsReliability = currentLocation != null ? 90.0 : 50.0;

    return _trustScoreService.calculateShipmentTrustScore(
      wasOnTime: !wasDelayed && newStatus == ShipmentStatus.delivered,
      hasEpod: hasEpod,
      gpsAccuracyPercent: gpsReliability,
      wasDelayed: wasDelayed,
    );
  }

  Future<void> updateStatus(String shipmentId, ShipmentStatus newStatus, {String? remarks}) async {
    final docSnap = await _firestoreService.getShipmentDocRef(shipmentId).get();
    if (!docSnap.exists) throw Exception("Shipment missing.");

    final data = docSnap.data() as Map<String, dynamic>?;
    final currentScore = (data?['trustScore'] as num?)?.toDouble() ?? 50.0;

    // Calculate new trust score using AI engine
    double newScore = currentScore;
    if (newStatus == ShipmentStatus.delivered) {
      newScore = await _trustScoreService.quickScoreUpdate(shipmentId, delivered: true);
    } else if (newStatus == ShipmentStatus.delayed) {
      newScore = await _trustScoreService.quickScoreUpdate(shipmentId, delayed: true);
    }

    final updateData = <String, dynamic>{
      'status': newStatus.firestoreValue,
      'trustScore': newScore,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    };

    // Mark delay detection timestamp
    if (newStatus == ShipmentStatus.delayed && data?['delayDetectedAt'] == null) {
      updateData['delayDetectedAt'] = DateTime.now().toIso8601String();
    }

    await _firestoreService.updateShipment(shipmentId, updateData);

    // Recalculate transporter aggregate score
    final transporterId = data?['transporterId'] as String?;
    if (transporterId != null) {
      _trustScoreService.recalculateAndStore(transporterId);
    }
  }

  Future<void> uploadEPOD(String shipmentId, File imageFile, {String? remarks}) async {
    // ── Verify user is authenticated before upload ───────────────────────
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to upload ePOD. Please sign in and try again.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'epod/$shipmentId/$timestamp.jpg';
    final ref = _storage.ref().child(path);

    try {
      await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': currentUser.uid,
            'shipmentId': shipmentId,
          },
        ),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception('Storage permission denied. Please ensure you are logged in and try again.');
      }
      rethrow;
    }
    final downloadUrl = await ref.getDownloadURL();

    // ── Compute image hash for fraud detection ────────────────────────────
    final imageBytes = await imageFile.readAsBytes();
    final imageHash = sha256.convert(imageBytes).toString();

    // ── Capture geo-tagged metadata ──────────────────────────────────────
    Map<String, dynamic> proofMetadata = {
      'proofImage': downloadUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'imageHash': imageHash,
    };

    // Try to get current location for geo-tagging
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      proofMetadata['lat'] = position.latitude;
      proofMetadata['lng'] = position.longitude;
    } catch (e) {
      debugPrint('[ShipmentRepo] Could not geo-tag ePOD: $e');
    }

    // ── Check for image reuse fraud ──────────────────────────────────────
    await _fraudDetectionService.runAllChecks(
      shipmentId: shipmentId,
      imageHash: imageHash,
    );

    // ── Update shipment with ePOD + trust score boost ────────────────────
    final newScore = await _trustScoreService.quickScoreUpdate(
      shipmentId,
      epodUploaded: true,
      delivered: true,
    );

    await _firestoreService.updateShipment(shipmentId, {
      'epodUrl': downloadUrl,
      'epodUploadedAt': DateTime.now().toIso8601String(),
      'proofMetadata': proofMetadata,
      'status': ShipmentStatus.delivered.firestoreValue,
      'trustScore': newScore,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });

    // Recalculate transporter aggregate
    final docSnap = await _firestoreService.getShipmentDocRef(shipmentId).get();
    final transporterId = (docSnap.data() as Map<String, dynamic>?)?['transporterId'] as String?;
    if (transporterId != null) {
      _trustScoreService.recalculateAndStore(transporterId);
    }
  }

  /// Get transporter analytics stats
  Future<Map<String, dynamic>> getTransporterStats(String transporterId) async {
    return _trustScoreService.calculateTransporterTrustScore(transporterId);
  }

  /// Get predictive ETA display string
  String getPredictiveETA(double distanceKm, {double avgSpeed = 45.0}) {
    return _etaService.getETADisplay(distanceKm: distanceKm, avgSpeedKmh: avgSpeed);
  }

  /// Get traffic condition for display
  String getTrafficCondition() {
    return _etaService.getTrafficCondition();
  }

  /// Business owner marks an ePOD as verified
  Future<void> verifyEPOD(String shipmentId, String verifiedByUid) async {
    await _firestoreService.updateShipment(shipmentId, {
      'epodVerified': true,
      'epodVerifiedAt': DateTime.now().toIso8601String(),
      'epodVerifiedBy': verifiedByUid,
    });
  }
}
