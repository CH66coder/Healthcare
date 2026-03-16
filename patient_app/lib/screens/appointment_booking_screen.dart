import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'package:patient_app/screens/appointment_confirmed_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String specialist;
  final List<Map<String, dynamic>> doctors;
  final Map<String, dynamic>? preselectedDoctor;

  const AppointmentBookingScreen({
    super.key,
    required this.specialist,
    required this.doctors,
    this.preselectedDoctor,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _svc = FirebaseService();
  Map<String, dynamic>? _selectedDoctor;
  String _appointmentType = 'video'; // 'video' or 'in-person'
  String _selectedDate = '';
  String _selectedTime = '';
  bool _loading = false;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  final List<String> _times = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.preselectedDoctor ?? 
        (widget.doctors.isNotEmpty ? widget.doctors.first : null);
    // Default date - today
    final now = DateTime.now();
    _selectedDate =
        '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _confirmBooking() async {
  if (_selectedTime.isEmpty) {
    _snack("Please select a time slot");
    return;
  }

  if (_selectedDoctor == null) {
    _snack("Please select a doctor");
    return;
  }

  setState(() => _loading = true);

  final appointmentId =
    await _svc.bookAppointment({
      'doctorId':
        _selectedDoctor!['id'] ?? '',
      'doctorName':
        _selectedDoctor!['name'] ?? '',
      'specialty':
        widget.specialist,
      'date': _selectedDate,
      'time': _selectedTime,
      'type': _appointmentType,
      'fee': _selectedDoctor![
        'consultation_fee'
      ],
      'status': 'confirmed',
      'timestamp': DateTime.now()
        .toIso8601String(),
    });

  setState(() => _loading = false);

  if (appointmentId.isNotEmpty
      && mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
          AppointmentConfirmedScreen(
            doctor: _selectedDoctor!,
            selectedTime: _selectedTime,
            selectedDate: _selectedDate,
            appointmentType:
              _appointmentType,
            appointmentId: appointmentId,
          )
      ),
    );
  }
}


  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: _card));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
          backgroundColor: _bg, title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor selection
            if (widget.doctors.length > 1) ...[
              _sectionTitle('Select Doctor'),
              ...widget.doctors.map((d) => _DoctorOption(
                    doctor: d,
                    selected: _selectedDoctor?['id'] == d['id'],
                    onTap: () => setState(() => _selectedDoctor = d),
                  )),
              const SizedBox(height: 20),
            ] else if (_selectedDoctor != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (_selectedDoctor!['name'] as String? ?? 'D')[0]
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                            color: _primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedDoctor!['name'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Text(widget.specialist,
                            style: GoogleFonts.poppins(
                                color: _primary, fontSize: 12)),
                        Text(
                            '⭐ ${_selectedDoctor!['rating']} • ${_selectedDoctor!['experience_years']} yrs • 📍${_selectedDoctor!['bangalore_location'] ?? ''}',
                            style: GoogleFonts.poppins(
                                color: _text2, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('₹${_selectedDoctor!['consultation_fee']}',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFFFB347),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Appointment type
            _sectionTitle('Appointment Type'),
            Row(children: [
              Expanded(
                child: _TypeCard(
                  icon: Icons.video_call_rounded,
                  label: 'Video Call',
                  selected: _appointmentType == 'video',
                  onTap: () =>
                      setState(() => _appointmentType = 'video'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  icon: Icons.local_hospital_outlined,
                  label: 'In-Person',
                  selected: _appointmentType == 'in-person',
                  onTap: () =>
                      setState(() => _appointmentType = 'in-person'),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Time slots
            _sectionTitle('Select Time'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: _times.length,
              itemBuilder: (context, i) {
                final t = _times[i];
                final sel = _selectedTime == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = t),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel
                          ? _primary.withOpacity(0.15)
                          : _card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? _primary : _border),
                    ),
                    alignment: Alignment.center,
                    child: Text(t,
                        style: GoogleFonts.poppins(
                            color: sel ? _primary : _text2,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmBooking,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Confirm Booking${_selectedDoctor != null ? ' — ₹${_selectedDoctor!['consultation_fee']}' : ''}'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      );
}

class _DoctorOption extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final bool selected;
  final VoidCallback onTap;
  const _DoctorOption(
      {required this.doctor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? const Color(0xFF00C896)
                  : const Color(0xFF1E2A42)),
        ),
        child: Row(children: [
          if (selected)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00C896), size: 20),
          if (!selected)
            const Icon(Icons.radio_button_unchecked_rounded,
                color: Color(0xFF4A5568), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(doctor['name'] ?? '',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13))),
          Text('⭐ ${doctor['rating']}',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8B9EC7), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C896).withOpacity(0.1)
              : const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? const Color(0xFF00C896)
                  : const Color(0xFF1E2A42)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF00C896)
                    : const Color(0xFF8B9EC7),
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: selected
                        ? const Color(0xFF00C896)
                        : const Color(0xFF8B9EC7),
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
