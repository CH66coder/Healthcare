import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../database/driver_data.dart'; // fixed: was ../data/

Future<void> acceptRequest(String requestId) async {
  Position pos = await Geolocator.getCurrentPosition();

  await FirebaseFirestore.instance
      .collection("sos_requests") // fixed: was "requests"
      .doc(requestId)
      .update({
        "driverName": DriverData.driver["driverName"],
        "driverPhone": DriverData.driver["driverPhone"],
        "ambulanceNumber": DriverData.driver["ambulanceNumber"],
        "driverLat": pos.latitude,
        "driverLng": pos.longitude,
        "status": "accepted",
      });
}
