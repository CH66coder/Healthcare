import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../database/driver_data.dart';
import '../providers/location_provider.dart';
import '../models/ambulance_request_model.dart';
import '../services/notification_service.dart';

class RequestProvider extends ChangeNotifier {
  String requestStatus = "No Request";

  String? requestId;
  String? patientName;
  String? patientPhone;
  double? patientLat;
  double? patientLng;
  String? patientEmergency; // added

  LocationProvider? _locationProvider;

  void init(LocationProvider locationProvider) {
    _locationProvider = locationProvider;
    listenForRequests();
  }

  void listenForRequests() {
    FirebaseFirestore.instance
        .collection("sos_requests")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              if (requestStatus == "New Request") {
                requestId = null;
                patientName = null;
                patientPhone = null;
                patientLat = null;
                patientLng = null;
                patientEmergency = null; // added
                requestStatus = "No Request";
                notifyListeners();
              }
              return;
            }

            var doc = snapshot.docs.first;
            final data = doc.data();
            final request = AmbulanceRequest.fromMap(doc.id, data);

            print("DEBUG: found pending doc id=${doc.id} existing=$requestId");

            if (requestId != request.id) {
              requestId = request.id;
              patientName = request.patientName;
              patientPhone = request.phone;
              patientLat = request.latitude;
              patientLng = request.longitude;
              patientEmergency = data['emergency'] ?? ''; // added
              requestStatus = "New Request";

              print(
                "DEBUG: New request from $patientName emergency=$patientEmergency",
              );

              NotificationService.showLocalSOSNotification(
                request.patientName,
                request.phone,
              );

              notifyListeners();
            }
          },
          onError: (e) {
            print("DEBUG: Firestore error: $e");
          },
        );
  }

  Future<void> acceptRequest() async {
    if (requestId == null) return;
    Position position = await Geolocator.getCurrentPosition();
    await FirebaseFirestore.instance
        .collection("sos_requests")
        .doc(requestId)
        .update({
          "driverName": DriverData.driver["driverName"],
          "driverPhone": DriverData.driver["driverPhone"],
          "ambulanceNumber": DriverData.driver["ambulanceNumber"],
          "driverLat": position.latitude,
          "driverLng": position.longitude,
          "status": "accepted", // ← lowercase ✅
        });
    _locationProvider?.startSimulation(requestId!);
    requestStatus = "Accepted";
    notifyListeners();
  }

  Future<void> rejectRequest() async {
    if (requestId == null) return;

    await FirebaseFirestore.instance
        .collection("sos_requests")
        .doc(requestId)
        .update({"status": "rejected"});

    requestId = null;
    patientName = null;
    patientPhone = null;
    patientLat = null;
    patientLng = null;
    patientEmergency = null; // added
    requestStatus = "No Request";
    notifyListeners();
  }

  // REPLACE updateRequest method:
  Future<void> updateRequest(String status) async {
    if (status == "Accepted" || status == "accepted") {
      await acceptRequest();
    } else if (status == "Rejected" || status == "rejected") {
      await rejectRequest();
    }
  }
}
