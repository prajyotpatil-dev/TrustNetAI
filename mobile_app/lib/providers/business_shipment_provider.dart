import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/shipment_model.dart';
import '../models/shipment_status.dart';
import '../repositories/shipment_repository.dart';

class BusinessShipmentProvider extends ChangeNotifier {
  final ShipmentRepository _repository = ShipmentRepository();

  List<ShipmentModel> _shipments = [];
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription? _shipmentSubscription;
  int _limit = 20;
  String? _currentBusinessId;
  bool _isFallbackMode = false;

  List<ShipmentModel> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeShipmentsCount => _shipments.where((s) => s.status != ShipmentStatus.delivered).length;
  int get completedShipmentsCount => _shipments.where((s) => s.status == ShipmentStatus.delivered).length;
  double get averageTrustScore {
    if (_shipments.isEmpty) return 0.0;
    final total = _shipments.fold<double>(0.0, (sum, item) => sum + item.trustScore);
    return total / _shipments.length;
  }
  int get riskAlertsCount => _shipments.where((s) => s.status == ShipmentStatus.delayed).length;

  /// Starts listening to the shipments collection via repository stream
  void listenShipments(String businessId) {
    if (_currentBusinessId == businessId && _shipmentSubscription != null) return;
    
    _currentBusinessId = businessId;
    _isLoading = true;
    _error = null;
    _isFallbackMode = false;
    notifyListeners();

    _attachListener();
  }

  void _attachListener() {
    _shipmentSubscription?.cancel();
    _shipmentSubscription = _repository.streamShipmentsByBusiness(_currentBusinessId!, limit: _limit, fallbackNoOrder: _isFallbackMode).listen(
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

  void loadMore() {
    if (_shipments.length < _limit) return;
    _limit += 20;
    _attachListener();
  }

  Future<void> assignTransporter(String shipmentId, String transporterId) async {
    try {
      await _repository.assignTransporter(shipmentId, transporterId);
    } catch (e) {
      debugPrint('Error assigning shipment: $e');
      rethrow;
    }
  }

  Future<String> createShipment({
    required String fromCity,
    required String toCity,
  }) async {
    try {
      return await _repository.createShipment(
        fromCity: fromCity,
        toCity: toCity,
        transporterId: null,
        businessId: _currentBusinessId,
      );
    } catch (e) {
      debugPrint('Error creating shipment: $e');
      rethrow;
    }
  }

  Future<void> verifyEPOD(String shipmentId, String verifiedByUid) async {
    try {
      await _repository.verifyEPOD(shipmentId, verifiedByUid);
    } catch (e) {
      debugPrint('Error verifying ePOD: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _shipmentSubscription?.cancel();
    super.dispose();
  }
}
