import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import 'country_currency_picker.dart';

/// Currency row with optional inline editable send amount.
class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.label,
    required this.option,
    required this.onCurrencyTap,
    this.amountText,
    this.amountController,
    this.onAmountChanged,
    this.amountColor,
    this.feeLabel,
    this.showFeeBadge = false,
  });

  final String label;
  final CountryCurrencyOption option;
  final VoidCallback onCurrencyTap;
  final String? amountText;
  final TextEditingController? amountController;
  final ValueChanged<String>? onAmountChanged;
  final Color? amountColor;
  final String? feeLabel;
  final bool showFeeBadge;

  bool get _editable => amountController != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FC),
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCurrencyTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(countryFlagEmoji(option.countryCode), style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: _editable ? 140 : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_editable)
                        TextField(
                          controller: amountController,
                          onChanged: onAmountChanged,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                            _OneDecimalFormatter(),
                          ],
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: amountColor ?? XmoneyTheme.navyDeep,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: '0',
                          ),
                        )
                      else
                        Text(
                          amountText ?? '0.00',
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
                ),
              ],
            ),
          ],
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

/// Allows only one decimal point in amount input.
class _OneDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if ('.'.allMatches(t).length > 1) return oldValue;
    if (t.startsWith('.')) return oldValue;
    return newValue;
  }
}
