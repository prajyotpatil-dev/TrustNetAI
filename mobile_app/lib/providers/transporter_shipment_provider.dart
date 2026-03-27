import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';
import '../repositories/shipment_repository.dart';

class TransporterShipmentProvider extends ChangeNotifier {
  final ShipmentRepository _repository = ShipmentRepository();

  List<ShipmentModel> _shipments = [];
  List<ShipmentModel> _marketplaceShipments = [];
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription? _shipmentSubscription;
  StreamSubscription? _marketplaceSubscription;
  int _limit = 20;
  String? _currentTransporterId;
  bool _isFallbackMode = false;

  List<ShipmentModel> get shipments => _shipments;
  List<ShipmentModel> get marketplaceShipments => _marketplaceShipments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeShipmentsCount => _shipments.where((s) => s.status != ShipmentStatus.delivered).length;
  int get completedShipmentsCount => _shipments.where((s) => s.status == ShipmentStatus.delivered).length;
  double get averageTrustScore {
    if (_shipments.isEmpty) return 0.0;
    final total = _shipments.fold<double>(0.0, (sum, item) => sum + item.trustScore);
    return total / _shipments.length;
  }

  void listenShipments(String transporterId) {
    if (_currentTransporterId == transporterId && _shipmentSubscription != null) return;
    
    _currentTransporterId = transporterId;
    _isLoading = true;
    _error = null;
    _isFallbackMode = false;
    notifyListeners();

    _attachListener();
  }

  void _attachListener() {
    _shipmentSubscription?.cancel();
    _shipmentSubscription = _repository.streamShipmentsByTransporter(_currentTransporterId!, limit: _limit, fallbackNoOrder: _isFallbackMode).listen(
      (shipmentList) {
        if (_isFallbackMode) {
          shipmentList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        _shipments = shipmentList;
        _isLoading = false;
        if (_error == "Preparing shipment database, please wait...") {
          _error = null;
        }
        notifyListeners();
      },
      onError: (e) {
        final errorMsg = e.toString();
        if ((errorMsg.contains('failed-precondition') || errorMsg.contains('requires an index')) && !_isFallbackMode) {
          _isFallbackMode = true;
          _error = "Preparing shipment database, please wait...";
          _isLoading = true;
          notifyListeners();
          _attachListener();
          return;
        }
        _error = errorMsg;
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  void listenMarketplaceShipments() {
    _marketplaceSubscription?.cancel();
    _marketplaceSubscription = _repository.streamMarketplaceShipments(limit: 50).listen(
      (list) {
        _marketplaceShipments = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Marketplace error: $e');
      }
    );
  }

  Future<void> acceptMarketplaceShipment(String shipmentId) async {
    if (_currentTransporterId == null || _currentTransporterId!.isEmpty) return;
    try {
      await _repository.acceptMarketplaceShipment(shipmentId, _currentTransporterId!);
    } catch (e) {
      debugPrint('Error accepting marketplace shipment: $e');
      rethrow;
    }
  }

  void loadMore() {
    if (_shipments.length < _limit) return;
    _limit += 20;
    _attachListener();
  }

  Future<String> createShipment({
    required String fromCity,
    required String toCity,
    required String transporterId,
    String? businessId,
  }) async {
    try {
      return await _repository.createShipment(
        fromCity: fromCity,
        toCity: toCity,
        transporterId: transporterId,
        businessId: businessId,
      );
    } catch (e) {
      debugPrint('Error creating shipment: $e');
      rethrow;
    }
  }

  Future<void> updateShipmentStatus(String shipmentId, ShipmentStatus status, {String? remarks}) async {
    try {
      await _repository.updateStatus(shipmentId, status, remarks: remarks);
    } catch (e) {
      debugPrint('Error updating shipment status: $e');
      rethrow;
    }
  }

  Future<void> uploadEPOD(String shipmentId, File imageFile, {String? remarks}) async {
    try {
      await _repository.uploadEPOD(shipmentId, imageFile, remarks: remarks);
    } catch (e) {
      debugPrint('Error uploading ePOD: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _shipmentSubscription?.cancel();
    _marketplaceSubscription?.cancel();
    super.dispose();
  }
}
