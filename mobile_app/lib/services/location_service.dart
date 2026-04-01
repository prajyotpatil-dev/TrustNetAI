import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'fraud_detection_service.dart';

/// LocationService
/// - Handles GPS permission using Geolocator
/// - Streams real-time updates to Firestore
/// - Enhanced with speed, heading, and fraud detection
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  String? _currentShipmentId;

  // Previous position tracking for fraud detection
  double? _prevLat;
  double? _prevLng;
  DateTime? _prevTimestamp;

  final FraudDetectionService _fraudDetection = FraudDetectionService();

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check permissions using Geolocator
  Future<void> checkPermissions() async {
    if (kIsWeb) return; // Handled by browser

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    if (permission == LocationPermission.denied) {
      return Future.error('Location permission is denied.');
    }
  }

  /// Starts streaming GPS location to Firestore
  Future<void> startTracking(String shipmentId) async {
    if (_currentShipmentId == shipmentId && isTracking) return;

    stopTracking();
    _currentShipmentId = shipmentId;
    _prevLat = null;
    _prevLng = null;
    _prevTimestamp = null;

    await checkPermissions();

    // Get initial high-accuracy fix before starting stream
    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );
      // Only write if accuracy is acceptable (≤ 20 metres)
      if (initialPos.accuracy <= 20) {
        await _writeLocation(shipmentId, initialPos);
      } else {
        debugPrint('[LocationService] Initial fix too inaccurate (${initialPos.accuracy}m), skipping.');
      }
    } catch (e) {
      debugPrint('[LocationService] Initial fetch failed or timed out: $e');
      // Fallback: last known position (best-effort)
      final Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && lastPos.accuracy <= 20) {
        await _writeLocation(shipmentId, lastPos);
      }
    }

    // ── Real-Time Stream ────────────────────────────────────────────────────
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // ── GPS Drift Filter ─────────────────────────────────────────────────
        if (position.accuracy > 20) {
          debugPrint('[LocationService] Ignoring inaccurate reading: ${position.accuracy}m accuracy');
          return;
        }

        if (_currentShipmentId != null) {
          _writeLocation(_currentShipmentId!, position);
        }
      },
      onError: (error) {
        debugPrint('[LocationService] Stream error: $error');
      },
    );
  }

  /// Stops the location stream.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentShipmentId = null;
    _prevLat = null;
    _prevLng = null;
    _prevTimestamp = null;
  }

  bool get isTracking => _positionStreamSubscription != null;

  Future<void> _writeLocation(String shipmentId, Position position) async {
    try {
      // Convert speed from m/s to km/h
      final speedKmh = position.speed >= 0 ? position.speed * 3.6 : 0.0;

      // ── Fraud Detection ──────────────────────────────────────────────────
      if (_prevLat != null && _prevLng != null && _prevTimestamp != null) {
        final timeDelta = DateTime.now().difference(_prevTimestamp!).inMinutes;

        // Check for GPS jump
        final gpsFlag = _fraudDetection.detectGPSJump(
          prevLat: _prevLat!,
          prevLng: _prevLng!,
          currentLat: position.latitude,
          currentLng: position.longitude,
          timeDeltaMinutes: timeDelta > 0 ? timeDelta : 1,
        );
        if (gpsFlag != null) {
          debugPrint('[LocationService] FRAUD DETECTED: $gpsFlag');
          _fraudDetection.runAllChecks(
            shipmentId: shipmentId,
            prevLat: _prevLat,
            prevLng: _prevLng,
            currentLat: position.latitude,
            currentLng: position.longitude,
            timeDeltaMinutes: timeDelta > 0 ? timeDelta : 1,
            speedKmh: speedKmh,
          );
        }

        // Check for unrealistic speed
        final speedFlag = _fraudDetection.detectUnrealisticSpeed(speedKmh);
        if (speedFlag != null) {
          debugPrint('[LocationService] SPEED ANOMALY: $speedFlag');
        }
      }

      // Update previous position
      _prevLat = position.latitude;
      _prevLng = position.longitude;
      _prevTimestamp = DateTime.now();

      // ── Write to Firestore ─────────────────────────────────────────────
      await FirebaseFirestore.instance
          .collection('shipments')
          .doc(shipmentId)
          .update({
        'currentLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'speed': speedKmh,
        'heading': position.heading,
      });

      debugPrint('[LocationService] Updated: ${position.latitude}, ${position.longitude} @ ${speedKmh.toStringAsFixed(1)}km/h');
    } catch (e) {
      debugPrint('[LocationService] Firestore write failed: $e');
    }
  }
}
