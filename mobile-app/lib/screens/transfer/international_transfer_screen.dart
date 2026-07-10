import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/transfer/country_currency_option.dart';
import '../../core/transfer/country_repository.dart';
import '../../core/transfer/exchange_rate_controller.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/widgets/currency_selector.dart';
import '../../core/responsive/xm_layout.dart';
import '../../core/widgets/xm_ui.dart';
import '../../core/wallets/country_wallet_mapping.dart';
import '../../core/wallets/wallet_provider.dart';
import '../../core/wallets/wallet_repository.dart';
import '../../core/widgets/wallet_selector.dart';
import '../../core/transfer/local_transfer_repository.dart';
import '../../core/widgets/bank_selector.dart';
import '../../core/transfer/international_transfer_context.dart';
import '../../core/transfer/transfer_delivery_type.dart';
import '../../core/transfer/international_transfer_mode.dart';
import 'international_transfer_beneficiary_screen.dart';

class InternationalTransferScreen extends StatefulWidget {
  const InternationalTransferScreen({
    super.key,
    required this.router,
    required this.mode,
  });

  final AppRouter router;
  final InternationalTransferMode mode;

  bool get isWallet => mode == InternationalTransferMode.wallet;
  bool get isBank => mode == InternationalTransferMode.bank;

  @override
  State<InternationalTransferScreen> createState() => _InternationalTransferScreenState();
}

class _InternationalTransferScreenState extends State<InternationalTransferScreen> {
  final _repo = CountryRepository.instance;
  late final WalletRepository _walletRepo;
  late final ExchangeRateController _rates;
  final _sendAmount = TextEditingController(text: '100');

  CountryCurrencyOption? _sender;
  CountryCurrencyOption? _receiver;
  CountryWalletMapping? _destinationWallets;
  WalletProvider? _selectedProvider;
  List<LocalBank> _destinationBanks = [];
  LocalBank? _selectedBank;
  List<Map<String, dynamic>> _wallets = [];
  String? _walletId;
  bool _booting = true;
  bool _loadingWallets = false;
  bool _loadingBanks = false;

  @override
  void initState() {
    super.initState();
    _rates = ExchangeRateController(widget.router.api)..addListener(_onRates);
    _walletRepo = WalletRepository(widget.router.api);
    _boot();
    _sendAmount.addListener(_onAmountChanged);
  }

  Future<void> _boot() async {
    try {
      await _repo.ensureLoaded();
      _sender = _repo.defaultForCountry('AE') ??
          _repo.tryFindById('AE_AED') ??
          (_repo.all.isNotEmpty ? _repo.all.first : null);
      _receiver = _repo.defaultForCountry('PK') ??
          _repo.tryFindById('PK_PKR');

      if (widget.router.api.previewBypassAuth) {
        _wallets = _previewWallets();
      } else {
        final res = await widget.router.api.get('/v1/wallets');
        final data = (res['data'] as List?) ?? [];
        _wallets = data.cast<Map<String, dynamic>>();
      }
      if (_wallets.isNotEmpty) {
        _walletId = _wallets.first['uuid'] as String? ?? _wallets.first['id']?.toString();
      }
    } catch (_) {
      if (widget.router.api.previewBypassAuth) {
        _wallets = _previewWallets();
        _walletId = _wallets.first['uuid'] as String?;
      }
    } finally {
      if (mounted) {
        setState(() => _booting = false);
        if (widget.isWallet) {
          _loadDestinationWallets();
        } else {
          _loadDestinationBanks();
        }
        _refreshQuote();
      }
    }
  }

  Future<void> _loadDestinationWallets() async {
    final receiver = _receiver;
    if (receiver == null) return;
    setState(() => _loadingWallets = true);
    final mapping = await _walletRepo.forCountry(receiver.countryCode);
    if (!mounted) return;
    setState(() {
      _destinationWallets = mapping;
      _loadingWallets = false;
      if (_selectedProvider != null &&
          !mapping.providers.any((p) => p.code == _selectedProvider!.code)) {
        _selectedProvider = null;
      }
    });
  }

  Future<void> _loadDestinationBanks() async {
    final receiver = _receiver;
    if (receiver == null) return;
    setState(() => _loadingBanks = true);
    await CountryBankRepository.instance.ensureLoaded();
    final banks = CountryBankRepository.instance.banksForCountry(receiver.countryCode);
    if (!mounted) return;
    setState(() {
      _destinationBanks = banks;
      _loadingBanks = false;
      if (_selectedBank != null && !banks.any((b) => b.code == _selectedBank!.code)) {
        _selectedBank = null;
      }
    });
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
    if (widget.isWallet) {
      await _loadDestinationWallets();
    } else {
      await _loadDestinationBanks();
    }
    _refreshQuote();
  }

  bool _canContinue(double send) {
    if (send <= 0 || _sender == null || _receiver == null) return false;
    if (widget.isWallet) {
      return (_destinationWallets?.hasWallets ?? false) && _selectedProvider != null;
    }
    return _destinationBanks.isNotEmpty && _selectedBank != null;
  }

  Future<void> _openBeneficiaryFlow() async {
    final sender = _sender;
    final receiver = _receiver;
    if (sender == null || receiver == null) return;
    final send = double.tryParse(_sendAmount.text.replaceAll(',', '')) ?? 0;
    final ctx = InternationalTransferContext(
      sender: sender,
      receiver: receiver,
      sendAmount: send,
      quote: _rates.quote,
      payFromWalletId: _walletId,
      senderWallets: _wallets,
      deliveryMethod: widget.isWallet ? TransferDeliveryType.wallet : TransferDeliveryType.bank,
      walletProvider: widget.isWallet ? _selectedProvider : null,
      selectedBank: widget.isBank ? _selectedBank : null,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InternationalTransferBeneficiaryScreen(router: widget.router, transferContext: ctx),
      ),
    );
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
        title: Text(
          widget.mode.screenTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: XmoneyTheme.navyDeep),
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
                        amountController: _sendAmount,
                        onAmountChanged: (_) => _refreshQuote(),
                        feeLabel: _sender != null ? 'Fee: ${_sender!.currencyCode} ${fmt.format(fee)}' : null,
                        showFeeBadge: fee > 0,
                        onCurrencyTap: _pickSender,
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
                        onCurrencyTap: _pickReceiver,
                      ),
                    const SizedBox(height: 20),
                    if (widget.isWallet) ...[
                      if (_loadingWallets)
                        const LinearProgressIndicator(minHeight: 2, color: XmoneyTheme.teal)
                      else if (_destinationWallets?.hasWallets ?? false)
                        WalletSelector(
                          mapping: _destinationWallets!,
                          repository: _walletRepo,
                          selected: _selectedProvider,
                          onSelected: (p) => setState(() => _selectedProvider = p),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'No wallet providers available for ${_receiver?.countryName ?? 'this country'}.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.isBank) ...[
                      BankSelector(
                        countryName: _receiver?.countryName ?? 'destination country',
                        banks: _destinationBanks,
                        selected: _selectedBank,
                        loading: _loadingBanks,
                        onSelected: (b) => setState(() => _selectedBank = b),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                        onPressed: _canContinue(send)
                            ? _openBeneficiaryFlow
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
