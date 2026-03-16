import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SOSService {
  static const String driverPhone = "9000000000";

  static Future<String?> sendSOS({
    required String name,
    required String phone,
    required String emergency,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled");

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double lat = position.latitude;
      double lon = position.longitude;

      final connectivityResult = await Connectivity().checkConnectivity();
      final bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          DocumentReference ref = await FirebaseFirestore.instance
              .collection("sos_requests")
              .add({
            "patient_name": name,
            "phone": phone,
            "emergency": emergency,
            "latitude": lat,
            "longitude": lon,
            "status": "pending",
            "driverName": "",
            "driverPhone": "",
            "ambulanceNumber": "",
            "driverLat": 0,
            "driverLng": 0,
            "time": FieldValue.serverTimestamp(),
          });
          return ref.id;
        } catch (e) {
          await _sendSMSToDriver(name, phone, emergency, lat, lon);
          return null;
        }
      } else {
        await _sendSMSToDriver(name, phone, emergency, lat, lon);
        return null;
      }
    } catch (e) {
      print("Error sending SOS: $e");
      return null;
    }
  }

  static Future<void> _sendSMSToDriver(
    String name,
    String phone,
    String emergency,
    double lat,
    double lon,
  ) async {
    final String googleMapsLink = "https://maps.google.com/?q=$lat,$lon";
    final String message =
        "🚨 EMERGENCY SOS ALERT!\n"
        "Patient: $name\n"
        "Phone: $phone\n"
        "Emergency: $emergency\n"
        "Location: $googleMapsLink\n"
        "Lat: $lat, Lng: $lon";

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: driverPhone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }
}