import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// LocationService
/// - Handles GPS permission request
/// - Periodically writes {lat, lng, updatedAt} to Firestore every 5 seconds
class LocationService {
  Timer? _timer;
  String? _currentShipmentId;

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Returns true if permission was granted or already granted.
  Future<bool> requestPermission() async {
    // On web, the browser handles the permission prompt automatically.
    if (kIsWeb) return true;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }
    return true;
  }

  /// Check if location services are enabled on device.
  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Starts writing GPS location to Firestore every 5 seconds.
  Future<void> startTracking(String shipmentId) async {
    // Avoid double-starting
    if (_currentShipmentId == shipmentId && _timer != null) return;

    stopTracking();
    _currentShipmentId = shipmentId;

    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on this device.');
    }

    final granted = await requestPermission();
    if (!granted) {
      throw Exception(
          'Location permission denied. Please enable it in app settings.');
    }

    // Write immediately, then repeat every 5s
    await _writeLocation(shipmentId);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _writeLocation(shipmentId);
    });
  }

  /// Stops the periodic location timer.
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _currentShipmentId = null;
  }

  bool get isTracking => _timer != null && _timer!.isActive;

  Future<void> _writeLocation(String shipmentId) async {
    try {
      late Position position;
      if (kIsWeb) {
        // Web uses browser geolocation
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } else {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          ),
        );
      }

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
    } catch (e) {
      // Silently log — don't crash the app if a single update fails
      debugPrint('[LocationService] Failed to write location: $e');
    }
  }
}
