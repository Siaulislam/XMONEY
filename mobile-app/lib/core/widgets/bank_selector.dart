import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/local_transfer_repository.dart';

/// Searchable list of destination-country banks (international bank transfer).
class BankSelector extends StatefulWidget {
  const BankSelector({
    super.key,
    required this.countryName,
    required this.banks,
    required this.selected,
    required this.onSelected,
    this.loading = false,
  });

  final String countryName;
  final List<LocalBank> banks;
  final LocalBank? selected;
  final ValueChanged<LocalBank> onSelected;
  final bool loading;

  @override
  State<BankSelector> createState() => _BankSelectorState();
}

class _BankSelectorState extends State<BankSelector> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<LocalBank> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.banks;
    return widget.banks.where((b) {
      return b.name.toLowerCase().contains(q) || b.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficiary bank in ${widget.countryName}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2, color: XmoneyTheme.teal),
          )
        else if (widget.banks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Text(
              'No banks configured for ${widget.countryName} yet. You can enter bank details in the next step.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          )
        else ...[
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            cursorColor: XmoneyTheme.teal,
            style: const TextStyle(color: XmoneyTheme.navyDeep),
            decoration: InputDecoration(
              hintText: 'Search banks',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF6F8FC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: XmoneyTheme.teal, width: 1.2),
              ),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final bank = _filtered[i];
              final selected = widget.selected?.code == bank.code;
              return _BankTile(
                bank: bank,
                selected: selected,
                onTap: () => widget.onSelected(bank),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.bank, required this.selected, required this.onTap});

  final LocalBank bank;
  final bool selected;
  final VoidCallback onTap;

  Color get _brand {
    try {
      return Color(int.parse('FF${bank.brandColor.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return XmoneyTheme.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? XmoneyTheme.teal : const Color(0xFFE8ECF3), width: selected ? 1.6 : 1),
        boxShadow: selected
            ? [BoxShadow(color: XmoneyTheme.teal.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _BankLogo(bank: bank, brand: _brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bank.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep),
                  ),
                ),
                _RadioMark(selected: selected, accent: _brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.bank, required this.brand});

  final LocalBank bank;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    if (bank.logoAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(bank.logoAsset!, width: 44, height: 44, fit: BoxFit.contain),
      );
    }
    if (bank.logoUrl != null && bank.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          bank.logoUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final initial = bank.name.isNotEmpty ? bank.name[0].toUpperCase() : 'B';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: brand.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.withOpacity(0.35)),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: brand)),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
    );
  }
}
