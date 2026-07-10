import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import '../transfer/country_repository.dart';
import 'currency_search_field.dart';
import 'currency_tile.dart';

/// Full-screen country & currency picker with popular section + search.
class CountryCurrencyPicker extends StatefulWidget {
  const CountryCurrencyPicker({
    super.key,
    required this.title,
    this.selectedId,
  });

  final String title;
  final String? selectedId;

  static Future<CountryCurrencyOption?> show(
    BuildContext context, {
    required String title,
    String? selectedId,
  }) {
    return showModalBottomSheet<CountryCurrencyOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryCurrencyPicker(title: title, selectedId: selectedId),
    );
  }

  @override
  State<CountryCurrencyPicker> createState() => _CountryCurrencyPickerState();
}

class _CountryCurrencyPickerState extends State<CountryCurrencyPicker> {
  final _search = TextEditingController();
  final _repo = CountryRepository.instance;
  bool _loading = true;
  String _query = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _boot();
  }

  Future<void> _boot() async {
    await _repo.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CountryCurrencyOption> get _filtered => _repo.search(_query);

  List<CountryCurrencyOption> get _popularFiltered {
    final pop = _repo.popular;
    if (_query.isEmpty) return pop;
    final q = _query.toLowerCase();
    return pop.where((e) {
      return e.countryName.toLowerCase().contains(q) ||
          e.currencyCode.toLowerCase().contains(q);
    }).toList();
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: XmoneyTheme.navyDeep,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CurrencySearchField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_query.isNotEmpty) {
      return ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (_, i) => CurrencyTile(
          option: _filtered[i],
          selected: _filtered[i].id == _selectedId,
          onTap: () => Navigator.pop(context, _filtered[i]),
        ),
      );
    }

    final popular = _popularFiltered;
    final all = _repo.allAlphabetical;

    return CustomScrollView(
      slivers: [
        if (popular.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionHeader('Popular countries')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => CurrencyTile(
                option: popular[i],
                selected: popular[i].id == _selectedId,
                onTap: () => Navigator.pop(context, popular[i]),
              ),
              childCount: popular.length,
            ),
          ),
        ],
        SliverToBoxAdapter(child: _sectionHeader('All countries')),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => CurrencyTile(
              option: all[i],
              selected: all[i].id == _selectedId,
              onTap: () => Navigator.pop(context, all[i]),
            ),
            childCount: all.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      color: const Color(0xFFEEF2FA),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
