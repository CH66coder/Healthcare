import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationProvider extends ChangeNotifier {
  double latitude = 0.0;
  double longitude = 0.0;

  StreamSubscription<Position>? positionStream;
  Timer? simulationTimer;

  /// EXISTING FEATURE (kept unchanged)
  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  /// REAL GPS TRACKING
  void startLocationUpdates(String requestId) {
    positionStream?.cancel();
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          latitude = position.latitude;
          longitude = position.longitude;

          FirebaseFirestore.instance
              .collection("sos_requests")
              .doc(requestId)
              .update({"driverLat": latitude, "driverLng": longitude});

          notifyListeners();
        });
  }

  /// STOP GPS TRACKING
  void stopLocationUpdates() {
    positionStream?.cancel();
    positionStream = null;
  }

  /// SIMULATION MODE
  /// Starts from driver's real GPS position and moves towards patient
  void startSimulation(String requestId) async {
    simulationTimer?.cancel();

    // Get driver's actual current position
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = pos.latitude;
    double lng = pos.longitude;

    // Update immediately with real position
    latitude = lat;
    longitude = lng;
    notifyListeners();

    // Get patient location from Firestore to move towards them
    final doc = await FirebaseFirestore.instance
        .collection("sos_requests")
        .doc(requestId)
        .get();

    final double targetLat = (doc['latitude'] as num).toDouble();
    final double targetLng = (doc['longitude'] as num).toDouble();

    simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Stop when close enough to patient
      if ((targetLat - lat).abs() < 0.0001 &&
          (targetLng - lng).abs() < 0.0001) {
        timer.cancel();
        return;
      }

      // Move 5% of remaining distance towards patient each step
      final double stepLat = (targetLat - lat) * 0.05;
      final double stepLng = (targetLng - lng) * 0.05;

      lat += stepLat;
      lng += stepLng;

      latitude = lat;
      longitude = lng;

      FirebaseFirestore.instance
          .collection("sos_requests")
          .doc(requestId)
          .update({"driverLat": latitude, "driverLng": longitude});

      notifyListeners();
    });
  }

  /// STOP SIMULATION
  void stopSimulation() {
    simulationTimer?.cancel();
    simulationTimer = null;
  }

  /// Cleanup when provider is disposed
  @override
  void dispose() {
    positionStream?.cancel();
    simulationTimer?.cancel();
    super.dispose();
  }
}
