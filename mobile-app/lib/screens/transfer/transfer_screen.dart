import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/widgets/xm_ui.dart';
import '../../core/widgets/send_money_options_sheet.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.router, this.channel});

  final AppRouter router;
  final SendMoneyChannel? channel;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  List<dynamic> _beneficiaries = [];
  List<dynamic> _wallets = [];
  String? _selectedBen;
  String _srcCur = 'AED';
  final _amount = TextEditingController();
  Map<String, dynamic>? _quote;
  bool _loading = true;
  String? _error;
  final _s = XmStrings.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.router.api.get('/v1/beneficiaries'),
      widget.router.api.get('/v1/wallets'),
      widget.router.api.get('/v1/settings/public'),
    ]);
    if (!mounted) return;
    setState(() {
      _beneficiaries = (results[0]['data'] as List?) ?? [];
      _wallets = (results[1]['data'] as List?) ?? [];
      final pub = results[2]['data'] as Map<String, dynamic>?;
      if (pub?['default_source_currency'] != null) {
        _srcCur = pub!['default_source_currency'] as String;
      }
      _loading = false;
    });
  }

  double _available(String currency) {
    final w = _wallets.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['currency_code'] == currency,
      orElse: () => null,
    );
    if (w == null) return 0;
    return (w['available_balance'] as num?)?.toDouble() ?? (w['balance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _fetchQuote() async {
    if (_selectedBen == null) {
      setState(() => _error = _s.t('mobile.transfer.selectBen', 'Select a beneficiary'));
      return;
    }
    final ben = _beneficiaries.cast<Map<String, dynamic>>().firstWhere((b) => b['uuid'] == _selectedBen);
    final res = await widget.router.api.post('/v1/transfers/quote', {
      'source_currency': _srcCur,
      'target_currency': ben['currency_code'],
      'send_amount': double.tryParse(_amount.text) ?? 0,
      'destination_country': ben['country_code'],
    });
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() { _quote = res['data'] as Map<String, dynamic>?; _error = null; });
    } else {
      setState(() => _error = res['message'] as String? ?? _s.t('mobile.transfer.quoteFailed', 'Quote failed'));
    }
  }

  Future<void> _send() async {
    if (_quote == null || _selectedBen == null) return;
    final needed = (_quote!['total_debit'] as num?)?.toDouble() ?? 0;
    if (_available(_srcCur) < needed) {
      showXmSnack(context, _s.t('mobile.transfer.insufficientBalance', 'Insufficient wallet balance'), error: true);
      return;
    }
    final create = await widget.router.api.post('/v1/transfers', {
      'beneficiary_uuid': _selectedBen,
      'send_amount': _quote!['send_amount'],
      'source_currency': _quote!['source_currency'],
      'payment_method': 'wallet',
    });
    if (create['success'] != true) {
      if (!mounted) return;
      showXmSnack(context, create['message'] as String? ?? _s.t('mobile.transfer.transferFailed', 'Transfer failed'), error: true);
      return;
    }
    final uuid = (create['data'] as Map)['uuid'];
    final confirm = await widget.router.api.post('/v1/transfers/$uuid/confirm', {'payment_method': 'wallet'});
    if (!mounted) return;
    if (confirm['success'] == true) {
      showXmSnack(context, _s.t('mobile.transfer.submitted', 'Transfer submitted'));
      _amount.clear();
      setState(() => _quote = null);
      _load();
    } else {
      showXmSnack(context, confirm['message'] as String? ?? _s.t('mobile.transfer.paymentFailed', 'Payment failed'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final channelLabel = _channelTitle(widget.channel);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_s.t('nav.send', 'Send money')),
            if (channelLabel != null)
              Text(
                channelLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: _loading
          ? const XmLoading()
          : SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 375 ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_s.t('mobile.transfer.available', 'Available: {amount} {currency}')
                      .replaceAll('{amount}', fmt.format(_available(_srcCur)))
                      .replaceAll('{currency}', _srcCur)),
                  const SizedBox(height: 12),
                  if (_beneficiaries.isEmpty)
                    Text(_s.t('mobile.transfer.addBenFirst', 'Add a beneficiary first (More -> Beneficiaries).'))
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedBen,
                      decoration: InputDecoration(labelText: _s.t('transfer.beneficiary', 'Beneficiary')),
                      items: _beneficiaries.map((b) {
                        final m = b as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: m['uuid'] as String,
                          child: Text(m['receiver_name'] as String),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedBen = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${_s.t('wallet.amount', 'Amount')} ($_srcCur)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _fetchQuote, child: Text(_s.t('transfer.getQuote', 'Get quote'))),
                    if (_quote != null) ...[
                      const SizedBox(height: 12),
                      Text(_s.t('mobile.transfer.receive', 'Receive: {amount} {currency}')
                          .replaceAll('{amount}', '${_quote!['receive_amount']}')
                          .replaceAll('{currency}', '${_quote!['target_currency']}')),
                      Text(_s.t('mobile.transfer.feeTotal', 'Fee: {fee} · Total: {total} {currency}')
                          .replaceAll('{fee}', '${_quote!['fee_amount']}')
                          .replaceAll('{total}', '${_quote!['total_debit']}')
                          .replaceAll('{currency}', _srcCur)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _send, child: Text(_s.t('mobile.transfer.confirmWallet', 'Confirm & pay from wallet'))),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  String? _channelTitle(SendMoneyChannel? ch) {
    switch (ch) {
      case SendMoneyChannel.international:
        return 'International Transfer';
      case SendMoneyChannel.bank:
        return 'Bank Transfer';
      case SendMoneyChannel.cnic:
        return 'CNIC Transfer';
      case SendMoneyChannel.local:
        return 'Local Transfer';
      case SendMoneyChannel.otherWallets:
        return 'Other Wallets';
      case SendMoneyChannel.scanQr:
        return 'Scan QR';
      case null:
        return null;
    }
  }
}
