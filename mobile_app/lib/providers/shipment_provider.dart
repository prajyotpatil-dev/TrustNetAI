import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';
import '../services/shipment_service.dart';

class ShipmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShipmentService _shipmentService = ShipmentService(); // Optional composition

  List<ShipmentModel> _shipments = [];
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription? _shipmentSubscription;
  int _limit = 20;
  String? _currentTransporterId;

  List<ShipmentModel> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Starts listening to the shipments collection
  void listenShipments(String transporterId) {
    if (_currentTransporterId == transporterId && _shipmentSubscription != null) return;
    
    _currentTransporterId = transporterId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _attachListener();
  }

  void _attachListener() {
    _shipmentSubscription?.cancel();
    _shipmentSubscription = _firestore
        .collection('shipments')
        .where('transporterId', isEqualTo: _currentTransporterId)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .listen((snapshot) {
      _shipments = snapshot.docs.map((doc) => ShipmentModel.fromMap(doc.data(), doc.id)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void loadMore() {
    // If we have fewer shipments than our limit, we reached the end
    if (_shipments.length < _limit) return;
    
    _limit += 20;
    _attachListener();
  }

  /// Calculates the new trust score impact internally and returns the delta
  double _calculateTrustScoreImpact(String status) {
    switch (status) {
      case 'delivered': return 5.0; // Positive boost
      case 'delayed': return -10.0; // Penalty
      default: return 0.0;
    }
  }

  Future<void> updateShipmentStatus(String shipmentId, String status, {String? remarks}) async {
    try {
      final docRef = _firestore.collection('shipments').doc(shipmentId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) throw Exception("Shipment missing.");
      
      final currentScore = (docSnap.data()?['trustScore'] as num?)?.toDouble() ?? 0.0;
      final newScore = currentScore + _calculateTrustScoreImpact(status);

      await docRef.update({
        'status': status,
        'trustScore': newScore,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // The stream automatically pushes this reactive change to _shipments
    } catch (e) {
      debugPrint('Error updating shipment status: $e');
      rethrow;
    }
  }

  Future<void> uploadEPOD(String shipmentId, {String? remarks}) async {
    try {
      // Simulate file upload latency or actual upload to Firebase Storage if we had File bytes.
      await Future.delayed(const Duration(seconds: 1));
      final fakeFirebaseStorageUrl = "https://firebasestorage.googleapis.com/v0/b/trustnet/o/mock_epod_$shipmentId.png";

      final docRef = _firestore.collection('shipments').doc(shipmentId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) throw Exception("Shipment missing.");

      final currentScore = (docSnap.data()?['trustScore'] as num?)?.toDouble() ?? 0.0;
      final newScore = currentScore + 10.0; // Bonus for completing ePOD

      await docRef.update({
        'epodUrl': fakeFirebaseStorageUrl,
        'status': 'delivered',
        'trustScore': newScore,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error uploading ePOD: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _shipmentSubscription?.cancel();
    super.dispose();
  }
}
