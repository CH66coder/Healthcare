import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/doctor_firebase_service.dart';
import '../screens/video_call_screen_doctor.dart';

class DoctorAvailabilityWidget extends StatefulWidget {
  const DoctorAvailabilityWidget({super.key});

  @override
  State<DoctorAvailabilityWidget> createState() =>
      _DoctorAvailabilityWidgetState();
}

class _DoctorAvailabilityWidgetState
    extends State<DoctorAvailabilityWidget> {
  final _svc = DoctorFirebaseService();
  bool _isAvailable = false;
  bool _toggling = false;

  static const Color _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final val = await _svc.getAvailability();
    if (mounted) setState(() => _isAvailable = val);
  }

  Future<void> _toggle(bool val) async {
    setState(() {
      _isAvailable = val;
      _toggling = true;
    });
    await _svc.setAvailability(val);
    setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Availability toggle ──────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isAvailable
                  ? _primary.withOpacity(0.5)
                  : Colors.white12,
            ),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isAvailable ? Colors.greenAccent : Colors.grey,
                boxShadow: _isAvailable
                    ? [
                        BoxShadow(
                          color:
                              Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAvailable ? 'You are Online' : 'You are Offline',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _isAvailable
                        ? 'Patients can request video calls'
                        : 'Toggle to accept video consultations',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            _toggling
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6C63FF)),
                  )
                : Switch(
                    value: _isAvailable,
                    onChanged: _toggle,
                    activeColor: _primary,
                  ),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Incoming call banner ─────────────────────
        StreamBuilder<QuerySnapshot>(
          stream: _svc.listenForIncomingCalls(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            final callDoc = snap.data!.docs.first;
            final callData =
                callDoc.data() as Map<String, dynamic>;

            return _IncomingCallBanner(
              patientName: callData['patientName'] ?? 'Patient',
              appointmentId:
                  callData['appointmentId'] ?? callDoc.id,
              roomName: callData['roomName'] ?? '',
              patientId: callData['patientId'] ?? '',  // ← fixed
              svc: _svc,
            );
          },
        ),
      ],
    );
  }
}

class _IncomingCallBanner extends StatelessWidget {
  final String patientName;
  final String appointmentId;
  final String roomName;
  final String patientId;  // ← added
  final DoctorFirebaseService svc;

  const _IncomingCallBanner({
    required this.patientName,
    required this.appointmentId,
    required this.roomName,
    required this.patientId,  // ← added
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.greenAccent.withOpacity(0.4)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.video_call_rounded,
                color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incoming Video Call',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('Patient: $patientName',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          // Decline
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await svc.endVideoCall(appointmentId);
              },
              icon: const Icon(Icons.call_end_rounded,
                  color: Colors.redAccent, size: 18),
              label: Text('Decline',
                  style: GoogleFonts.poppins(
                      color: Colors.redAccent, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Accept
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await svc.acceptVideoCall(appointmentId);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorVideoCallScreen(
                        roomName: roomName,
                        patientName: patientName,
                        appointmentId: appointmentId,
                        patientId: patientId,  // ← fixed
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text('Accept',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}