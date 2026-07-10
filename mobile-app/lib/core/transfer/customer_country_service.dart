import 'dart:convert';
import 'package:flutter/services.dart';
import '../api/api_client.dart';

/// Resolves the customer's registered country (no re-prompt on local transfers).
class CustomerCountryService {
  CustomerCountryService(this.api);

  final ApiClient api;
  String? _cached;

  Future<String> resolveCountryCode() async {
    if (_cached != null) return _cached!;
    if (api.previewBypassAuth) {
      _cached = 'PK';
      return _cached!;
    }
    try {
      final res = await api.get('/v1/me');
      if (res['success'] == true) {
        final profile = res['data'] as Map<String, dynamic>?;
        final cc = profile?['country_code'] as String? ??
            (profile?['profile'] as Map?)?['country_code'] as String?;
        if (cc != null && cc.length == 2) {
          _cached = cc.toUpperCase();
          return _cached!;
        }
      }
    } catch (_) {}
    _cached = 'AE';
    return _cached!;
  }

  Future<String> resolveCountryName(String code) async {
    await LocalCountryNames.ensureLoaded();
    return LocalCountryNames.nameFor(code);
  }
}

class LocalCountryNames {
  static Map<String, String>? _names;

  static Future<void> ensureLoaded() async {
    if (_names != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/local_banks.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _names = {};
      for (final row in (json['countries'] as List?) ?? []) {
        final m = row as Map<String, dynamic>;
        final cc = m['countryCode'] as String?;
        final name = m['countryName'] as String?;
        if (cc != null && name != null) _names![cc] = name;
      }
    } catch (_) {
      _names = const {
        'PK': 'Pakistan',
        'IN': 'India',
        'BD': 'Bangladesh',
        'AE': 'United Arab Emirates',
      };
    }
  }

  static String nameFor(String code) => _names?[code.toUpperCase()] ?? code;
}
