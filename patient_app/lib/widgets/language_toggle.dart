// lib/widgets/language_toggle.dart
// Drop this widget anywhere — appbar actions, settings screen, home screen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/language_provider.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return GestureDetector(
      onTap: () => _showLanguageDialog(context, lang),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E2A42)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.isTamil ? '🇮🇳' : '🇬🇧',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              lang.isTamil ? 'தமிழ்' : 'EN',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B27),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          lang.t('select_language'),
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangOption(
              flag: '🇬🇧',
              label: 'English',
              selected: lang.isEnglish,
              onTap: () async {
                await lang.setLanguage('en');
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _LangOption(
              flag: '🇮🇳',
              label: 'தமிழ் (Tamil)',
              selected: lang.isTamil,
              onTap: () async {
                await lang.setLanguage('ta');
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF00C896);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _primary.withOpacity(0.1)
              : const Color(0xFF1E2535),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _primary : const Color(0xFF1E2A42)),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: selected ? _primary : Colors.white,
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: _primary, size: 20),
        ]),
      ),
    );
  }
}