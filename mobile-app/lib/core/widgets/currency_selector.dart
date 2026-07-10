import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import 'country_currency_picker.dart';

/// Tappable currency row used on the international transfer screen.
class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.label,
    required this.option,
    required this.amountText,
    required this.onTap,
    this.amountColor,
    this.feeLabel,
    this.showFeeBadge = false,
  });

  final String label;
  final CountryCurrencyOption option;
  final String amountText;
  final VoidCallback onTap;
  final Color? amountColor;
  final String? feeLabel;
  final bool showFeeBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (feeLabel != null)
                    Text(feeLabel!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(countryFlagEmoji(option.countryCode), style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  option.currencyCode,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: XmoneyTheme.navyDeep,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: XmoneyTheme.navyDeep),
                              ],
                            ),
                            Text(
                              option.currencyName,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: amountColor ?? XmoneyTheme.navyDeep,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (showFeeBadge)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: XmoneyTheme.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Includes fee',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: XmoneyTheme.blue),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<CountryCurrencyOption?> pick(
    BuildContext context, {
    required String title,
    String? selectedId,
  }) {
    return CountryCurrencyPicker.show(context, title: title, selectedId: selectedId);
  }
}
