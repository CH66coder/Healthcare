import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class DoctorRequestsScreen extends StatelessWidget {
  const DoctorRequestsScreen({super.key});

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('Doctor Requests',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: svc.listenToDoctorRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('No pending requests',
                      style: GoogleFonts.poppins(
                          color: _text2, fontSize: 16)),
                  Text('Doctor requests will appear here',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF4A5568), fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final type = d['type'] ?? 'medicine';
              return type == 'medicine'
                  ? _MedicineRequestCard(
                      requestId: doc.id, data: d, svc: svc)
                  : _LabRequestCard(
                      requestId: doc.id, data: d, svc: svc);
            },
          );
        },
      ),
    );
  }
}

// ─── Medicine Request Card ─────────────────────────────────
class _MedicineRequestCard extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final FirebaseService svc;

  const _MedicineRequestCard({
    required this.requestId,
    required this.data,
    required this.svc,
  });

  @override
  State<_MedicineRequestCard> createState() =>
      _MedicineRequestCardState();
}

class _MedicineRequestCardState extends State<_MedicineRequestCard> {
  String _selectedPharmacy = 'Apollo Pharmacy';
  bool _loading = false;
  bool _confirmed = false;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);
  static const Color _green = Color(0xFF00C896);

  final _pharmacies = [
    'Apollo Pharmacy', 'MedPlus', 'Netmeds',
    '1mg', 'PharmEasy',
  ];

  @override
  Widget build(BuildContext context) {
    final meds = (widget.data['medicines'] as List?) ?? [];
    final doctorName = widget.data['doctorName'] ?? 'Doctor';

    if (_confirmed) {
      return _ConfirmedCard(
        icon: '💊',
        title: 'Medicines Ordered!',
        subtitle: 'Order placed at $_selectedPharmacy',
        color: _primary,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Text('💊', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medicine Request',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('From Dr. $doctorName',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Pending',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFFB347),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // Medicine list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prescribed Medicines (${meds.length})',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...meds.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.medication_outlined,
                            color: Color(0xFF6C63FF), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(m['name'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 13)),
                        ),
                        Text(
                            '${m['dosageForm'] ?? ''} • ${m['strength'] ?? ''}',
                            style: GoogleFonts.poppins(
                                color: _text2, fontSize: 11)),
                      ]),
                    )),
                const SizedBox(height: 14),

                // Pharmacy selector
                Text('Choose Pharmacy',
                    style: GoogleFonts.poppins(
                        color: _text2, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _pharmacies.map((p) {
                    final sel = _selectedPharmacy == p;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPharmacy = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? _primary.withOpacity(0.15)
                              : const Color(0xFF1E2535),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? _primary : _border),
                        ),
                        child: Text(p,
                            style: GoogleFonts.poppins(
                                color: sel ? _primary : _text2,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              await widget.svc.acceptMedicineRequest(
                                widget.requestId,
                                List<Map<String, dynamic>>.from(meds),
                                _selectedPharmacy,
                              );
                              setState(() {
                                _loading = false;
                                _confirmed = true;
                              });
                            },
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Place Order',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () =>
                        widget.svc.declineRequest(widget.requestId),
                    child: Text('Decline',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 13)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lab Request Card ──────────────────────────────────────
class _LabRequestCard extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final FirebaseService svc;

  const _LabRequestCard({
    required this.requestId,
    required this.data,
    required this.svc,
  });

  @override
  State<_LabRequestCard> createState() => _LabRequestCardState();
}

class _LabRequestCardState extends State<_LabRequestCard> {
  String _selectedLab = 'Apollo Diagnostics';
  bool _loading = false;
  bool _confirmed = false;

  static const Color _primary = Color(0xFFFFB347);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  final _labs = [
    'Apollo Diagnostics', 'Thyrocare',
    'Dr. Lal PathLabs', 'SRL Diagnostics',
    'Metropolis',
  ];

  @override
  Widget build(BuildContext context) {
    final tests = List<String>.from(widget.data['tests'] ?? []);
    final doctorName = widget.data['doctorName'] ?? 'Doctor';

    if (_confirmed) {
      return _ConfirmedCard(
        icon: '🧪',
        title: 'Lab Tests Booked!',
        subtitle: '${tests.length} tests at $_selectedLab',
        color: _primary,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Text('🧪', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lab Test Request',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('From Dr. $doctorName',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Pending',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFFB347),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Tests (${tests.length})',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...tests.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(children: [
                        const Icon(Icons.science_outlined,
                            color: Color(0xFFFFB347), size: 16),
                        const SizedBox(width: 8),
                        Text(t,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13)),
                      ]),
                    )),
                const SizedBox(height: 14),

                // Lab selector
                Text('Choose Lab',
                    style: GoogleFonts.poppins(
                        color: _text2, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _labs.map((lab) {
                    final sel = _selectedLab == lab;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLab = lab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? _primary.withOpacity(0.15)
                              : const Color(0xFF1E2535),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? _primary : _border),
                        ),
                        child: Text(lab,
                            style: GoogleFonts.poppins(
                                color: sel ? _primary : _text2,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              await widget.svc.acceptLabRequest(
                                widget.requestId,
                                tests,
                                _selectedLab,
                              );
                              setState(() {
                                _loading = false;
                                _confirmed = true;
                              });
                            },
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Book Tests',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () =>
                        widget.svc.declineRequest(widget.requestId),
                    child: Text('Decline',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 13)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirmed Card ────────────────────────────────────────
class _ConfirmedCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ConfirmedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: const Color(0xFF8B9EC7), fontSize: 12)),
          ],
        ),
        const Spacer(),
        Icon(Icons.check_circle_rounded, color: color, size: 28),
      ]),
    );
  }
}