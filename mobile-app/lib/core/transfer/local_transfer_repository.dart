import 'dart:convert';
import 'package:flutter/services.dart';

class LocalBank {
  const LocalBank({
    required this.code,
    required this.name,
    required this.brandColor,
    this.logoUrl,
    this.logoAsset,
  });

  final String code;
  final String name;
  final String brandColor;
  final String? logoUrl;
  final String? logoAsset;

  static LocalBank? fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final name = json['name'] as String?;
    if (code == null || name == null) return null;
    return LocalBank(
      code: code,
      name: name,
      brandColor: json['brandColor'] as String? ?? '#1A4B8C',
      logoUrl: json['logoUrl'] as String?,
      logoAsset: json['logoAsset'] as String?,
    );
  }
}

/// Country banks dataset (local + international beneficiary corridors).
class CountryBankRepository {
  CountryBankRepository._();
  static final CountryBankRepository instance = CountryBankRepository._();

  List<Map<String, dynamic>>? _countries;

  Future<void> ensureLoaded() async {
    if (_countries != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/country_banks.json');
      _countries = ((jsonDecode(raw) as Map)['countries'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      try {
        final raw = await rootBundle.loadString('assets/data/local_banks.json');
        _countries = ((jsonDecode(raw) as Map)['countries'] as List).cast<Map<String, dynamic>>();
      } catch (_) {
        _countries = [];
      }
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

/// Back-compat accessor used by local transfer screens.
class LocalTransferRepository {
  LocalTransferRepository._();
  static final LocalTransferRepository instance = LocalTransferRepository._();
  final _repo = CountryBankRepository.instance;

  Future<void> ensureLoaded() => _repo.ensureLoaded();
  List<LocalBank> banksForCountry(String countryCode) => _repo.banksForCountry(countryCode);
  String? countryName(String countryCode) => _repo.countryName(countryCode);
}
