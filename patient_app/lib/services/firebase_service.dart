import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── AUTH ────────────────────────────────────────────────
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return cred.user;
    } catch (e) {
      print('SignUp Error: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print('SignIn Error: $e');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();
  User? get currentUser => _auth.currentUser;

  // ─── DOCTORS ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDoctorsBySpecialty(
      String specialty) async {
    try {
      String formatted = specialty.toLowerCase().replaceAll(' ', '-');
      final query = await _db
          .collection('doctors')
          .where('specialty', isEqualTo: formatted)
          .limit(3)
          .get();
      return query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      print('getDoctors Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllDoctors(
      {String? specialty}) async {
    try {
      Query query = _db.collection('doctors');
      if (specialty != null && specialty != 'all') {
        query = query.where('specialty', isEqualTo: specialty);
      }
      final snap = await query.limit(20).get();
      return snap.docs
          .map((d) =>
              {...(d.data() as Map<String, dynamic>), 'id': d.id})
          .toList();
    } catch (e) {
      print('getAllDoctors Error: $e');
      return [];
    }
  }

  Future<List<String>> getSpecialties() async {
    try {
      final snap = await _db.collection('doctors').get();
      final specialties = snap.docs
          .map((d) => d.data()['specialty']?.toString() ?? '')
          .toSet()
          .where((s) => s.isNotEmpty)
          .toList();
      specialties.sort();
      return specialties;
    } catch (e) {
      return [];
    }
  }

  Stream<DocumentSnapshot> listenToDoctorAvailability(String doctorId) {
    return _db.collection('doctors').doc(doctorId).snapshots();
  }

  // ─── MEDICINES ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMedicines(
      {String? category}) async {
    try {
      Query query = _db.collection('medicines');
      if (category != null && category != 'All') {
        query = query.where('Category', isEqualTo: category);
      }
      final snap = await query.limit(30).get();
      final results = snap.docs
          .map((d) =>
              {...(d.data() as Map<String, dynamic>), 'id': d.id})
          .toList();
      if (results.isNotEmpty) {
        print('Medicine fields: ${results.first.keys.toList()}');
      } else {
        print('No medicines found in Firestore.');
      }
      return results;
    } catch (e) {
      print('getMedicines Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    try {
      final snap =
          await _db.collection('medicines').limit(300).get();
      final lower = query.toLowerCase().trim();
      return snap.docs
          .map((d) =>
              {...(d.data() as Map<String, dynamic>), 'id': d.id})
          .where((m) {
            final name =
                (m['Name'] ?? m['name'] ?? m['medicine_name'] ?? '')
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

  // ─── APPOINTMENTS ─────────────────────────────────────────
  Future<String> bookAppointment(Map<String, dynamic> data) async {
    try {
      final cleanData = Map<String, dynamic>.from(data)
        ..remove('status');
      final doc = await _db.collection('appointments').add({
        ...cleanData,
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return doc.id;
    } catch (e) {
      print('bookAppointment Error: $e');
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    try {
      final snap = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: currentUser?.uid ?? '')
          .get();
      return snap.docs
          .map((d) =>
              {...(d.data() as Map<String, dynamic>), 'id': d.id})
          .toList();
    } catch (e) {
      print('getMyAppointments Error: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> listenToMyAppointments() {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .snapshots();
  }

  // ─── ORDERS ───────────────────────────────────────────────
  Future<String> orderMedicine(
      String medicineName, String pharmacy, String sessionId) async {
    try {
      final doc = await _db.collection('orders').add({
        'medicine': medicineName,
        'pharmacy': pharmacy,
        'sessionId': sessionId,
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      print('orderMedicine Error: $e');
      return '';
    }
  }

  Future<String> placeOrder(List<Map<String, dynamic>> cartItems,
      String pharmacy, double total) async {
    try {
      final doc = await _db.collection('orders').add({
        'items': cartItems,
        'pharmacy': pharmacy,
        'total': total,
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      print('placeOrder Error: $e');
      return '';
    }
  }

  Stream<QuerySnapshot> listenToMyOrders() {
    return _db
        .collection('orders')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .snapshots();
  }

  // ─── LAB TESTS ────────────────────────────────────────────
  Future<String> bookLabTest(Map<String, dynamic> data) async {
    try {
      final doc = await _db.collection('lab_tests').add({
        ...data,
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      return '';
    }
  }

  Stream<QuerySnapshot> listenToMyLabTests() {
    return _db
        .collection('lab_tests')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .snapshots();
  }

  // ─── CHAT HISTORY ─────────────────────────────────────────
  Future<void> saveChatMessage(
      String sessionId, String text, String sender) async {
    try {
      await _db
          .collection('chat_history')
          .doc(sessionId)
          .collection('messages')
          .add({
        'text': text,
        'sender': sender,
        'patientId': currentUser?.uid ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('saveChatMessage Error: $e');
    }
  }

  // ─── CHAT SESSIONS ────────────────────────────────────────
  Future<void> saveChatSession({
    required String sessionId,
    required String title,
    required String lastMessage,
  }) async {
    try {
      await _db.collection('chat_sessions').doc(sessionId).set({
        'sessionId': sessionId,
        'patientId': currentUser?.uid ?? '',
        'title': title,
        'lastMessage': lastMessage,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('saveChatSession Error: $e');
    }
  }

  Future<void> updateChatSession({
    required String sessionId,
    required String lastMessage,
  }) async {
    try {
      await _db
          .collection('chat_sessions')
          .doc(sessionId)
          .update({
        'lastMessage': lastMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('updateChatSession Error: $e');
    }
  }

  Stream<QuerySnapshot> listenToChatSessions() {
    return _db
        .collection('chat_sessions')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .snapshots();
  }

  Stream<QuerySnapshot> listenToChatMessages(String sessionId) {
    return _db
        .collection('chat_history')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      final messages = await _db
          .collection('chat_history')
          .doc(sessionId)
          .collection('messages')
          .get();
      for (final doc in messages.docs) {
        await doc.reference.delete();
      }
      await _db
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      print('deleteChatSession Error: $e');
    }
  }

  // ─── VIDEO CALL ───────────────────────────────────────────
  Future<String> requestVideoCall(String appointmentId,
      String doctorId, String patientName) async {
    try {
      final roomName =
          'health_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('video_calls').doc(appointmentId).set({
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': currentUser?.uid ?? '',
        'patientName': patientName,
        'roomName': roomName,
        'status': 'waiting',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      return roomName;
    } catch (e) {
      print('requestVideoCall Error: $e');
      return '';
    }
  }

  Stream<DocumentSnapshot> listenToVideoCall(String appointmentId) {
    return _db
        .collection('video_calls')
        .doc(appointmentId)
        .snapshots();
  }

  Future<void> endVideoCall(String appointmentId) async {
    await _db.collection('video_calls').doc(appointmentId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp()
    });
  }

  // ─── PRESCRIPTIONS ────────────────────────────────────────
  Stream<QuerySnapshot> listenToPrescriptions(String userId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: userId)
        .snapshots();
  }

  // ─── HEALTH RECORDS ───────────────────────────────────────
  Stream<QuerySnapshot> listenToHealthRecords() {
    return _db
        .collection('health_records')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .snapshots();
  }

  Future<void> addHealthRecord(Map<String, dynamic> data) async {
    await _db.collection('health_records').add({
      ...data,
      'patientId': currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────
  Stream<QuerySnapshot> listenToNotifications() {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: currentUser?.uid ?? '')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // ─── DOCTOR REQUESTS ──────────────────────────────────────
  Stream<QuerySnapshot> listenToDoctorRequests() {
    return _db
        .collection('doctor_requests')
        .where('patientId', isEqualTo: currentUser?.uid ?? '')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptMedicineRequest(String requestId,
      List<Map<String, dynamic>> medicines, String pharmacy) async {
    try {
      await _db.collection('orders').add({
        'items': medicines,
        'pharmacy': pharmacy,
        'total': medicines.fold(
            0.0,
            (sum, m) =>
                sum + ((m['price'] ?? 120) as num).toDouble()),
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'status': 'confirmed',
        'fromDoctorRequest': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _db
          .collection('doctor_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('acceptMedicineRequest Error: $e');
    }
  }

  Future<void> acceptLabRequest(
      String requestId, List<String> tests, String lab) async {
    try {
      await _db.collection('lab_tests').add({
        'tests': tests,
        'lab': lab,
        'totalAmount': tests.length * 350,
        'patientId': currentUser?.uid ?? '',
        'patientName': currentUser?.displayName ?? 'Patient',
        'status': 'booked',
        'fromDoctorRequest': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _db
          .collection('doctor_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('acceptLabRequest Error: $e');
    }
  }

  Future<void> declineRequest(String requestId) async {
    await _db
        .collection('doctor_requests')
        .doc(requestId)
        .update({'status': 'declined'});
  }
}