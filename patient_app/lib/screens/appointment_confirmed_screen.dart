import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'video_call_screen.dart';

class AppointmentConfirmedScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String selectedTime;
  final String selectedDate;
  final String appointmentType;
  final String appointmentId;

  const AppointmentConfirmedScreen({
    super.key,
    required this.doctor,
    required this.selectedTime,
    required this.selectedDate,
    required this.appointmentType,
    required this.appointmentId,
  });

  @override
  State<AppointmentConfirmedScreen> createState() =>
      _AppointmentConfirmedScreenState();
}

class _AppointmentConfirmedScreenState
    extends State<AppointmentConfirmedScreen> {
  final _svc = FirebaseService();
  bool _isRequesting = false;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _text2 = Color(0xFF8B9EC7);

  Future<void> _requestCall(String doctorId) async {
    setState(() => _isRequesting = true);
    final patientName = _svc.currentUser?.displayName ?? 'Patient';

    final roomName = await _svc.requestVideoCall(
      widget.appointmentId,
      doctorId,
      patientName,
    );

    setState(() => _isRequesting = false);

    if (roomName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request call. Try again.')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _WaitingForDoctorScreen(
            appointmentId: widget.appointmentId,
            roomName: roomName,
            svc: _svc,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = widget.doctor['id'] ?? '';
    final isVideo = widget.appointmentType == 'video';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (r) => r.isFirst),
            child:
                Text('Home', style: GoogleFonts.poppins(color: _text2)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _primary, size: 60),
              ),
              const SizedBox(height: 20),
              Text('Appointment Confirmed!',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Your appointment has been booked successfully',
                  style: GoogleFonts.poppins(color: _text2, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E2A42)),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (widget.doctor['name'] as String? ?? 'D')[0]
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                                color: _primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.doctor['name'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          Text(widget.doctor['specialty'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: _primary, fontSize: 12)),
                        ],
                      ),
                    ]),
                    const Divider(color: Color(0xFF1E2A42), height: 24),
                    _row('📅', 'Date', widget.selectedDate),
                    _row('🕐', 'Time', widget.selectedTime),
                    _row('📞', 'Type',
                        isVideo ? 'Video Call' : 'In-Person'),
                    _row('💰', 'Fee',
                        '₹${widget.doctor['consultation_fee']}'),
                    _row('🎫', 'Booking ID',
                        widget.appointmentId.substring(0, 8).toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Video call section (video appointments only) ──
              if (isVideo && doctorId.isNotEmpty) ...[
                StreamBuilder<DocumentSnapshot>(
                  stream: _svc.listenToDoctorAvailability(doctorId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final data =
                        snap.data!.data() as Map<String, dynamic>?;
                    final isAvailable = data?['isAvailable'] == true;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isAvailable ? _primary : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable
                                  ? 'Doctor is available now'
                                  : 'Doctor is currently unavailable',
                              style: GoogleFonts.poppins(
                                  color: isAvailable ? _primary : _text2,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isAvailable && !_isRequesting
                                ? () => _requestCall(doctorId)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              disabledBackgroundColor:
                                  _primary.withOpacity(0.3),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isRequesting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.video_call_rounded),
                            label: Text(
                              _isRequesting
                                  ? 'Requesting...'
                                  : isAvailable
                                      ? 'Start Video Call'
                                      : 'Doctor Unavailable',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text2,
                    side: const BorderSide(color: Color(0xFF1E2A42)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Home',
                      style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String emoji, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(color: _text2, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// ─── Waiting screen — shown after patient taps "Start Video Call" ─────────
class _WaitingForDoctorScreen extends StatelessWidget {
  final String appointmentId;
  final String roomName;
  final FirebaseService svc;

  const _WaitingForDoctorScreen({
    required this.appointmentId,
    required this.roomName,
    required this.svc,
  });

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: StreamBuilder<DocumentSnapshot>(
          stream: svc.listenToVideoCall(appointmentId),
          builder: (context, snap) {
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'waiting';

              // Doctor accepted → auto-launch Jitsi
              if (status == 'accepted') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoCallScreen(
                        roomName: roomName,
                        displayName:
                            svc.currentUser?.displayName ?? 'Patient',
                        appointmentId: appointmentId,
                        isDoctor: false,
                      ),
                    ),
                  );
                });
              }

              // Doctor rejected or ended
              if (status == 'ended') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Doctor is not available right now.')),
                    );
                  }
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: _primary),
                    const SizedBox(height: 32),
                    const Text(
                      'Waiting for doctor to accept...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The doctor will join shortly.\nPlease keep this screen open.',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    OutlinedButton(
                      onPressed: () async {
                        await svc.endVideoCall(appointmentId);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side:
                            const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}