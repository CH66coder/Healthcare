import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationProvider extends ChangeNotifier {
  double latitude = 0.0;
  double longitude = 0.0;

  StreamSubscription<Position>? positionStream;
  Timer? simulationTimer;

  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

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
              .collection("sos_requests") // fixed: was "requests"
              .doc(requestId)
              .update({"driverLat": latitude, "driverLng": longitude});

          notifyListeners();
        });
  }

  void stopLocationUpdates() {
    positionStream?.cancel();
    positionStream = null;
  }

  void startSimulation(String requestId) {
    simulationTimer?.cancel();

    double lat = 13.0827;
    double lng = 80.2707;

    simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      lat += 0.0001;
      lng += 0.0001;

      latitude = lat;
      longitude = lng;

      FirebaseFirestore.instance
          .collection("sos_requests") // fixed: was "requests"
          .doc(requestId)
          .update({"driverLat": latitude, "driverLng": longitude});

      notifyListeners();
    });
  }

  void stopSimulation() {
    simulationTimer?.cancel();
    simulationTimer = null;
  }

  @override
  void dispose() {
    positionStream?.cancel();
    simulationTimer?.cancel();
    super.dispose();
  }
}
