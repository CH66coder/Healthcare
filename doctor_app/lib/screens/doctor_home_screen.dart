import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/doctor_firebase_service.dart';
import 'prescription_screen.dart';
import 'video_call_screen_doctor.dart';
import '../widgets/doctor_availability_widget.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _svc = DoctorFirebaseService();
  bool _callDialogShowing = false;

  static const Color _primary = Color(0xFF2196F3);
  static const Color _bg = Color(0xFF0A0F1E);
  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    _svc.listenForIncomingCalls().listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_callDialogShowing) {
        final callDoc = snapshot.docs.first;
        final data = callDoc.data() as Map<String, dynamic>;
        _showIncomingCallDialog(callDoc.id, data);
      }
    });
  }

  void _showIncomingCallDialog(
      String appointmentId, Map<String, dynamic> data) {
    _callDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_call_rounded,
                  color: Color(0xFF6C63FF), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Incoming Video Call',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Patient: ${data['patientName'] ?? 'Patient'}',
                style:
                    GoogleFonts.poppins(color: _text2, fontSize: 14)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF4757).withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    _callDialogShowing = false;
                    await _svc.endVideoCall(appointmentId);
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: Text('Decline',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFFF4757),
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    _callDialogShowing = false;
                    Navigator.of(context).pop();
                    await _svc.acceptVideoCall(appointmentId);
                    final roomName =
                        await _svc.getRoomName(appointmentId);
                    if (roomName.isNotEmpty && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorVideoCallScreen(
                            roomName: roomName,
                            patientName:
                                data['patientName'] ?? 'Patient',
                            appointmentId: appointmentId,
                            patientId: data['patientId'] ?? '',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Accept',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ).then((_) => _callDialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = _svc.currentUser?.displayName ?? 'Doctor';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services,
                color: _primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. $name',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text('Doctor Portal',
                  style:
                      GoogleFonts.poppins(color: _text2, fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Color(0xFF8B9EC7)),
            onPressed: () => _svc.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _svc.listenToMyAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: _primary));
          }

          final docs = (snapshot.data?.docs ?? []).toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'];
              final bt = (b.data() as Map)['createdAt'];
              if (at == null) return 1;
              if (bt == null) return -1;
              return (bt as Timestamp).compareTo(at as Timestamp);
            });

          final pending = docs
              .where((d) =>
                  (d.data() as Map)['status'] == 'pending')
              .length;
          final completed = docs
              .where((d) =>
                  (d.data() as Map)['status'] == 'completed')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DoctorAvailabilityWidget(),
                const SizedBox(height: 20),

                // ── Stat Cards ───────────────────────────
                Row(children: [
                  _StatCard('Total', '${docs.length}', _text2),
                  const SizedBox(width: 12),
                  _StatCard('Pending', '$pending',
                      const Color(0xFFFFB347)),
                  const SizedBox(width: 12),
                  _StatCard('Done', '$completed', _primary),
                ]),
                const SizedBox(height: 28),

                Text("Today's Appointments",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),

                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Center(
                      child: Text('No appointments yet',
                          style: GoogleFonts.poppins(
                              color: _text2, fontSize: 14)),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;
                    return _AppointmentCard(
                        data: d, docId: doc.id, svc: _svc);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────
Widget _StatCard(String label, String value, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3050)),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.poppins(
                color: const Color(0xFF8B9EC7), fontSize: 12)),
      ]),
    ),
  );
}

// ─── Appointment Card ──────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final DoctorFirebaseService svc;

  const _AppointmentCard(
      {required this.data, required this.docId, required this.svc});

  static const Color _primary = Color(0xFF2196F3);
  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);

  Color _statusColor(String s) {
    if (s == 'confirmed') return const Color(0xFF00C896);
    if (s == 'completed') return const Color(0xFF8B9EC7);
    if (s == 'cancelled') return const Color(0xFFFF4757);
    return const Color(0xFFFFB347);
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        // ── Patient info row ───────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline,
                  color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['patientName'] ?? 'Patient',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text(data['specialty'] ?? '',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF8B9EC7),
                          fontSize: 12)),
                  if (data['date'] != null)
                    Text('📅 ${data['date']}  🕐 ${data['time'] ?? ''}',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF8B9EC7),
                            fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: GoogleFonts.poppins(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        // ── Action buttons ─────────────────────────────
        Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  child: Column(
    children: [
      Row(children: [
        // Confirm button (pending only)
        if (status == 'pending') ...[
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => svc.confirmAppointment(docId),
              child: Text('Confirm',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Video Call button (confirmed only)
        if (status == 'confirmed') ...[
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.video_call_rounded,
                  color: Colors.white, size: 18),
              label: Text('Video Call',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              onPressed: () async {
                final db = FirebaseFirestore.instance;
                final callRef =
                    db.collection('video_calls').doc(docId);
                final existing = await callRef.get();
                String roomName;
                if (!existing.exists) {
                  roomName =
                      'health_${docId}_${DateTime.now().millisecondsSinceEpoch}';
                  await callRef.set({
                    'appointmentId': docId,
                    'doctorId': svc.doctorId,
                    'patientId': data['patientId'] ?? '',
                    'patientName': data['patientName'] ?? 'Patient',
                    'roomName': roomName,
                    'status': 'accepted',
                    'requestedAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  roomName = existing.data()?['roomName'] ?? '';
                }
                if (context.mounted && roomName.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorVideoCallScreen(
                        roomName: roomName,
                        patientName: data['patientName'] ?? 'Patient',
                        appointmentId: docId,
                        patientId: data['patientId'] ?? '',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Prescribe button (always shown unless completed)
        if (status != 'completed')
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E3050)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrescriptionScreen(
                    appointmentId: docId,
                    patientId: data['patientId'] ?? '',
                    patientName: data['patientName'] ?? 'Patient',
                  ),
                ),
              ),
              child: Text('Prescribe',
                  style: GoogleFonts.poppins(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),

      // ── Mark as Done button (confirmed only) ──────────
      if (status == 'confirmed') ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896).withOpacity(0.15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF00C896), size: 18),
            label: Text('Mark as Done',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF00C896),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF131929),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Mark as Done?',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  content: Text(
                      'This will mark the appointment with ${data['patientName'] ?? 'patient'} as completed.',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF8B9EC7),
                          fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF8B9EC7))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C896),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: Text('Mark Done',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await svc.completeAppointment(docId);
              }
            },
          ),
        ),
      ],

      // ── Completed status info ─────────────────────────
      if (status == 'completed')
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B9EC7).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF8B9EC7).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF8B9EC7), size: 16),
              const SizedBox(width: 6),
              Text('Appointment Completed',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF8B9EC7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
    ],
  ),
),
      ]),
    );
  }
}