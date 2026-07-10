import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Sender wallet picker — shown at the end of the transfer flow only.
class PayFromWalletPicker extends StatelessWidget {
  const PayFromWalletPicker({
    super.key,
    required this.wallets,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
  });

  final List<Map<String, dynamic>> wallets;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay from wallet', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: errorText != null ? Colors.red.shade300 : const Color(0xFFE8ECF3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: wallets.any((w) => (w['uuid'] ?? w['id']) == selectedId) ? selectedId : null,
              hint: const Text('Select wallet', style: TextStyle(color: Color(0xFF9CA3AF))),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF071526)),
              dropdownColor: Colors.white,
              items: wallets.map((w) {
                final id = w['uuid'] as String? ?? w['id']?.toString() ?? '';
                final label = w['label'] as String? ?? w['name'] as String? ?? 'Wallet';
                final cur = w['currency_code'] as String? ?? '';
                return DropdownMenuItem(value: id, child: Text('$label · $cur', style: const TextStyle(color: Color(0xFF071526))));
              }).toList(),
              onChanged: wallets.isEmpty ? null : (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }
}
