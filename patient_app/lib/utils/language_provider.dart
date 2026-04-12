// lib/utils/language_provider.dart
// Simple language state manager — no extra packages needed

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;
  bool get isTamil => _languageCode == 'ta';
  bool get isEnglish => _languageCode == 'en';

  // Translate a key
  String t(String key) =>
      AppTranslations.translate(key, _languageCode);

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    _languageCode = saved;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_languageCode == 'en' ? 'ta' : 'en');
  }
}