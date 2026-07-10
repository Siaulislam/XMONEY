import 'dart:convert';
import 'package:flutter/services.dart';

class LocalBank {
  const LocalBank({required this.code, required this.name, required this.brandColor});

  final String code;
  final String name;
  final String brandColor;

  static LocalBank? fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final name = json['name'] as String?;
    if (code == null || name == null) return null;
    return LocalBank(
      code: code,
      name: name,
      brandColor: json['brandColor'] as String? ?? '#1A4B8C',
    );
  }
}

/// Local banks available in the customer's registered country.
class LocalTransferRepository {
  LocalTransferRepository._();
  static final LocalTransferRepository instance = LocalTransferRepository._();

  List<Map<String, dynamic>>? _countries;

  Future<void> ensureLoaded() async {
    if (_countries != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/local_banks.json');
      _countries = ((jsonDecode(raw) as Map)['countries'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _countries = [];
    }
  }

  List<LocalBank> banksForCountry(String countryCode) {
    final cc = countryCode.toUpperCase();
    for (final row in _countries ?? []) {
      if (row['countryCode'] == cc) {
        return ((row['banks'] as List?) ?? [])
            .map((e) => LocalBank.fromJson(e as Map<String, dynamic>))
            .whereType<LocalBank>()
            .toList();
      }
    }
    return [];
  }

  String? countryName(String countryCode) {
    final cc = countryCode.toUpperCase();
    for (final row in _countries ?? []) {
      if (row['countryCode'] == cc) return row['countryName'] as String?;
    }
    return null;
  }
}
