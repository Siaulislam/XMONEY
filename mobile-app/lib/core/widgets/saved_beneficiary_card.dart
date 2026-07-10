import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../beneficiaries/beneficiary.dart';
import '../transfer/country_currency_option.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import '../transfer/transfer_delivery_type.dart';

class SavedBeneficiaryCard extends StatelessWidget {
  const SavedBeneficiaryCard({
    super.key,
    required this.beneficiary,
    required this.onTransfer,
    required this.onEdit,
    required this.onDelete,
    required this.onFavourite,
  });

  final Beneficiary beneficiary;
  final VoidCallback onTransfer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final last = beneficiary.lastUsedAt != null ? dateFmt.format(beneficiary.lastUsedAt!) : 'Never';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(countryFlagEmoji(beneficiary.countryCode), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(beneficiary.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: XmoneyTheme.navyDeep)),
                      Text(beneficiary.receiverName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onFavourite,
                  icon: Icon(
                    beneficiary.isFavourite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: beneficiary.isFavourite ? XmoneyTheme.gold : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.payments_outlined, beneficiary.currencyCode),
                _chip(beneficiary.isWallet ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined, beneficiary.deliveryMethod.label),
                _chip(Icons.history_rounded, 'Last: $last'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTransfer,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Transfer again'),
                    style: OutlinedButton.styleFrom(foregroundColor: XmoneyTheme.teal, side: const BorderSide(color: XmoneyTheme.teal)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, color: Colors.red.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8ECF3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ],
        ),
      );
}
