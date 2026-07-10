import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../wallets/wallet_provider.dart';
import '../wallets/wallet_repository.dart';
import '../wallets/country_wallet_mapping.dart';

/// Searchable list of destination digital wallet providers.
class WalletSelector extends StatefulWidget {
  const WalletSelector({
    super.key,
    required this.mapping,
    required this.repository,
    this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final CountryWalletMapping mapping;
  final WalletRepository repository;
  final WalletProvider? selected;
  final ValueChanged<WalletProvider> onSelected;
  final bool compact;

  @override
  State<WalletSelector> createState() => _WalletSelectorState();
}

class _WalletSelectorState extends State<WalletSelector> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WalletProvider> get _filtered => widget.repository.search(widget.mapping, _query);

  @override
  Widget build(BuildContext context) {
    if (!widget.mapping.hasWallets) return const SizedBox.shrink();

    final list = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          Text(
            'Digital wallets',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search wallets',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF3F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: list.isEmpty
              ? Padding(
                  key: const ValueKey('empty'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No wallets match your search', style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.separated(
                  key: ValueKey('list-$_query-${list.length}'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final selected = widget.selected?.code == p.code;
                    return _WalletProviderTile(
                      provider: p,
                      selected: selected,
                      onTap: () => widget.onSelected(p),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WalletProviderTile extends StatelessWidget {
  const _WalletProviderTile({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final WalletProvider provider;
  final bool selected;
  final VoidCallback onTap;

  Color get _brand {
    try {
      final hex = provider.brandColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return XmoneyTheme.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? XmoneyTheme.teal : const Color(0xFFE8ECF3),
          width: selected ? 1.6 : 1,
        ),
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
                _WalletLogo(provider: provider, brand: _brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: XmoneyTheme.navyDeep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RadioMark(selected: selected, accent: _brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletLogo extends StatelessWidget {
  const _WalletLogo({required this.provider, required this.brand});

  final WalletProvider provider;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    if (provider.logoAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(provider.logoAsset!, width: 44, height: 44, fit: BoxFit.cover),
      );
    }
    if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(provider.logoUrl!, width: 44, height: 44, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final initial = provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'W';
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
