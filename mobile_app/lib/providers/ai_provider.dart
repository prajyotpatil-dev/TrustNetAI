import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/delay_detection_service.dart';
import '../services/trust_score_service.dart';
import '../services/smart_assignment_service.dart';

/// Central AI State Manager
/// Exposes all AI features to the UI layer
class AIProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final FraudDetectionService _fraudService = FraudDetectionService();
  final DelayDetectionService _delayService = DelayDetectionService();
  final TrustScoreService _trustScoreService = TrustScoreService();
  final SmartAssignmentService _assignmentService = SmartAssignmentService();

  // ── Gemini Report State ─────────────────────────────────────────────────
  String? _geminiReport;
  bool _isLoadingReport = false;
  String? _reportError;

  String? get geminiReport => _geminiReport;
  bool get isLoadingReport => _isLoadingReport;
  String? get reportError => _reportError;

  // ── Dashboard Insight ───────────────────────────────────────────────────
  String? _dashboardInsight;
  bool _isLoadingInsight = false;

  String? get dashboardInsight => _dashboardInsight;
  bool get isLoadingInsight => _isLoadingInsight;

  // ── Fraud Alerts ────────────────────────────────────────────────────────
  int _fraudAlertCount = 0;
  Map<String, List<String>> _fraudAlertsByShipment = {};
  bool _isLoadingFraud = false;

  int get fraudAlertCount => _fraudAlertCount;
  Map<String, List<String>> get fraudAlertsByShipment => _fraudAlertsByShipment;
  bool get isLoadingFraud => _isLoadingFraud;

  // ── Delay Detection ─────────────────────────────────────────────────────
  List<String> _delayedShipmentIds = [];
  int _delayedCount = 0;
  bool _isCheckingDelays = false;

  List<String> get delayedShipmentIds => _delayedShipmentIds;
  int get delayedCount => _delayedCount;
  bool get isCheckingDelays => _isCheckingDelays;

  // ── Smart Assignment ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _transporterRankings = [];
  bool _isLoadingRankings = false;

  List<Map<String, dynamic>> get transporterRankings => _transporterRankings;
  bool get isLoadingRankings => _isLoadingRankings;

  // ── Transporter Trust Stats ─────────────────────────────────────────────
  Map<String, dynamic>? _transporterStats;
  bool _isLoadingStats = false;

  Map<String, dynamic>? get transporterStats => _transporterStats;
  bool get isLoadingStats => _isLoadingStats;

  // ── Fraud Analysis State ─────────────────────────────────────────────────
  String? _fraudAnalysisReport;
  bool _isLoadingFraudAnalysis = false;

  String? get fraudAnalysisReport => _fraudAnalysisReport;
  bool get isLoadingFraudAnalysis => _isLoadingFraudAnalysis;

  // ── Delivery Prediction State ────────────────────────────────────────────
  String? _deliveryPrediction;
  bool _isLoadingPrediction = false;

  String? get deliveryPrediction => _deliveryPrediction;
  bool get isLoadingPrediction => _isLoadingPrediction;

  // ═══════════════════════════════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch AI-generated trust report for a transporter
  Future<void> fetchGeminiReport({
    required String transporterId,
    String? transporterName,
    double? trustScore,
    int? totalDelays,
    double? onTimeRate,
    int? completedTrips,
    double epodCompliance = 0.0,
    double gpsReliability = 100.0,
  }) async {
    _isLoadingReport = true;
    _reportError = null;
    notifyListeners();

    try {
      _geminiReport = await _geminiService.generateTrustReport(
        transporterId: transporterId,
        transporterName: transporterName,
        trustScore: trustScore,
        totalDelays: totalDelays,
        onTimeRate: onTimeRate,
        completedTrips: completedTrips,
        epodCompliance: epodCompliance,
        gpsReliability: gpsReliability,
      );
    } catch (e) {
      _reportError = e.toString();
      debugPrint('[AIProvider] Report error: $e');
    } finally {
      _isLoadingReport = false;
      notifyListeners();
    }
  }

  /// Fetch AI fraud analysis for a transporter
  Future<void> fetchFraudAnalysis({required String transporterId}) async {
    _isLoadingFraudAnalysis = true;
    notifyListeners();

    try {
      _fraudAnalysisReport = await _geminiService.generateFraudAnalysis(
        transporterId: transporterId,
      );
    } catch (e) {
      debugPrint('[AIProvider] Fraud analysis error: $e');
      _fraudAnalysisReport = 'Failed to generate fraud analysis: $e';
    } finally {
      _isLoadingFraudAnalysis = false;
      notifyListeners();
    }
  }

  /// Fetch AI delivery prediction for a transporter
  Future<void> fetchDeliveryPrediction({required String transporterId}) async {
    _isLoadingPrediction = true;
    notifyListeners();

    try {
      _deliveryPrediction = await _geminiService.generateDeliveryPrediction(
        transporterId: transporterId,
      );
    } catch (e) {
      debugPrint('[AIProvider] Prediction error: $e');
      _deliveryPrediction = 'Failed to generate prediction: $e';
    } finally {
      _isLoadingPrediction = false;
      notifyListeners();
    }
  }

  /// Fetch a one-liner dashboard insight
  Future<void> fetchDashboardInsight({
    required int totalShipments,
    required int activeShipments,
    required int delayedShipments,
    required double avgTrustScore,
    required int fraudAlerts,
  }) async {
    _isLoadingInsight = true;
    notifyListeners();

    try {
      _dashboardInsight = await _geminiService.generateDashboardInsight(
        totalShipments: totalShipments,
        activeShipments: activeShipments,
        delayedShipments: delayedShipments,
        avgTrustScore: avgTrustScore,
        fraudAlerts: fraudAlerts,
      );
    } catch (e) {
      debugPrint('[AIProvider] Insight error: $e');
    } finally {
      _isLoadingInsight = false;
      notifyListeners();
    }
  }

  /// Scan for fraud alerts for a business
  Future<void> scanFraudAlerts(String businessId) async {
    _isLoadingFraud = true;
    notifyListeners();

    try {
      _fraudAlertCount = await _fraudService.getBusinessFraudAlertCount(businessId);
    } catch (e) {
      debugPrint('[AIProvider] Fraud scan error: $e');
    } finally {
      _isLoadingFraud = false;
      notifyListeners();
    }
  }

  /// Get fraud alerts for a specific transporter
  Future<void> fetchTransporterFraudFlags(String transporterId) async {
    _isLoadingFraud = true;
    notifyListeners();

    try {
      _fraudAlertsByShipment = await _fraudService.getTransporterFraudFlags(transporterId);
      _fraudAlertCount = _fraudAlertsByShipment.values.fold(0, (sum, flags) => sum + flags.length);
    } catch (e) {
      debugPrint('[AIProvider] Transporter fraud error: $e');
    } finally {
      _isLoadingFraud = false;
      notifyListeners();
    }
  }

  /// Scan for delayed shipments
  Future<void> scanDelays(String businessId) async {
    _isCheckingDelays = true;
    notifyListeners();

    try {
      _delayedShipmentIds = await _delayService.scanBusinessShipments(businessId);
      _delayedCount = await _delayService.getDelayedCount(businessId);
    } catch (e) {
      debugPrint('[AIProvider] Delay scan error: $e');
    } finally {
      _isCheckingDelays = false;
      notifyListeners();
    }
  }

  /// Get smart transporter rankings for a shipment
  Future<void> getSmartAssignments(String fromCity) async {
    _isLoadingRankings = true;
    notifyListeners();

    try {
      _transporterRankings = await _assignmentService.rankTransporters(fromCity);
    } catch (e) {
      debugPrint('[AIProvider] Assignment error: $e');
    } finally {
      _isLoadingRankings = false;
      notifyListeners();
    }
  }

  /// Fetch transporter trust stats
  Future<void> fetchTransporterStats(String transporterId) async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _transporterStats = await _trustScoreService.calculateTransporterTrustScore(transporterId);
    } catch (e) {
      debugPrint('[AIProvider] Stats error: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Recalculate and persist transporter trust score
  Future<void> recalculateTransporterScore(String transporterId) async {
    await _trustScoreService.recalculateAndStore(transporterId);
    await fetchTransporterStats(transporterId);
  }

  /// Run full AI scan for a business (fraud + delays + insight)
  Future<void> runFullBusinessScan({
    required String businessId,
    required int totalShipments,
    required int activeShipments,
    required double avgTrustScore,
  }) async {
    // Run in parallel
    await Future.wait([
      scanFraudAlerts(businessId),
      scanDelays(businessId),
    ]);

    // Fetch AI insight after we have the counts
    fetchDashboardInsight(
      totalShipments: totalShipments,
      activeShipments: activeShipments,
      delayedShipments: _delayedCount,
      avgTrustScore: avgTrustScore,
      fraudAlerts: _fraudAlertCount,
    );
  }

  /// Clear all state
  void clearAll() {
    _geminiReport = null;
    _reportError = null;
    _dashboardInsight = null;
    _fraudAlertCount = 0;
    _fraudAlertsByShipment = {};
    _delayedShipmentIds = [];
    _delayedCount = 0;
    _transporterRankings = [];
    _transporterStats = null;
    _fraudAnalysisReport = null;
    _deliveryPrediction = null;
    notifyListeners();
  }
}
