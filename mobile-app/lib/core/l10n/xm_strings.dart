import 'dart:convert';
import 'package:flutter/services.dart';

/// JSON-based i18n — English, Arabic, Urdu with RTL support.
class XmStrings {
  XmStrings._();
  static final XmStrings instance = XmStrings._();

  static const rtlLocales = {'ar', 'ur'};
  String _lang = 'en';
  Map<String, String> _catalog = {};

  String get lang => _lang;
  bool get isRtl => rtlLocales.contains(_lang);

  String t(String key, [String? fallback]) => _catalog[key] ?? fallback ?? key;

  Future<void> load(String code) async {
    final raw = await rootBundle.loadString('assets/i18n/$code.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _catalog = json.map((k, v) => MapEntry(k, v.toString()));
    _lang = code;
  }
}
