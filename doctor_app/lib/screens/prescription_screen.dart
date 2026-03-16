import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/doctor_firebase_service.dart';

class PrescriptionScreen extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String patientName;

  const PrescriptionScreen({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _svc = DoctorFirebaseService();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _specialistCtrl = TextEditingController();
  final _medSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> _prescribedMeds = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = false;
  bool _searching = false;

  static const Color _primary = Color(0xFF2196F3);
  static const Color _bg = Color(0xFF0A0F1E);
  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);
  static const Color _text2 = Color(0xFF8B9EC7);

  // Pre-defined specialties for referral
  final _specialties = [
    'dermatologist',
    'cardiologist',
    'neurologist',
    'orthopedist',
    'gastroenterologist',
    'pediatrician',
    'gynecologist',
    'psychiatrist',
    'ophthalmologist',
    'endocrinologist',
    'oncologist',
    'nephrologist',
    'urologist',
  ];

  Future<void> _searchMedicines(String query) async {
  if (query.length < 2) {
    setState(() => _searchResults = []);
    return;
  }
  setState(() => _searching = true);
  final results = await _svc.searchMedicines(query);
  
  // Debug: print what fields are coming back
  if (results.isNotEmpty) {
    print('First result keys: ${results.first.keys.toList()}');
    print('First result: ${results.first}');
  }
  
  setState(() {
    _searchResults = results;
    _searching = false;
  });
}

  void _addMedicine(Map<String, dynamic> med) {
  if (_prescribedMeds.any((m) => m['id'] == med['id'])) return;
  
  final name = (med['Name'] ?? med['name'] ?? 
                med['medicine_name'] ?? '').toString().trim();
  final category = (med['Category'] ?? med['category'] ?? '').toString();
  final dosageForm = (med['Dosage Form'] ?? med['dosageForm'] ?? '').toString();
  final strength = (med['Strength'] ?? med['strength'] ?? '').toString();

  setState(() {
    _prescribedMeds.add({
      'id': med['id'],
      'name': name,
      'category': category,
      'dosageForm': dosageForm,
      'strength': strength,
      'dosage': '1 tablet',
      'frequency': 'Once daily',
      'duration': '7 days',
      'instructions': 'After meals',
    });
    _searchResults = [];
    _medSearchCtrl.clear();
  });
}

  void _removeMedicine(int index) {
    setState(() => _prescribedMeds.removeAt(index));
  }

  Future<void> _submitPrescription() async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      _snack('Enter diagnosis');
      return;
    }
    setState(() => _loading = true);

    final prescId = await _svc.writePrescription(
      patientId: widget.patientId,
      patientName: widget.patientName,
      appointmentId: widget.appointmentId,
      medicines: _prescribedMeds,
      diagnosis: _diagnosisCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      specialistReferral: _specialistCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (prescId.isNotEmpty && mounted) {
      _snack('Prescription sent to patient ✅');
      Navigator.of(context).pop();
    } else {
      _snack('Failed to send prescription');
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
        backgroundColor: _bg,
        title: Text('Prescription — ${widget.patientName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.patientName,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text('Patient',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 12)),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Diagnosis
            _label('Diagnosis *'),
            TextField(
              controller: _diagnosisCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('e.g. Fungal Infection - Tinea Corporis'),
            ),
            const SizedBox(height: 16),

            // Search medicines from Firebase
            _label('Add Medicines (from your Firebase)'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _medSearchCtrl,
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: _inputDeco('Search medicine by name...'),
                  onChanged: _searchMedicines,
                ),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _primary)),
                ),
            ]),

            // REPLACE the search results dropdown:
if (_searchResults.isNotEmpty)
  Container(
    margin: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: _searchResults.take(5).map((med) {
        // Handle all possible field name formats
        final name = (med['Name'] ?? 
                      med['name'] ?? 
                      med['medicine_name'] ?? 
                      med['NAME'] ?? '').toString().trim();
        final category = (med['Category'] ?? 
                          med['category'] ?? '').toString();
        final dosageForm = (med['Dosage Form'] ?? 
                            med['dosage_form'] ?? 
                            med['dosageForm'] ?? '').toString();
        final strength = (med['Strength'] ?? 
                          med['strength'] ?? '').toString();
        
        return ListTile(
          dense: true,
          leading: const Text('💊', style: TextStyle(fontSize: 18)),
          title: Text(
            name.isNotEmpty ? name : '(unnamed)',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13)),
          subtitle: Text(
            '$category • $dosageForm • $strength',
            style: GoogleFonts.poppins(
                color: _text2, fontSize: 11)),
          trailing: const Icon(Icons.add_circle_outline,
              color: _primary),
          onTap: () => _addMedicine(med),
        );
      }).toList(),
    ),
  ),

            const SizedBox(height: 12),

            // Prescribed medicines list
            if (_prescribedMeds.isNotEmpty) ...[
              _label('Prescribed Medicines'),
              ..._prescribedMeds.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return _PrescribedMedTile(
                  med: med,
                  index: i,
                  onRemove: () => _removeMedicine(i),
                  onChanged: (updated) {
                    setState(() => _prescribedMeds[i] = updated);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),

            // Specialist referral
            _label('Refer to Specialist (optional)'),
            Text(
              'This will trigger the chatbot on the patient\'s app to book a specialist appointment',
              style: GoogleFonts.poppins(color: _text2, fontSize: 11),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _specialistCtrl.text.isEmpty
                  ? null
                  : _specialistCtrl.text,
              dropdownColor: _card,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('Select specialist...'),
              items: _specialties
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _specialistCtrl.text = val ?? '');
              },
            ),
            const SizedBox(height: 16),

            // Notes
            _label('Additional Notes'),
            TextField(
              controller: _notesCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: _inputDeco(
                  'e.g. Monitor blood pressure daily. Follow-up in 2 weeks.'),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitPrescription,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send Prescription to Patient'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(color: const Color(0xFF4A5568), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1A2340),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3050)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3050)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Prescribed Medicine Tile ────────────────────────────────
class _PrescribedMedTile extends StatelessWidget {
  final Map<String, dynamic> med;
  final int index;
  final VoidCallback onRemove;
  final Function(Map<String, dynamic>) onChanged;

  const _PrescribedMedTile({
    required this.med,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);
  static const Color _primary = Color(0xFF2196F3);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.medication_outlined, color: _primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                med['name'] ?? '',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Color(0xFFFF4757), size: 18),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          Text(
            '${med['category']} • ${med['dosageForm']} • ${med['strength']}',
            style: GoogleFonts.poppins(color: _text2, fontSize: 11),
          ),
          const SizedBox(height: 10),
          // Dosage fields
          Row(children: [
            Expanded(
              child: _DropField(
                label: 'Frequency',
                value: med['frequency'],
                items: [
                  'Once daily',
                  'Twice daily',
                  'Three times daily',
                  'As needed',
                ],
                onChanged: (v) =>
                    onChanged({...med, 'frequency': v}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DropField(
                label: 'Duration',
                value: med['duration'],
                items: ['3 days', '5 days', '7 days', '14 days', '30 days'],
                onChanged: (v) =>
                    onChanged({...med, 'duration': v}),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _DropField(
            label: 'Instructions',
            value: med['instructions'],
            items: [
              'After meals',
              'Before meals',
              'With food',
              'On empty stomach',
              'At bedtime',
            ],
            onChanged: (v) => onChanged({...med, 'instructions': v}),
          ),
        ],
      ),
    );
  }
}

class _DropField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                color: const Color(0xFF8B9EC7), fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2340),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E3050)),
          ),
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            dropdownColor: const Color(0xFF131929),
            underline: const SizedBox(),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            items: items
                .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(i,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12))))
                .toList(),
            onChanged: (v) => onChanged(v ?? value),
          ),
        ),
      ],
    );
  }
}
