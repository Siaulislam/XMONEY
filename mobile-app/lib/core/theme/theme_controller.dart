import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'xm_strings.dart';

enum XmThemeMode { light, dark, system }

/// Persists theme + locale; detects system theme.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  final SharedPreferences _prefs;
  static const _themeKey = 'xm_theme';
  static const _langKey = 'xm_lang';

  XmThemeMode _themeMode = XmThemeMode.system;
  Locale _locale = const Locale('en');

  XmThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isRtl => XmStrings.instance.isRtl;

  ThemeMode get materialThemeMode => switch (_themeMode) {
        XmThemeMode.light => ThemeMode.light,
        XmThemeMode.dark => ThemeMode.dark,
        XmThemeMode.system => ThemeMode.system,
      };

  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ThemeController(prefs);
    await c._load();
    return c;
  }

  Future<void> _load() async {
    final theme = _prefs.getString(_themeKey);
    if (theme == 'light') _themeMode = XmThemeMode.light;
    if (theme == 'dark') _themeMode = XmThemeMode.dark;
    if (theme == 'system') _themeMode = XmThemeMode.system;

    final lang = _prefs.getString(_langKey) ?? 'en';
    await XmStrings.instance.load(lang);
    _locale = Locale(lang);
  }

  Future<void> setThemeMode(XmThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    await XmStrings.instance.load(code);
    _locale = Locale(code);
    await _prefs.setString(_langKey, code);
    notifyListeners();
  }
}
