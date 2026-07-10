import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';
import 'pay_from_wallet_picker.dart';

/// Review summary for International Bank Transfer (step 3).
class BankTransferReviewPanel extends StatelessWidget {
  const BankTransferReviewPanel({
    super.key,
    required this.receiverName,
    required this.countryName,
    required this.currencyCode,
    required this.transferMethod,
    required this.bankName,
    required this.mobile,
    required this.account,
    required this.purpose,
    required this.senderWallets,
    required this.selectedWalletId,
    required this.onWalletChanged,
    this.walletError,
  });

  final String receiverName;
  final String countryName;
  final String currencyCode;
  final String transferMethod;
  final String bankName;
  final String mobile;
  final String account;
  final String purpose;
  final List<Map<String, dynamic>> senderWallets;
  final String? selectedWalletId;
  final ValueChanged<String> onWalletChanged;
  final String? walletError;

  static const _text = Color(0xFF071526);
  static const _muted = Color(0xFF4B5563);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text)),
              const SizedBox(height: 12),
              _row('Receiver', receiverName),
              _row('Country', countryName),
              _row('Currency', currencyCode),
              _row('Transfer Method', transferMethod),
              _row('Bank', bankName),
              if (mobile.isNotEmpty) _row('Mobile', mobile),
              if (account.isNotEmpty) _row('Account / IBAN', account),
              if (purpose.isNotEmpty) _row('Purpose', purpose),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PayFromWalletPicker(
          wallets: senderWallets,
          selectedId: selectedWalletId,
          onChanged: onWalletChanged,
          errorText: walletError,
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600))),
            Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text))),
          ],
        ),
      );
}
