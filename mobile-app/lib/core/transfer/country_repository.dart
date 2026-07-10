import 'dart:convert';
import 'package:flutter/services.dart';
import 'country_currency_option.dart';

/// Loads worldwide ISO country/currency pairs from bundled dataset.
class CountryRepository {
  CountryRepository._();
  static final CountryRepository instance = CountryRepository._();

  List<CountryCurrencyOption>? _all;
  List<String>? _popularOrder;

  static const _popularCountryNames = [
    'United Arab Emirates',
    'Pakistan',
    'India',
    'Bangladesh',
    'Saudi Arabia',
    'United Kingdom',
    'United States',
    'Canada',
    'Australia',
    'China',
    'Philippines',
    'Nepal',
    'Sri Lanka',
    'Egypt',
  ];

  Future<void> ensureLoaded() async {
    if (_all != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/country_currencies.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _popularOrder = ((json['popularCountryCodes'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
      final seen = <String>{};
      _all = [];
      for (final raw in (json['entries'] as List?) ?? []) {
        final option = CountryCurrencyOption.tryParse(raw as Map<String, dynamic>);
        if (option == null) continue;
        if (seen.add(option.countryCode)) {
          _all!.add(option);
        }
      }
      _all!.sort((a, b) => a.countryName.compareTo(b.countryName));
    } catch (_) {
      _popularOrder = [];
      _all = _fallbackEntries();
    }
  }

  List<CountryCurrencyOption> _fallbackEntries() => const [
        CountryCurrencyOption(countryCode: 'AE', countryName: 'United Arab Emirates', currencyCode: 'AED', currencyName: 'UAE Dirham'),
        CountryCurrencyOption(countryCode: 'PK', countryName: 'Pakistan', currencyCode: 'PKR', currencyName: 'Pakistani Rupee'),
        CountryCurrencyOption(countryCode: 'IN', countryName: 'India', currencyCode: 'INR', currencyName: 'Indian Rupee'),
        CountryCurrencyOption(countryCode: 'GB', countryName: 'United Kingdom', currencyCode: 'GBP', currencyName: 'British Pound'),
        CountryCurrencyOption(countryCode: 'US', countryName: 'United States', currencyCode: 'USD', currencyName: 'US Dollar'),
      ];

  List<CountryCurrencyOption> get all => _all ?? [];

  List<CountryCurrencyOption> get popular {
    final order = _popularOrder ?? [];
    if (order.isEmpty) {
      return all
          .where((e) => _popularCountryNames.contains(e.countryName))
          .toList();
    }
    final byCode = {for (final e in all) e.countryCode: e};
    return [
      for (final code in order)
        if (byCode.containsKey(code)) byCode[code]!,
    ];
  }

  List<CountryCurrencyOption> get allAlphabetical => List<CountryCurrencyOption>.from(all);

  List<CountryCurrencyOption> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allAlphabetical;
    return allAlphabetical.where((e) {
      return e.countryName.toLowerCase().contains(q) ||
          e.countryCode.toLowerCase().contains(q) ||
          e.currencyCode.toLowerCase().contains(q) ||
          e.currencyName.toLowerCase().contains(q);
    }).toList();
  }

  CountryCurrencyOption? defaultForCountry(String countryCode) {
    final cc = countryCode.toUpperCase();
    for (final e in all) {
      if (e.countryCode == cc) return e;
    }
    return null;
  }

  CountryCurrencyOption? tryFindById(String? id) {
    if (id == null) return null;
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
