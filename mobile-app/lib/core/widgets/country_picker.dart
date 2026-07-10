import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import '../transfer/country_currency_option.dart';
import '../transfer/country_repository.dart';
import 'currency_search_field.dart';

/// Country-only searchable picker (all ISO countries).
class CountryPicker extends StatefulWidget {
  const CountryPicker({super.key, required this.title, this.selectedCode});

  final String title;
  final String? selectedCode;

  static Future<CountryCurrencyOption?> show(
    BuildContext context, {
    required String title,
    String? selectedCode,
  }) {
    return showModalBottomSheet<CountryCurrencyOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryPicker(title: title, selectedCode: selectedCode),
    );
  }

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  final _search = TextEditingController();
  final _repo = CountryRepository.instance;
  bool _loading = true;
  String _query = '';
  String? _selected;

  List<CountryCurrencyOption> _uniqueCountries = [];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCode;
    _boot();
  }

  Future<void> _boot() async {
    await _repo.ensureLoaded();
    final seen = <String>{};
    final list = <CountryCurrencyOption>[];
    for (final e in _repo.allAlphabetical) {
      if (seen.add(e.countryCode)) list.add(e);
    }
    _uniqueCountries = list;
    if (mounted) setState(() => _loading = false);
  }

  List<CountryCurrencyOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _uniqueCountries;
    return _uniqueCountries.where((e) {
      return e.countryName.toLowerCase().contains(q) || e.countryCode.toLowerCase().contains(q);
    }).toList();
  }

  List<CountryCurrencyOption> get _popular {
    final codes = _repo.popular.map((e) => e.countryCode).toSet();
    return _uniqueCountries.where((e) => codes.contains(e.countryCode)).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CurrencySearchField(controller: _search, hint: 'Search country', onChanged: (v) => setState(() => _query = v)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _query.isNotEmpty
                    ? _countryList(_filtered)
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _header('Popular countries')),
                          SliverList(delegate: SliverChildBuilderDelegate((c, i) => _row(_popular[i]), childCount: _popular.length)),
                          SliverToBoxAdapter(child: _header('All countries')),
                          SliverList(delegate: SliverChildBuilderDelegate((c, i) => _row(_uniqueCountries[i]), childCount: _uniqueCountries.length)),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _countryList(List<CountryCurrencyOption> items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => _row(items[i]),
      );

  Widget _header(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        color: const Color(0xFFEEF2FA),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
      );

  Widget _row(CountryCurrencyOption e) {
    final selected = _selected == e.countryCode;
    return ListTile(
      onTap: () => Navigator.pop(context, e),
      leading: Text(countryFlagEmoji(e.countryCode), style: const TextStyle(fontSize: 26)),
      title: Text(e.countryName, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: selected
          ? Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: XmoneyTheme.teal, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            )
          : null,
    );
  }
}
