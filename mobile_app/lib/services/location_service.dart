import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// LocationService
/// - Handles GPS permission using Geolocator
/// - Streams real-time updates to Firestore
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  String? _currentShipmentId;

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
    // bestForNavigation uses all available sensors (GPS + network + barometer)
    // distanceFilter: 5 m → update every 5 m moved (more precise than 10 m)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // ── GPS Drift Filter ─────────────────────────────────────────────────
        // Ignore readings where the device reports > 20 m horizontal error.
        // This prevents the marker from jumping off-road during weak signal.
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
  }

  bool get isTracking => _positionStreamSubscription != null;

  Future<void> _writeLocation(String shipmentId, Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('shipments')
          .doc(shipmentId)
          .update({
        'currentLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
      debugPrint('[LocationService] Updated location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('[LocationService] Firestore write failed (possibly no internet): $e');
    }
  }
}
