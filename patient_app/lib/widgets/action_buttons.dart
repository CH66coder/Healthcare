import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtonsWidget extends StatelessWidget {
  final bool showAppointment;
  final bool showMedicine;
  final bool showLabTest;
  final String specialist;
  final VoidCallback onAppointmentTap;
  final VoidCallback onMedicineTap;
  final VoidCallback onLabTestTap;

  const ActionButtonsWidget({
    super.key,
    required this.showAppointment,
    required this.showMedicine,
    required this.showLabTest,
    required this.specialist,
    required this.onAppointmentTap,
    required this.onMedicineTap,
    required this.onLabTestTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '🩺 What would you like to do?',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B9EC7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showAppointment)
            _ActionBtn(
              icon: Icons.calendar_today_rounded,
              label: specialist.isNotEmpty
                  ? 'Book $specialist Appointment'
                  : 'Book Appointment',
              color: const Color(0xFF00C896),
              onTap: onAppointmentTap,
            ),
          if (showMedicine)
            _ActionBtn(
              icon: Icons.local_pharmacy_outlined,
              label: 'Order Medicines',
              color: const Color(0xFF6C63FF),
              onTap: onMedicineTap,
            ),
          if (showLabTest)
            _ActionBtn(
              icon: Icons.science_outlined,
              label: 'Book Lab Test',
              color: const Color(0xFFFFB347),
              onTap: onLabTestTap,
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
        ]),
      ),
    );
  }
}
