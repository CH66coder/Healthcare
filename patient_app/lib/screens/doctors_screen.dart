import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'appointment_booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _svc = FirebaseService();
  final _searchCtrl = TextEditingController();
  String _selectedSpecialty = 'all';
  List<Map<String, dynamic>> _doctors = [];
  List<String> _specialties = [];
  bool _loading = true;
  bool _isSearching = false;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  static const Map<String, String> _specialtyIcons = {
    'general-physician': '🩺',
    'cardiologist': '❤️',
    'dermatologist': '🧴',
    'neurologist': '🧠',
    'orthopedist': '🦴',
    'pediatrician': '👶',
    'gynecologist': '🌸',
    'psychiatrist': '🧘',
    'ophthalmologist': '👁️',
    'dentist': '🦷',
    'gastroenterologist': '🫁',
    'endocrinologist': '⚗️',
    'oncologist': '🔬',
    'nephrologist': '💧',
    'anesthesiologist': '💉',
    'pathologist': '🧪',
    'ayurveda': '🌿',
    'cardiac-surgeon': '🫀',
    'neurosurgeon': '🔬',
    'plastic-surgeon': '✨',
    'general': '🩺',
  };

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    final s = await _svc.getSpecialties();
    setState(() => _specialties = s);
  }

  Future<void> _loadDoctors() async {
    setState(() => _loading = true);
    final docs = await _svc.getAllDoctors(
        specialty: _selectedSpecialty == 'all' ? null : _selectedSpecialty);
    setState(() {
      _doctors = docs;
      _loading = false;
    });
  }

  /// Search doctors by name across BOTH 'doctors' and 'doctor_users' collections
  Future<void> _searchDoctors(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      _loadDoctors();
      return;
    }

    setState(() {
      _loading = true;
      _isSearching = true;
    });

    final db = FirebaseFirestore.instance;
    final queryLower = query.toLowerCase();

    // Search 'doctors' collection (CSV-imported + app-registered doctors)
    final snap1 = await db.collection('doctors').get();
    final from1 = snap1.docs
        .map((d) => {...(d.data()), 'id': d.id})
        .where((d) =>
            (d['name'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (d['specialty'] ?? '').toString().toLowerCase().contains(queryLower))
        .toList();

    // Search 'doctor_users' collection (doctor app registrations)
    final snap2 = await db.collection('doctor_users').get();
    final from2 = snap2.docs
        .map((d) => {...(d.data()), 'id': d.id})
        .where((d) =>
            (d['name'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (d['specialty'] ?? '').toString().toLowerCase().contains(queryLower))
        .toList();

    // Merge — avoid duplicates by uid
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final doc in [...from1, ...from2]) {
      final uid = doc['uid']?.toString() ?? doc['id'];
      if (seen.add(uid)) {
        merged.add(doc);
      }
    }

    setState(() {
      _doctors = merged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
          backgroundColor: _bg, title: const Text('Find a Doctor')),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '🔍 Search doctor by name or specialty...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF8B9EC7)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8B9EC7)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _isSearching = false);
                          _loadDoctors();
                        })
                    : null,
              ),
              onChanged: (val) {
                setState(() {}); // update suffix icon
                if (val.isEmpty) {
                  setState(() => _isSearching = false);
                  _loadDoctors();
                }
              },
              onSubmitted: _searchDoctors,
            ),
          ),

          // ── Specialty filter chips (hidden while searching) ──
          if (!_isSearching)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _SpecialtyChip(
                    label: 'All',
                    icon: '🏥',
                    selected: _selectedSpecialty == 'all',
                    onTap: () {
                      setState(() => _selectedSpecialty = 'all');
                      _loadDoctors();
                    },
                  ),
                  ..._specialties.map((s) => _SpecialtyChip(
                        label: s
                            .split('-')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                        icon: _specialtyIcons[s] ?? '👨‍⚕️',
                        selected: _selectedSpecialty == s,
                        onTap: () {
                          setState(() => _selectedSpecialty = s);
                          _loadDoctors();
                        },
                      )),
                ],
              ),
            ),

          // ── Search hint ─────────────────────────────────────
          if (_isSearching && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(children: [
                Text(
                  'Results for "${_searchCtrl.text}" — ${_doctors.length} found',
                  style: GoogleFonts.poppins(color: _text2, fontSize: 12),
                ),
              ]),
            ),

          // ── Doctors list ────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _doctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👨‍⚕️',
                                style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _isSearching
                                  ? 'No doctors found for "${_searchCtrl.text}"'
                                  : 'No doctors found',
                              style: GoogleFonts.poppins(
                                  color: _text2, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, i) {
                          return _DoctorCard(
                              doctor: _doctors[i], svc: _svc);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _SpecialtyChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00C896) : const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF00C896)
                  : const Color(0xFF1E2A42)),
        ),
        child: Text('$icon $label',
            style: GoogleFonts.poppins(
                color: selected ? Colors.white : const Color(0xFF8B9EC7),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final FirebaseService svc;

  const _DoctorCard({required this.doctor, required this.svc});

  static const Color _primary = Color(0xFF00C896);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    final specialty = doctor['specialty'] ?? '';
    final rating = doctor['rating']?.toString() ?? '4.0';
    final exp = doctor['experience_years']?.toString() ?? '';
    final fee = doctor['consultation_fee']?.toString() ?? '';
    final location = doctor['bangalore_location'] ?? '';
    final name = doctor['name'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '👨‍⚕️',
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
                Text(name,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(specialty,
                    style:
                        GoogleFonts.poppins(color: _primary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('⭐ $rating',
                      style:
                          GoogleFonts.poppins(color: _text2, fontSize: 11)),
                  if (exp.isNotEmpty) ...[
                    Text(' • ',
                        style:
                            GoogleFonts.poppins(color: _text2, fontSize: 11)),
                    Text('$exp yrs',
                        style:
                            GoogleFonts.poppins(color: _text2, fontSize: 11)),
                  ],
                  if (location.isNotEmpty) ...[
                    Text(' • ',
                        style:
                            GoogleFonts.poppins(color: _text2, fontSize: 11)),
                    Flexible(
                      child: Text('📍$location',
                          style:
                              GoogleFonts.poppins(color: _text2, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
                if (fee.isNotEmpty)
                  Text('₹$fee consultation',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFFFB347), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppointmentBookingScreen(
                  specialist: specialty,
                  doctors: [doctor],
                  preselectedDoctor: doctor,
                ),
              ),
            ),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}