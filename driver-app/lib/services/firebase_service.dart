import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../database/driver_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Listen for pending SOS requests ──────────────────
  Stream<QuerySnapshot> listenForPendingSOS() {
    return _db
        .collection('sos_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ─── Accept SOS request ───────────────────────────────
  Future<void> acceptSOSRequest(String requestId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _db.collection('sos_requests').doc(requestId).update({
        'driverName': DriverData.driver['driverName'],
        'driverPhone': DriverData.driver['driverPhone'],
        'ambulanceNumber': DriverData.driver['ambulanceNumber'],
        'driverLat': position.latitude,
        'driverLng': position.longitude,
        'status': 'accepted', // ← lowercase to match patient app
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('acceptSOSRequest error: $e');
    }
  }

  // ─── Reject SOS request ───────────────────────────────
  Future<void> rejectSOSRequest(String requestId) async {
    try {
      await _db.collection('sos_requests').doc(requestId).update({
        'status': 'rejected',
      });
    } catch (e) {
      print('rejectSOSRequest error: $e');
    }
  }

  // ─── Update driver live location ──────────────────────
  Future<void> updateDriverLocation(String requestId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _db.collection('sos_requests').doc(requestId).update({
        'driverLat': position.latitude,
        'driverLng': position.longitude,
      });
    } catch (e) {
      print('updateDriverLocation error: $e');
    }
  }

  // ─── Complete trip ─────────────────────────────────────
  Future<void> completeTrip(String requestId) async {
    try {
      await _db.collection('sos_requests').doc(requestId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('completeTrip error: $e');
    }
  }
}
