import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/doctor_firebase_service.dart';
import 'package:flutter/services.dart';

class DoctorVideoCallScreen extends StatefulWidget {
  final String roomName;
  final String patientName;
  final String appointmentId;
  final String patientId;

  const DoctorVideoCallScreen({
    super.key,
    required this.roomName,
    required this.patientName,
    required this.appointmentId,
    required this.patientId,
  });

  @override
  State<DoctorVideoCallScreen> createState() =>
      _DoctorVideoCallScreenState();
}

class _DoctorVideoCallScreenState extends State<DoctorVideoCallScreen> {
  final _svc = DoctorFirebaseService();

  static const Color _bg = Color(0xFF0A0F1E);
  static const Color _primary = Color(0xFF2196F3);
  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  void initState() {
    super.initState();
    _openJitsi();
  }

  Future<void> _openJitsi() async {
  final url = Uri.parse('https://meet.jit.si/${widget.roomName}');
  try {
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      // Fallback: try platform default
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    // Last resort fallback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video call: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Copy Link',
            onPressed: () async {
              // Copy room URL to clipboard
              await Clipboard.setData(
                ClipboardData(
                  text: 'https://meet.jit.si/${widget.roomName}'
                )
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!')),
              );
            },
          ),
        ),
      );
    }
  }
}

  void _showPostCallOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Post-Call Actions',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text('for ${widget.patientName}',
                style:
                    GoogleFonts.poppins(color: _text2, fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _ActionButton(
                  icon: '💊',
                  label: 'Request\nMedicines',
                  color: const Color(0xFF6C63FF),
                  onTap: () {
                    Navigator.pop(context);
                    _showMedicineRequestSheet();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: '🧪',
                  label: 'Request\nLab Tests',
                  color: const Color(0xFFFFB347),
                  onTap: () {
                    Navigator.pop(context);
                    _showLabRequestSheet();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Done — No Further Action',
                    style: GoogleFonts.poppins(
                        color: _text2, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineRequestSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // ← key fix
      isScrollControlled: true,
      builder: (_) => _MedicineRequestSheet(
        patientId: widget.patientId,
        patientName: widget.patientName,
        appointmentId: widget.appointmentId,
        svc: _svc,
        onSent: () {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💊 Medicine request sent to patient!'),
              backgroundColor: Color(0xFF6C63FF),
            ),
          );
        },
      ),
    );
  }

  void _showLabRequestSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // ← key fix
      isScrollControlled: true,
      builder: (_) => _LabRequestSheet(
        patientId: widget.patientId,
        patientName: widget.patientName,
        appointmentId: widget.appointmentId,
        svc: _svc,
        onSent: () {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🧪 Lab test request sent to patient!'),
              backgroundColor: Color(0xFFFFB347),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('Call with ${widget.patientName}',
            style:
                GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('📹', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 24),
            Text('Patient: ${widget.patientName}',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Room: ${widget.roomName}',
                style:
                    GoogleFonts.poppins(color: _text2, fontSize: 11)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _openJitsi,
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: Text('Join Video Call',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showPostCallOptions,
              icon: const Icon(Icons.post_add_rounded,
                  color: Colors.white),
              label: Text('Post-Call Actions',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('End Call',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFFF4757), fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Medicine Request Sheet ────────────────────────────────
class _MedicineRequestSheet extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String appointmentId;
  final DoctorFirebaseService svc;
  final VoidCallback onSent;

  const _MedicineRequestSheet({
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.svc,
    required this.onSent,
  });

  @override
  State<_MedicineRequestSheet> createState() =>
      _MedicineRequestSheetState();
}

class _MedicineRequestSheetState
    extends State<_MedicineRequestSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedMeds = [];
  bool _searching = false;
  bool _sending = false;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _card = Color(0xFF1A2340);
  static const Color _border = Color(0xFF1E3050);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final r = await widget.svc.searchMedicines(q.trim());
    setState(() {
      _searchResults = r;
      _searching = false;
    });
  }

  void _addMedicine(Map<String, dynamic> med) {
    if (_selectedMeds.any((m) => m['id'] == med['id'])) {
      setState(() => _searchResults = []);
      _searchCtrl.clear();
      return;
    }
    setState(() {
      _selectedMeds.add({
        'id': med['id'] ?? '',
        'name': med['Name'] ?? med['name'] ?? '',
        'category': med['Category'] ?? med['category'] ?? '',
        'dosageForm':
            med['Dosage Form'] ?? med['dosageForm'] ?? '',
        'strength': med['Strength'] ?? med['strength'] ?? '',
        'price': med['price'] ?? med['Price'] ?? 120,
        'qty': 1,
      });
      _searchResults = [];
      _searchCtrl.clear();
    });
  }

  void _updateQty(String id, int delta) {
    setState(() {
      final idx =
          _selectedMeds.indexWhere((m) => m['id'] == id);
      if (idx < 0) return;
      final newQty = (_selectedMeds[idx]['qty'] as int) + delta;
      if (newQty <= 0) {
        _selectedMeds.removeAt(idx);
      } else {
        _selectedMeds[idx] = {
          ..._selectedMeds[idx],
          'qty': newQty
        };
      }
    });
  }

  Future<void> _send() async {
    if (_selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Add at least one medicine')));
      return;
    }
    setState(() => _sending = true);
    final id = await widget.svc.sendMedicineRequest(
      patientId: widget.patientId,
      patientName: widget.patientName,
      appointmentId: widget.appointmentId,
      medicines: _selectedMeds,
    );
    setState(() => _sending = false);
    if (id.isNotEmpty) widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131929),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(children: [
                const Text('💊',
                    style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Request Medicines',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    Text('for ${widget.patientName}',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 12)),
                  ],
                ),
              ]),
            ),
            const Divider(
                color: Color(0xFF1E3050), height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search medicine by name...',
                      hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF4A5568),
                          fontSize: 13),
                      prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8B9EC7)),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primary)))
                          : (_searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                      Icons.close_rounded,
                                      color:
                                          Color(0xFF8B9EC7)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() =>
                                        _searchResults = []);
                                  })
                              : null),
                      filled: true,
                      fillColor: _card,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E3050)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E3050)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _primary, width: 1.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                    ),
                    onChanged: _search,
                  ),

                  // Search results
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: _searchResults
                            .take(6)
                            .map((med) {
                          final name = med['Name'] ??
                              med['name'] ??
                              '';
                          final already = _selectedMeds.any(
                              (m) => m['id'] == med['id']);
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding:
                                  const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text('💊',
                                  style: TextStyle(
                                      fontSize: 16)),
                            ),
                            title: Text(name,
                                style: GoogleFonts.poppins(
                                    color: already
                                        ? _text2
                                        : Colors.white,
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w500)),
                            subtitle: Text(
                                '${med['Category'] ?? ''} • ${med['Strength'] ?? ''} • ${med['Dosage Form'] ?? ''}',
                                style: GoogleFonts.poppins(
                                    color: _text2,
                                    fontSize: 11)),
                            trailing: already
                                ? const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: Color(0xFF00C896),
                                    size: 20)
                                : const Icon(
                                    Icons
                                        .add_circle_outline_rounded,
                                    color: _primary,
                                    size: 22),
                            onTap: already
                                ? null
                                : () => _addMedicine(med),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Selected medicines
                  if (_selectedMeds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Text(
                          'Added Medicines (${_selectedMeds.length})',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                          '${_selectedMeds.fold(0, (s, m) => s + (m['qty'] as int))} items total',
                          style: GoogleFonts.poppins(
                              color: _text2, fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),
                    ..._selectedMeds.map((m) => Container(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _primary.withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: _primary
                                    .withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            const Text('💊',
                                style:
                                    TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(m['name'] ?? '',
                                      style:
                                          GoogleFonts.poppins(
                                              color:
                                                  Colors.white,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight
                                                      .w600)),
                                  Text(
                                      '${m['dosageForm']} • ${m['strength']}',
                                      style:
                                          GoogleFonts.poppins(
                                              color: _text2,
                                              fontSize: 11)),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(children: [
                              GestureDetector(
                                onTap: () =>
                                    _updateQty(m['id'], -1),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFF1E3050),
                                    borderRadius:
                                        BorderRadius.circular(
                                            6),
                                  ),
                                  child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 14),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10),
                                child: Text('${m['qty']}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _updateQty(m['id'], 1),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _primary
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(
                                            6),
                                  ),
                                  child: Icon(Icons.add,
                                      color: _primary,
                                      size: 14),
                                ),
                              ),
                            ]),
                          ]),
                        )),
                  ],

                  if (_selectedMeds.isEmpty &&
                      _searchResults.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(children: [
                        const Text('💊',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Search and add medicines above',
                            style: GoogleFonts.poppins(
                                color: _text2, fontSize: 14)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Send button pinned at bottom
            Container(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF131929),
                border: Border(
                    top: BorderSide(
                        color: Color(0xFF1E3050))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMeds.isEmpty
                        ? const Color(0xFF1E3050)
                        : _primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                  onPressed: (_sending ||
                          _selectedMeds.isEmpty)
                      ? null
                      : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : Text(
                          _selectedMeds.isEmpty
                              ? 'Add medicines to send request'
                              : 'Send ${_selectedMeds.length} Medicine${_selectedMeds.length > 1 ? 's' : ''} to Patient',
                          style: GoogleFonts.poppins(
                              color: _selectedMeds.isEmpty
                                  ? _text2
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lab Request Sheet ─────────────────────────────────────
class _LabRequestSheet extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String appointmentId;
  final DoctorFirebaseService svc;
  final VoidCallback onSent;

  const _LabRequestSheet({
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.svc,
    required this.onSent,
  });

  @override
  State<_LabRequestSheet> createState() =>
      _LabRequestSheetState();
}

class _LabRequestSheetState extends State<_LabRequestSheet> {
  final List<String> _selected = [];
  bool _sending = false;

  static const Color _primary = Color(0xFFFFB347);
  static const Color _border = Color(0xFF1E3050);
  static const Color _text2 = Color(0xFF8B9EC7);

  final _allTests = [
    {'name': 'Complete Blood Count (CBC)', 'price': 350, 'icon': '🩸'},
    {'name': 'Blood Glucose (Fasting)', 'price': 80, 'icon': '🍬'},
    {'name': 'Lipid Profile', 'price': 450, 'icon': '💉'},
    {'name': 'Liver Function Test (LFT)', 'price': 600, 'icon': '🫀'},
    {'name': 'Kidney Function Test (KFT)', 'price': 500, 'icon': '💧'},
    {'name': 'Thyroid (TSH)', 'price': 350, 'icon': '⚗️'},
    {'name': 'Urine Routine', 'price': 120, 'icon': '🧪'},
    {'name': 'Stool Routine', 'price': 100, 'icon': '🔬'},
    {'name': 'Chest X-Ray', 'price': 400, 'icon': '🦴'},
    {'name': 'ECG', 'price': 300, 'icon': '❤️'},
    {'name': 'HbA1c', 'price': 400, 'icon': '🩺'},
    {'name': 'Vitamin D', 'price': 800, 'icon': '☀️'},
    {'name': 'Vitamin B12', 'price': 700, 'icon': '💊'},
    {'name': 'COVID-19 RT-PCR', 'price': 500, 'icon': '🦠'},
    {'name': 'Dengue NS1 Antigen', 'price': 600, 'icon': '🦟'},
  ];

  int get _totalCost => _selected.fold(0, (sum, name) {
        final t = _allTests.firstWhere((t) => t['name'] == name,
            orElse: () => {'price': 0});
        return sum + (t['price'] as int);
      });

  Future<void> _send() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Select at least one test')));
      return;
    }
    setState(() => _sending = true);
    final id = await widget.svc.sendLabRequest(
      patientId: widget.patientId,
      patientName: widget.patientName,
      appointmentId: widget.appointmentId,
      tests: _selected,
    );
    setState(() => _sending = false);
    if (id.isNotEmpty) widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131929),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(children: [
                const Text('🧪',
                    style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Request Lab Tests',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    Text('for ${widget.patientName}',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_selected.length} selected',
                        style: GoogleFonts.poppins(
                            color: _primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
            const Divider(
                color: Color(0xFF1E3050), height: 1),

            // Test list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: _allTests.length,
                itemBuilder: (_, i) {
                  final test = _allTests[i];
                  final name = test['name'] as String;
                  final sel = _selected.contains(name);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _selected.remove(name);
                      } else {
                        _selected.add(name);
                      }
                    }),
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? _primary.withOpacity(0.1)
                            : const Color(0xFF1A2340),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? _primary : _border),
                      ),
                      child: Row(children: [
                        Text(test['icon'] as String,
                            style: const TextStyle(
                                fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(name,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                        ),
                        Text('₹${test['price']}',
                            style: GoogleFonts.poppins(
                                color: _text2,
                                fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(
                          sel
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: sel
                              ? _primary
                              : const Color(0xFF4A5568),
                          size: 22,
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // Send button pinned at bottom
            Container(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF131929),
                border: Border(
                    top: BorderSide(
                        color: Color(0xFF1E3050))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selected.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${_selected.length} test${_selected.length > 1 ? 's' : ''} selected',
                              style: GoogleFonts.poppins(
                                  color: _text2,
                                  fontSize: 13)),
                          Text('Est. ₹$_totalCost',
                              style: GoogleFonts.poppins(
                                  color: _primary,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700)),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isEmpty
                            ? const Color(0xFF1E3050)
                            : _primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      onPressed:
                          (_sending || _selected.isEmpty)
                              ? null
                              : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text(
                              _selected.isEmpty
                                  ? 'Select tests to continue'
                                  : 'Send ${_selected.length} Test${_selected.length > 1 ? 's' : ''} to Patient',
                              style: GoogleFonts.poppins(
                                  color: _selected.isEmpty
                                      ? _text2
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}