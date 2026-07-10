import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../transfer/country_currency_option.dart';
import '../theme/xmoney_theme.dart';
import '../wallets/wallet_provider.dart';
import '../widgets/xm_ui.dart';
import 'international_transfer_screen.dart';

enum WalletDeliveryField { mobile, accountId, upiId }

/// Completes a local digital wallet transfer for the selected provider.
class WalletTransferScreen extends StatefulWidget {
  const WalletTransferScreen({
    super.key,
    required this.router,
    required this.provider,
    required this.receiver,
    required this.senderCurrency,
    required this.sendAmount,
    required this.quote,
    this.payFromWalletId,
  });

  final AppRouter router;
  final WalletProvider provider;
  final CountryCurrencyOption receiver;
  final String senderCurrency;
  final double sendAmount;
  final Map<String, dynamic>? quote;
  final String? payFromWalletId;

  @override
  State<WalletTransferScreen> createState() => _WalletTransferScreenState();
}

class _WalletTransferScreenState extends State<WalletTransferScreen> {
  final _account = TextEditingController();
  WalletDeliveryField _field = WalletDeliveryField.mobile;

  @override
  void initState() {
    super.initState();
    _field = _defaultField(widget.provider, widget.receiver.countryCode);
    _account.addListener(() => setState(() {}));
  }

  WalletDeliveryField _defaultField(WalletProvider p, String country) {
    if (p.code.contains('upi') || p.code == 'bhim_upi' || p.code == 'google_pay') {
      return WalletDeliveryField.upiId;
    }
    if (country == 'IN') return WalletDeliveryField.upiId;
    return WalletDeliveryField.mobile;
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  String get _fieldLabel {
    switch (_field) {
      case WalletDeliveryField.upiId:
        return 'UPI ID / VPA';
      case WalletDeliveryField.accountId:
        return 'Wallet account ID';
      case WalletDeliveryField.mobile:
        return 'Mobile wallet number';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final receive = (widget.quote?['receive_amount'] as num?)?.toDouble() ?? 0;
    final fee = (widget.quote?['fee_amount'] as num?)?.toDouble() ?? 0;
    final total = (widget.quote?['total_debit'] as num?)?.toDouble() ?? widget.sendAmount + fee;
    final maxW = XmLayout.maxContentWidth(context);

    Color brand;
    try {
      final hex = widget.provider.brandColor.replaceFirst('#', '');
      brand = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      brand = XmoneyTheme.teal;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: XmoneyTheme.navyDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Wallet transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: ListView(
            padding: EdgeInsets.fromLTRB(XmLayout.horizontalPad(context), 12, XmLayout.horizontalPad(context), 28),
            children: [
              _ProviderHero(provider: widget.provider, brand: brand, country: widget.receiver.countryName),
              const SizedBox(height: 20),
              _SummaryCard(
                send: widget.sendAmount,
                receive: receive,
                fee: fee,
                total: total,
                senderCurrency: widget.senderCurrency,
                targetCurrency: widget.receiver.currencyCode,
                fmt: fmt,
              ),
              const SizedBox(height: 20),
              Text(_fieldLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              TextField(
                controller: _account,
                keyboardType: _field == WalletDeliveryField.upiId ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _hintForField(),
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Funds will be delivered to the selected ${widget.provider.name} account.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _account.text.trim().length >= 5
                      ? () => showXmSnack(context, 'Wallet transfer to ${widget.provider.name} — review next')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: XmoneyTheme.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hintForField() {
    switch (_field) {
      case WalletDeliveryField.upiId:
        return 'name@upi';
      case WalletDeliveryField.accountId:
        return 'Enter wallet ID';
      case WalletDeliveryField.mobile:
        return '03XX XXXXXXX';
    }
  }
}

class _ProviderHero extends StatelessWidget {
  const _ProviderHero({required this.provider, required this.brand, required this.country});

  final WalletProvider provider;
  final Color brand;
  final String country;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              provider.name.isNotEmpty ? provider.name[0] : 'W',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: brand),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: XmoneyTheme.navyDeep)),
                Text(provider.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Destination · $country', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: brand)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.send,
    required this.receive,
    required this.fee,
    required this.total,
    required this.senderCurrency,
    required this.targetCurrency,
    required this.fmt,
  });

  final double send;
  final double receive;
  final double fee;
  final double total;
  final String senderCurrency;
  final String targetCurrency;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Text(
                value,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 15 : 13,
                  color: XmoneyTheme.navyDeep,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          row('You send', '$senderCurrency ${fmt.format(send)}'),
          row('They receive', '$targetCurrency ${fmt.format(receive)}'),
          row('Fee', '$senderCurrency ${fmt.format(fee)}'),
          const Divider(height: 20),
          row('Total debit', '$senderCurrency ${fmt.format(total)}', bold: true),
        ],
      ),
    );
  }
}
