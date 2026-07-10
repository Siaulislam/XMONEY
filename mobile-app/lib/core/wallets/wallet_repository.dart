import 'dart:convert';
import 'package:flutter/services.dart';
import '../api/api_client.dart';
import 'country_wallet_mapping.dart';
import 'wallet_provider.dart';

/// Loads country → digital wallet mappings from API with bundled fallback.
class WalletRepository {
  WalletRepository(this.api);

  final ApiClient api;

  Map<String, WalletProvider>? _providersByCode;
  List<CountryWalletMapping>? _mappings;
  DateTime? _lastFetch;
  static const _cacheTtl = Duration(minutes: 30);

  Future<void> ensureLoaded({bool force = false}) async {
    if (!force &&
        _providersByCode != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return;
    }

    final apiOk = await _loadFromApi();
    if (!apiOk) {
      await _loadFromBundle();
    }
  }

  Future<bool> _loadFromApi() async {
    try {
      final res = await api.get('/v1/digital-wallets');
      if (res['success'] != true || res['data'] == null) return false;
      final data = res['data'] as Map<String, dynamic>;
      _ingestPayload(data);
      _lastFetch = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadFromBundle() async {
    final raw = await rootBundle.loadString('assets/data/country_wallet_providers.json');
    _ingestPayload(jsonDecode(raw) as Map<String, dynamic>);
    _lastFetch = DateTime.now();
  }

  void _ingestPayload(Map<String, dynamic> data) {
    final providers = <String, WalletProvider>{};
    for (final row in (data['providers'] as List?) ?? []) {
      final p = WalletProvider.tryParse(row as Map<String, dynamic>);
      if (p != null) providers[p.code] = p;
    }
    _providersByCode = providers;

    final mappings = <CountryWalletMapping>[];
    for (final row in (data['mappings'] as List?) ?? []) {
      final m = row as Map<String, dynamic>;
      final cc = m['countryCode'] as String? ?? m['country_code'] as String?;
      if (cc == null) continue;
      final codes = ((m['providerCodes'] as List?) ?? (m['provider_codes'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
      final list = <WalletProvider>[];
      for (final code in codes) {
        final p = providers[code];
        if (p != null) list.add(p);
      }
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      mappings.add(CountryWalletMapping(
        countryCode: cc.toUpperCase(),
        countryName: m['countryName'] as String? ?? m['country_name'] as String?,
        providers: list,
      ));
    }
    _mappings = mappings;
  }

  Future<CountryWalletMapping> forCountry(String countryCode) async {
    await ensureLoaded();
    final cc = countryCode.toUpperCase();
    final hit = _mappings?.where((m) => m.countryCode == cc).firstOrNull;
    if (hit != null) return hit;

    // Live lookup when cache has no mapping row (API may return country-specific list).
    try {
      final res = await api.get('/v1/digital-wallets?country=$cc');
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (data is Map<String, dynamic>) {
          final list = ((data['providers'] as List?) ?? [])
              .map((e) => WalletProvider.tryParse(e as Map<String, dynamic>))
              .whereType<WalletProvider>()
              .toList();
          return CountryWalletMapping(countryCode: cc, providers: list);
        }
      }
    } catch (_) {}

    return CountryWalletMapping.empty(cc);
  }

  List<WalletProvider> search(CountryWalletMapping mapping, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return mapping.providers;
    return mapping.providers.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q);
    }).toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
