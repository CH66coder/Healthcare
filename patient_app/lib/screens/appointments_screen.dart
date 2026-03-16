import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'video_call_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

// ← Changed to StatefulWidget so _svc and stream are created ONCE
class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // ← _svc created once here, not inside build()
  final _svc = FirebaseService();
  late final Stream<QuerySnapshot> _stream;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  void initState() {
    super.initState();
    // ← Stream created once in initState, not on every build
    _stream = _svc.listenToMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: _bg,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          // Show loading only on first load, not on every rebuild
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF4A5568), size: 60),
                  const SizedBox(height: 16),
                  Text('No appointments yet',
                      style: GoogleFonts.poppins(
                          color: _text2, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Book a doctor from the Doctors tab',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF4A5568), fontSize: 13)),
                ],
              ),
            );
          }

          final sortedDocs = snapshot.data!.docs.toList()
  ..sort((a, b) {
    final aTime = (a.data() as Map)['createdAt'];
    final bTime = (b.data() as Map)['createdAt'];
    if (aTime == null || bTime == null) return 0;
    return (bTime as dynamic).compareTo(aTime);
  });
return ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: sortedDocs.length,
  itemBuilder: (context, i) {
    final doc = sortedDocs[i];
              final d = doc.data() as Map<String, dynamic>;
              return _AppointmentTile(
                  data: d, docId: doc.id, svc: _svc);
            },
          );
        },
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final FirebaseService svc;

  const _AppointmentTile(
      {required this.data, required this.docId, required this.svc});

  static const Color _primary = Color(0xFF00C896);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF00C896);
      case 'completed':
        return const Color(0xFF8B9EC7);
      case 'cancelled':
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFFFFB347);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final isVideo = data['appointmentType'] == 'video';
    final isConfirmed = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: _primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['doctorName'] ?? 'Doctor',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      Text(data['specialty'] ?? '',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF8B9EC7),
                              fontSize: 12)),
                      if (data['date'] != null)
                        Text(
                            '📅 ${data['date']}  🕐 ${data['time'] ?? ''}',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF8B9EC7),
                                fontSize: 11)),
                      if (data['bangalore_location'] != null ||
                          data['location'] != null)
                        Text(
                            '📍 ${data['bangalore_location'] ?? data['location'] ?? ''}',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF8B9EC7),
                                fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: GoogleFonts.poppins(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (isVideo) ...[
                      const SizedBox(height: 4),
                      Text('📹 Video',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF6C63FF),
                              fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Video call button — only for confirmed video appointments
          if (isConfirmed && isVideo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.video_call_rounded,
                    color: Colors.white, size: 20),
                label: Text('Start Video Call',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                onPressed: () async {
                  final patientName =
                      svc.currentUser?.displayName ?? 'Patient';
                  final roomName = await svc.requestVideoCall(
                    docId,
                    data['doctorId'] ?? '',
                    patientName,
                  );
                  if (roomName.isNotEmpty && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoCallScreen(
                          roomName: roomName,
                          displayName: patientName,
                          appointmentId: docId,
                          isDoctor: false,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

          // Fee info
          if (data['fee'] != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text('Consultation Fee: ',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF8B9EC7), fontSize: 12)),
                  Text('₹${data['fee']}',
                      style: GoogleFonts.poppins(
                          color: _primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}