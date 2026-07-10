import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/transfer/country_currency_option.dart';
import '../../core/transfer/country_repository.dart';
import '../../core/transfer/exchange_rate_controller.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/widgets/currency_selector.dart';
import '../../core/widgets/xm_ui.dart';

class InternationalTransferScreen extends StatefulWidget {
  const InternationalTransferScreen({super.key, required this.router});

  final AppRouter router;

  @override
  State<InternationalTransferScreen> createState() => _InternationalTransferScreenState();
}

class _InternationalTransferScreenState extends State<InternationalTransferScreen> {
  final _repo = CountryRepository.instance;
  late final ExchangeRateController _rates;
  final _sendAmount = TextEditingController(text: '100');

  CountryCurrencyOption? _sender;
  CountryCurrencyOption? _receiver;
  List<Map<String, dynamic>> _wallets = [];
  String? _walletId;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _rates = ExchangeRateController(widget.router.api)..addListener(_onRates);
    _boot();
    _sendAmount.addListener(_onAmountChanged);
  }

  Future<void> _boot() async {
    await _repo.ensureLoaded();
    _sender = _repo.defaultForCountry('AE') ??
        _repo.tryFindById('AE_AED') ??
        (_repo.all.isNotEmpty ? _repo.all.first : null);
    _receiver = _repo.defaultForCountry('PK') ??
        _repo.tryFindById('PK_PKR');

    final res = await widget.router.api.get('/v1/wallets');
    final data = (res['data'] as List?) ?? [];
    _wallets = data.cast<Map<String, dynamic>>();
    if (_wallets.isEmpty && widget.router.api.previewBypassAuth) {
      _wallets = _previewWallets();
    }
    if (_wallets.isNotEmpty) {
      _walletId = _wallets.first['uuid'] as String? ?? _wallets.first['id']?.toString();
    }

    if (mounted) {
      setState(() => _booting = false);
      _refreshQuote();
    }
  }

  List<Map<String, dynamic>> _previewWallets() => [
        {'uuid': 'primary', 'label': 'Primary Wallet', 'currency_code': 'AED', 'available_balance': 12500},
        {'uuid': 'usd', 'label': 'USD Wallet', 'currency_code': 'USD', 'available_balance': 3200},
        {'uuid': 'aed', 'label': 'AED Wallet', 'currency_code': 'AED', 'available_balance': 8500},
        {'uuid': 'eur', 'label': 'EUR Wallet', 'currency_code': 'EUR', 'available_balance': 2100},
      ];

  void _onRates() => setState(() {});

  void _onAmountChanged() => _refreshQuote();

  void _refreshQuote() {
    final sender = _sender;
    final receiver = _receiver;
    if (sender == null || receiver == null) return;
    final amount = double.tryParse(_sendAmount.text.replaceAll(',', '')) ?? 0;
    _rates.refresh(
      sourceCurrency: sender.currencyCode,
      targetCurrency: receiver.currencyCode,
      sendAmount: amount,
      destinationCountry: receiver.countryCode,
    );
  }

  Future<void> _pickSender() async {
    final picked = await CurrencySelector.pick(
      context,
      title: 'Your country & currency',
      selectedId: _sender?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _sender = picked);
    _refreshQuote();
  }

  Future<void> _pickReceiver() async {
    final picked = await CurrencySelector.pick(
      context,
      title: "Beneficiary's country & currency",
      selectedId: _receiver?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _receiver = picked);
    _refreshQuote();
  }

  @override
  void dispose() {
    _sendAmount.removeListener(_onAmountChanged);
    _sendAmount.dispose();
    _rates.removeListener(_onRates);
    _rates.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final quote = _rates.quote;
    final send = double.tryParse(_sendAmount.text.replaceAll(',', '')) ?? 0;
    final fee = (quote?['fee_amount'] as num?)?.toDouble() ?? 0;
    final receive = (quote?['receive_amount'] as num?)?.toDouble() ?? 0;
    final rate = (quote?['customer_rate'] as num?)?.toDouble();
    final total = (quote?['total_debit'] as num?)?.toDouble() ?? send + fee;
    final maxW = XmLayout.maxContentWidth(context);

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
        title: const Text(
          'International Transfer',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: XmoneyTheme.navyDeep),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showXmSnack(context, 'Help centre coming soon'),
            icon: Icon(Icons.help_outline_rounded, color: Colors.grey.shade600),
          ),
        ],
      ),
      body: _booting
          ? const Center(child: CircularProgressIndicator(color: XmoneyTheme.teal))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    XmLayout.horizontalPad(context),
                    8,
                    XmLayout.horizontalPad(context),
                    28,
                  ),
                  children: [
                    if (_sender != null)
                      CurrencySelector(
                        label: 'You send',
                        option: _sender!,
                        amountText: fmt.format(send),
                        feeLabel: _sender != null ? 'Fee: ${_sender!.currencyCode} ${fmt.format(fee)}' : null,
                        showFeeBadge: fee > 0,
                        onTap: _pickSender,
                      ),
                    const SizedBox(height: 8),
                    _ExchangeRateBand(
                      loading: _rates.loading,
                      rate: rate,
                      source: _sender?.currencyCode ?? '',
                      target: _receiver?.currencyCode ?? '',
                    ),
                    const SizedBox(height: 8),
                    if (_receiver != null)
                      CurrencySelector(
                        label: 'They receive',
                        option: _receiver!,
                        amountText: fmt.format(receive),
                        amountColor: const Color(0xFF0D9488),
                        onTap: _pickReceiver,
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Amount to send',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sendAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: '${_sender?.currencyCode ?? ''} ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _WalletPicker(
                      wallets: _wallets,
                      selectedId: _walletId,
                      onChanged: (id) => setState(() => _walletId = id),
                    ),
                    const SizedBox(height: 16),
                    _ReceiverCard(onTap: () => showXmSnack(context, 'Select receiver — coming next')),
                    const SizedBox(height: 16),
                    _SecureBanner(),
                    if (_rates.error != null) ...[
                      const SizedBox(height: 12),
                      Text(_rates.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: send > 0 && _receiver != null
                            ? () => showXmSnack(context, 'Total debit: ${_sender?.currencyCode} ${fmt.format(total)}')
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: XmoneyTheme.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _TrustRow(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ExchangeRateBand extends StatelessWidget {
  const _ExchangeRateBand({
    required this.loading,
    required this.rate,
    required this.source,
    required this.target,
  });

  final bool loading;
  final double? rate;
  final String source;
  final String target;

  @override
  Widget build(BuildContext context) {
    final rateText = rate != null ? '1 $source = ${rate!.toStringAsFixed(4)} $target' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: XmoneyTheme.blue,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: XmoneyTheme.blue.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.south_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exchange rate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  Text(rateText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPicker extends StatelessWidget {
  const _WalletPicker({required this.wallets, required this.selectedId, required this.onChanged});

  final List<Map<String, dynamic>> wallets;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay from wallet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: wallets.any((w) => (w['uuid'] ?? w['id']) == selectedId) ? selectedId : null,
              hint: const Text('Select wallet'),
              items: wallets.map((w) {
                final id = w['uuid'] as String? ?? w['id']?.toString() ?? '';
                final label = w['label'] as String? ?? w['name'] as String? ?? 'Wallet';
                final cur = w['currency_code'] as String? ?? '';
                return DropdownMenuItem(value: id, child: Text('$label · $cur'));
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiverCard extends StatelessWidget {
  const _ReceiverCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: XmoneyTheme.teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: XmoneyTheme.teal),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select receiver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep)),
                    SizedBox(height: 2),
                    Text('Bank, account or mobile wallet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecureBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: XmoneyTheme.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: XmoneyTheme.blue.withOpacity(0.9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your money is safe and secure', style: TextStyle(fontWeight: FontWeight.w700, color: XmoneyTheme.blue.withOpacity(0.95))),
                Text('All transfers are encrypted and protected.', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String sub) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: XmoneyTheme.blue, size: 22),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        );

    return Row(
      children: [
        item(Icons.bolt_rounded, 'Instant Transfer', 'in minutes'),
        item(Icons.verified_user_outlined, 'Secure & Trusted', '100% protected'),
        item(Icons.support_agent_rounded, '24/7 Support', "We're here"),
      ],
    );
  }
}

/// Responsive layout helpers for transfer screen.
class XmLayout {
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return 560;
    if (w >= 800) return 520;
    return double.infinity;
  }

  static double horizontalPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 800) return 32;
    if (w >= 600) return 24;
    return 18;
  }
}
