import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChecklistWidget extends StatefulWidget {
  final List<String> items;
  final List<String> precautions;

  const ChecklistWidget({
    super.key,
    required this.items,
    required this.precautions,
  });

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  final Set<int> _checked = {};
  bool _showPrecautions = false;

  @override
  Widget build(BuildContext context) {
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
            // Checklist header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checklist_rounded,
                      color: Color(0xFF00C896), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Pre-Visit Checklist',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_checked.length}/${widget.items.length}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00C896),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.items.isEmpty
                      ? 0
                      : _checked.length / widget.items.length,
                  backgroundColor: const Color(0xFF1E2A42),
                  color: const Color(0xFF00C896),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Checklist items
            ...widget.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final checked = _checked.contains(i);
              return InkWell(
                onTap: () => setState(() {
                  if (checked) {
                    _checked.remove(i);
                  } else {
                    _checked.add(i);
                  }
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        checked
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: checked
                            ? const Color(0xFF00C896)
                            : const Color(0xFF4A5568),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            color: checked
                                ? const Color(0xFF8B9EC7)
                                : Colors.white,
                            fontSize: 13,
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF8B9EC7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Precautions section
            if (widget.precautions.isNotEmpty) ...[
              const Divider(color: Color(0xFF1E2A42), height: 1),
              InkWell(
                onTap: () =>
                    setState(() => _showPrecautions = !_showPrecautions),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB347).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFFB347), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Precautions to Take',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showPrecautions
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8B9EC7),
                      size: 20,
                    ),
                  ]),
                ),
              ),
              if (_showPrecautions)
                ...widget.precautions.map((p) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B9EC7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
