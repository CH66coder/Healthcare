import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF00C896);
  static const Color primaryDark = Color(0xFF00A07A);
  static const Color secondary = Color(0xFF1A1F3C);
  static const Color accent = Color(0xFF6C63FF);
  static const Color danger = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFB347);
  static const Color info = Color(0xFF2196F3);
  static const Color surface = Color(0xFF0D1117);
  static const Color surfaceCard = Color(0xFF161B27);
  static const Color surfaceElevated = Color(0xFF1E2535);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9EC7);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color divider = Color(0xFF1E2A42);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surfaceCard,
        error: danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

class AppConstants {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your key
  static const String jitsiServerUrl = 'meet.jit.si';

  // Firestore collections
  static const String colDoctors = 'doctors';
  static const String colMedicines = 'medicines';
  static const String colUsers = 'users';
  static const String colAppointments = 'appointments';
  static const String colOrders = 'orders';
  static const String colLabTests = 'lab_tests';
  static const String colChats = 'chats';
  static const String colNotifications = 'notifications';
  static const String colPrescriptions = 'prescriptions';

  // Specialty to icon map
  static const Map<String, String> specialtyIcons = {
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
    'urologist': '🏥',
    'pulmonologist': '🫁',
    'rheumatologist': '🦴',
    'anesthesiologist': '💉',
    'pathologist': '🧪',
    'ayurveda': '🌿',
    'cardiac-surgeon': '🫀',
    'neurosurgeon': '🔬',
    'plastic-surgeon': '✨',
  };

  // Pre-visit checklist by specialty
  static const Map<String, List<String>> preVisitChecklist = {
    'dermatologist': [
      'Note when the skin issue first appeared',
      'Check if rash/lesion has changed in size or color',
      'Avoid applying creams or makeup before visit',
      'Take photos of affected area in good lighting',
      'List any new soaps, detergents or foods tried recently',
      'Note any itching, pain or discharge',
    ],
    'gastroenterologist': [
      'Note stool color (brown=normal, black/red=alert)',
      'Check urine color (pale yellow=normal, dark=dehydrated)',
      'Fast for 8 hours if endoscopy is likely',
      'List all current medications including antacids',
      'Note frequency and consistency of bowel movements',
      'Bring previous reports or scans',
    ],
    'cardiologist': [
      'Check resting heart rate before visit',
      'Note any episodes of chest pain or breathlessness',
      'Bring previous ECG or echo reports',
      'List all heart medications you take',
      'Avoid caffeine 2 hours before visit',
      'Note if symptoms worsen with exertion',
    ],
    'general-physician': [
      'Check and note your temperature',
      'List all current symptoms with duration',
      'Bring a list of all medicines you take',
      'Note any recent travel history',
      'Check blood pressure if you have a home monitor',
      'Bring previous prescription or test reports',
    ],
    'default': [
      'List all your current symptoms',
      'Bring all previous medical records and reports',
      'Note duration of each symptom',
      'List all medicines you currently take',
      'Write down any questions for the doctor',
      'Bring your ID and insurance card',
    ],
  };
}
