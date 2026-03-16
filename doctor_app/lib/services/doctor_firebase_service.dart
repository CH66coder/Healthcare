import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorFirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get doctorId => _auth.currentUser?.uid ?? '';

  // ─── AUTH ────────────────────────────────────────────────
  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print('Doctor SignIn Error: $e');
      return null;
    }
  }

  /// Signs up doctor and writes to BOTH collections:
  /// - 'doctor_users' → private doctor profile (login info, etc.)
  /// - 'doctors'      → public listing (patient app searches THIS)
  Future<User?> signUp(
      String email,
      String password,
      String name,
      String specialty, {
      String location = '',
      int experienceYears = 1,
      double consultationFee = 500,
      double rating = 4.5,
      }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);
      final uid = cred.user!.uid;

      // ── Private doctor profile (doctor app uses this) ──
      await _db.collection('doctor_users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'specialty': specialty,
        'role': 'doctor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── Public doctor listing (patient app searches THIS) ──
      await _db.collection('doctors').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'specialty': specialty.toLowerCase().replaceAll(' ', '-'),
        'experience_years': experienceYears,
        'consultation_fee': consultationFee,
        'rating': rating,
        'bangalore_location': location,
        'isAvailable': false,   // toggled by doctor in app
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } catch (e) {
      print('Doctor SignUp Error: $e');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();

  // ─── AVAILABILITY ─────────────────────────────────────────
  /// Toggle online/offline — patient app reads this in real time
  Future<void> setAvailability(bool available) async {
    await _db.collection('doctors').doc(doctorId).update({
      'isAvailable': available,
    });
  }

  Future<bool> getAvailability() async {
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      return doc.data()?['isAvailable'] == true;
    } catch (e) {
      return false;
    }
  }

  // ─── APPOINTMENTS ─────────────────────────────────────────
  Stream<QuerySnapshot> listenToMyAppointments() {
  return _db
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots();
}

  Future<void> confirmAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── VIDEO CALL ───────────────────────────────────────────
  Stream<QuerySnapshot> listenForIncomingCalls() {
    return _db
        .collection('video_calls')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  Future<void> acceptVideoCall(String appointmentId) async {
    await _db.collection('video_calls').doc(appointmentId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getRoomName(String appointmentId) async {
    final doc =
        await _db.collection('video_calls').doc(appointmentId).get();
    return doc.data()?['roomName'] ?? '';
  }

  Future<void> endVideoCall(String appointmentId) async {
    await _db.collection('video_calls').doc(appointmentId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── PRESCRIPTIONS ────────────────────────────────────────
  Future<String> writePrescription({
    required String patientId,
    required String patientName,
    required String appointmentId,
    required List<Map<String, dynamic>> medicines,
    required String diagnosis,
    required String notes,
    String? specialistReferral,
  }) async {
    try {
      final doc = await _db.collection('prescriptions').add({
        'patientId': patientId,
        'patientName': patientName,
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'doctorName': currentUser?.displayName ?? 'Doctor',
        'medicines': medicines,
        'diagnosis': diagnosis,
        'notes': notes,
        'specialistReferral': specialistReferral ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (specialistReferral != null && specialistReferral.isNotEmpty) {
        await _db.collection('referrals').add({
          'patientId': patientId,
          'patientName': patientName,
          'doctorId': doctorId,
          'doctorName': currentUser?.displayName ?? 'Doctor',
          'specialist': specialistReferral,
          'medicines': medicines.map((m) => m['name']).join(', '),
          'appointmentId': appointmentId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _db.collection('appointments').doc(appointmentId).update({
        'prescriptionId': doc.id,
        'status': 'completed',
      });

      return doc.id;
    } catch (e) {
      print('writePrescription Error: $e');
      return '';
    }
  }

  Stream<QuerySnapshot> listenToPrescriptionsForAppointment(
      String appointmentId) {
    return _db
        .collection('prescriptions')
        .where('appointmentId', isEqualTo: appointmentId)
        .snapshots();
  }

  // ─── PATIENT INFO ─────────────────────────────────────────
  Future<Map<String, dynamic>?> getPatientInfo(String patientId) async {
    try {
      final doc = await _db.collection('users').doc(patientId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Stream<QuerySnapshot> listenToPatientLabTests(String patientId) {
    return _db
        .collection('lab_tests')
        .where('patientId', isEqualTo: patientId)
        .snapshots();
  }

  // ─── MEDICINES ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
  try {
    final snap = await _db.collection('medicines').limit(300).get();
    final lower = query.toLowerCase().trim();
    return snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .where((m) {
          final name = (m['Name'] ?? m['name'] ?? m['medicine_name'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(lower);
        })
        .toList();
  } catch (e) {
    print('searchMedicines Error: $e');
    return [];
  }
}
  // ─── DOCTOR PROFILE ───────────────────────────────────────
  Future<Map<String, dynamic>?> getDoctorProfile() async {
    try {
      final doc =
          await _db.collection('doctor_users').doc(doctorId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update public doctor profile fields
  Future<void> updateDoctorProfile({
    String? location,
    int? experienceYears,
    double? consultationFee,
  }) async {
    final updates = <String, dynamic>{};
    if (location != null) updates['bangalore_location'] = location;
    if (experienceYears != null) updates['experience_years'] = experienceYears;
    if (consultationFee != null) updates['consultation_fee'] = consultationFee;
    if (updates.isNotEmpty) {
      await _db.collection('doctors').doc(doctorId).update(updates);
    }
  }

// ─── DOCTOR REQUESTS (Medicine + Lab) ────────────────────
Future<String> sendMedicineRequest({
  required String patientId,
  required String patientName,
  required String appointmentId,
  required List<Map<String, dynamic>> medicines,
}) async {
  try {
    final doc = await _db.collection('doctor_requests').add({
      'type': 'medicine',
      'patientId': patientId,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'doctorName': currentUser?.displayName ?? 'Doctor',
      'medicines': medicines,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  } catch (e) {
    print('sendMedicineRequest Error: $e');
    return '';
  }
}

Future<String> sendLabRequest({
  required String patientId,
  required String patientName,
  required String appointmentId,
  required List<String> tests,
}) async {
  try {
    final doc = await _db.collection('doctor_requests').add({
      'type': 'lab',
      'patientId': patientId,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'doctorName': currentUser?.displayName ?? 'Doctor',
      'tests': tests,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  } catch (e) {
    print('sendLabRequest Error: $e');
    return '';
  }
}
}