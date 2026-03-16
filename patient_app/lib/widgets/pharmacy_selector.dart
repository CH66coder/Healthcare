import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacySelectorWidget extends StatefulWidget {
  final Function(String) onPharmacySelected;

  const PharmacySelectorWidget({
    super.key,
    required this.onPharmacySelected,
  });

  @override
  State<PharmacySelectorWidget> createState() =>
      _PharmacySelectorWidgetState();
}

class _PharmacySelectorWidgetState extends State<PharmacySelectorWidget> {
  String? _selected;
  bool _confirmed = false;

  final List<Map<String, String>> _pharmacies = [
    {'name': 'Apollo Pharmacy', 'icon': '🏪', 'time': '30 min delivery'},
    {'name': 'MedPlus', 'icon': '💊', 'time': '45 min delivery'},
    {'name': 'Netmeds', 'icon': '📦', 'time': '2 hour delivery'},
    {'name': '1mg', 'icon': '🔵', 'time': '1 hour delivery'},
    {'name': 'PharmEasy', 'icon': '🟢', 'time': '45 min delivery'},
    {'name': 'Wellness Forever', 'icon': '💚', 'time': '1 hour delivery'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF00C896).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00C896), size: 20),
            const SizedBox(width: 10),
            Text(
              'Selected: $_selected',
              style: GoogleFonts.poppins(
                color: const Color(0xFF00C896),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2A42)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_pharmacy_outlined,
                      color: Color(0xFF6C63FF), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Choose Pharmacy',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
            ..._pharmacies.map((pharmacy) {
              final name = pharmacy['name']!;
              final sel = _selected == name;
              return InkWell(
                onTap: () => setState(() => _selected = name),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF6C63FF).withOpacity(0.1)
                        : const Color(0xFF1E2535),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF6C63FF).withOpacity(0.4)
                          : const Color(0xFF1E2A42),
                    ),
                  ),
                  child: Row(children: [
                    Text(pharmacy['icon']!,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: GoogleFonts.poppins(
                                color: sel ? Colors.white : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              )),
                          Text(pharmacy['time']!,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B9EC7),
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                    Icon(
                      sel
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: sel
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF4A5568),
                      size: 20,
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() => _confirmed = true);
                    widget.onPharmacySelected(_selected!);
                  },
                  child: Text(
                    'Order from $_selected',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
