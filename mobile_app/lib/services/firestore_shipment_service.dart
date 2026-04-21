import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';

class FirestoreShipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> streamShipmentsByTransporter(String transporterId, {int limit = 20, bool fallbackNoOrder = false}) {
    var query = _firestore
        .collection('shipments')
        .where('transporterId', isEqualTo: transporterId);
        
    if (!fallbackNoOrder) {
      query = query.orderBy('createdAt', descending: true);
    }
    
    return query.limit(limit).snapshots();
  }

  Stream<QuerySnapshot> streamShipmentsByBusiness(String businessId, {int limit = 20, bool fallbackNoOrder = false}) {
    var query = _firestore
        .collection('shipments')
        .where('businessId', isEqualTo: businessId);
        
    if (!fallbackNoOrder) {
      query = query.orderBy('createdAt', descending: true);
    }
    
    return query.limit(limit).snapshots();
  }

  Stream<QuerySnapshot> streamMarketplaceShipments({int limit = 20, bool fallbackNoOrder = false}) {
    var query = _firestore
        .collection('shipments')
        .where('status', isEqualTo: ShipmentStatus.pending.firestoreValue);
        
    if (!fallbackNoOrder) {
      query = query.orderBy('createdAt', descending: true);
    }
    
    return query.limit(limit).snapshots();
  }

  Future<void> saveShipment(ShipmentModel shipment) async {
    final data = shipment.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('shipments').doc(shipment.shipmentId).set(data);
  }

  Future<void> updateShipment(String shipmentId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('shipments').doc(shipmentId).update(data);
  }

  DocumentReference getShipmentDocRef(String shipmentId) {
    return _firestore.collection('shipments').doc(shipmentId);
  }
  
  String getNewDocId() {
    return _firestore.collection('shipments').doc().id;
  }
}
