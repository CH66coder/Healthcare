import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class LabTestScreen extends StatefulWidget {
  final List<String>? recommendedTests;
  const LabTestScreen({super.key, this.recommendedTests});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final _svc = FirebaseService();
  final List<String> _selectedTests = [];
  String _selectedLab = '';
  bool _loading = false;

  static const Color _primary = Color(0xFFFFB347);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
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

  final _labs = [
    'Apollo Diagnostics',
    'Thyrocare',
    'Dr. Lal PathLabs',
    'SRL Diagnostics',
    'Metropolis',
    'Vijaya Diagnostics',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select recommended tests from chatbot
    if (widget.recommendedTests != null) {
      _selectedTests.addAll(widget.recommendedTests!);
    }
  }

  int get _total => _selectedTests.fold(0, (sum, name) {
        final test = _allTests.firstWhere((t) => t['name'] == name,
            orElse: () => {'price': 0});
        return sum + (test['price'] as int);
      });

  Future<void> _bookTests() async {
    if (_selectedTests.isEmpty) {
      _snack('Select at least one test');
      return;
    }
    if (_selectedLab.isEmpty) {
      _snack('Select a lab');
      return;
    }
    setState(() => _loading = true);
    final id = await _svc.bookLabTest({
      'tests': _selectedTests,
      'lab': _selectedLab,
      'totalAmount': _total,
      'status': 'booked',
    });
    setState(() => _loading = false);
    if (id.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧪', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text('Lab Tests Booked!',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('${_selectedTests.length} tests at $_selectedLab\n\nBooking ID: $id',
                  style: GoogleFonts.poppins(color: _text2, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    } else {
      _snack('Booking failed. Try again.');
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
          backgroundColor: _bg, title: const Text('Book Lab Tests')),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Tests',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._allTests.map((test) {
                  final name = test['name'] as String;
                  final sel = _selectedTests.contains(name);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (sel) {
                          _selectedTests.remove(name);
                        } else {
                          _selectedTests.add(name);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? _primary.withOpacity(0.1)
                            : _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? _primary : _border),
                      ),
                      child: Row(children: [
                        Text(test['icon'] as String,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(name,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13))),
                        Text('₹${test['price']}',
                            style: GoogleFonts.poppins(
                                color: _text2, fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(
                          sel
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: sel ? _primary : const Color(0xFF4A5568),
                          size: 20,
                        ),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text('Select Lab',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _labs.map((lab) {
                    final sel = _selectedLab == lab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLab = lab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _primary.withOpacity(0.15)
                              : _card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? _primary : _border),
                        ),
                        child: Text(lab,
                            style: GoogleFonts.poppins(
                                color:
                                    sel ? _primary : _text2,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        if (_selectedTests.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF161B27),
              border: Border(top: BorderSide(color: Color(0xFF1E2A42))),
            ),
            child: Row(children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_selectedTests.length} tests',
                      style: GoogleFonts.poppins(
                          color: _text2, fontSize: 12)),
                  Text('₹$_total',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary),
                  onPressed: _loading ? null : _bookTests,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Book Tests →'),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
