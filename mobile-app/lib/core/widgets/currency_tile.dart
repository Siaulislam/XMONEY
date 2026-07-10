import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import 'xm_country_flag.dart';

class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CountryCurrencyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              XmCountryFlag(countryCode: option.countryCode),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.countryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: XmoneyTheme.navyDeep,
                  ),
                ),
              ),
              Text(
                option.currencyCode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: XmoneyTheme.listRowText,
                ),
              ),
              const SizedBox(width: 14),
              _RadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: XmoneyTheme.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
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
