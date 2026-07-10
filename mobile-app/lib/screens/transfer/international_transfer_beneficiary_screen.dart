import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/beneficiaries/beneficiary.dart';
import '../../core/beneficiaries/beneficiary_repository.dart';
import '../../core/responsive/xm_layout.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/transfer/international_transfer_context.dart';
import '../../core/transfer/transfer_delivery_type.dart';
import '../../core/transfer/transfer_repository.dart';
import '../../core/widgets/new_beneficiary_wizard.dart';
import '../../core/widgets/saved_beneficiary_card.dart';
import '../../core/widgets/xm_segmented_tabs.dart';
import '../../core/widgets/pay_from_wallet_picker.dart';
import '../../core/widgets/xm_ui.dart';

/// Beneficiary selection / creation step for international transfers.
class InternationalTransferBeneficiaryScreen extends StatefulWidget {
  const InternationalTransferBeneficiaryScreen({
    super.key,
    required this.router,
    required this.transferContext,
  });

  final AppRouter router;
  final InternationalTransferContext transferContext;

  @override
  State<InternationalTransferBeneficiaryScreen> createState() => _InternationalTransferBeneficiaryScreenState();
}

class _InternationalTransferBeneficiaryScreenState extends State<InternationalTransferBeneficiaryScreen> {
  int _tab = 0;
  final _search = TextEditingController();
  List<Beneficiary> _all = [];
  bool _loading = true;
  bool _submitting = false;
  late final BeneficiaryRepository _benRepo;
  late final TransferRepository _transferRepo;

  @override
  void initState() {
    super.initState();
    _benRepo = BeneficiaryRepository(widget.router.api);
    _transferRepo = TransferRepository(widget.router.api);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ctx = widget.transferContext;
    final method = ctx.isWallet ? TransferDeliveryType.wallet : TransferDeliveryType.bank;
    final list = await _benRepo.list(
      countryCode: ctx.receiver.countryCode,
      currencyCode: ctx.receiver.currencyCode,
      deliveryMethod: method,
    );
    if (mounted) setState(() { _all = list; _loading = false; });
  }

  List<Beneficiary> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = List<Beneficiary>.from(_all);
    list.sort((a, b) {
      if (a.isFavourite != b.isFavourite) return a.isFavourite ? -1 : 1;
      final al = a.lastUsedAt, bl = b.lastUsedAt;
      if (al != null && bl != null) return bl.compareTo(al);
      return 0;
    });
    if (q.isEmpty) return list;
    return list.where((b) {
      return b.displayName.toLowerCase().contains(q) ||
          b.receiverName.toLowerCase().contains(q) ||
          (b.bankName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<Beneficiary> get _favourites => _filtered.where((b) => b.isFavourite).toList();
  List<Beneficiary> get _recent => _filtered.where((b) => !b.isFavourite).take(8).toList();

  Future<void> _transferWith(Beneficiary b) async {
    final walletId = await _pickPayFromWallet();
    if (!mounted || walletId == null) return;

    setState(() => _submitting = true);
    await _benRepo.touchLastUsed(b.uuid);
    final ok = await _executeTransfer(b.uuid, payFromWalletId: walletId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      showXmSnack(context, 'Transfer submitted successfully');
      Navigator.popUntil(context, (r) => r.isFirst);
    } else if (widget.router.api.previewBypassAuth) {
      showXmSnack(context, 'Preview: transfer flow completed for ${b.displayName}');
      Navigator.pop(context);
    } else {
      showXmSnack(context, 'Transfer failed — check balance and try again', error: true);
    }
  }

  Future<String?> _pickPayFromWallet() async {
    final wallets = widget.transferContext.senderWallets;
    if (wallets.isEmpty) return widget.transferContext.payFromWalletId;

    var selected = widget.transferContext.payFromWalletId ??
        wallets.first['uuid'] as String? ??
        wallets.first['id']?.toString();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Confirm transfer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep)),
                  const SizedBox(height: 16),
                  PayFromWalletPicker(
                    wallets: wallets,
                    selectedId: selected,
                    onChanged: (id) => setLocal(() => selected = id),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
                    style: FilledButton.styleFrom(backgroundColor: XmoneyTheme.blue, minimumSize: const Size(double.infinity, 52)),
                    child: const Text('Confirm & pay from wallet', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _executeTransfer(String beneficiaryUuid, {String? payFromWalletId}) async {
    final ctx = widget.transferContext;
    final uuid = await _transferRepo.createTransfer(
      beneficiaryUuid: beneficiaryUuid,
      sendAmount: ctx.sendAmount,
      sourceCurrency: ctx.sender.currencyCode,
    );
    if (uuid == null) return widget.router.api.previewBypassAuth;
    return _transferRepo.confirmTransfer(uuid);
  }

  Future<void> _onNewBeneficiary(Map<String, dynamic> draft, bool save) async {
    setState(() => _submitting = true);
    Beneficiary? ben;
    if (save) {
      final b = Beneficiary(
        uuid: '',
        receiverName: draft['receiver_name'] as String,
        nickname: (draft['nickname'] as String?)?.isEmpty == true ? null : draft['nickname'] as String?,
        countryCode: draft['country_code'] as String,
        currencyCode: draft['currency_code'] as String,
        deliveryMethod: TransferDeliveryType.fromString(draft['delivery_method'] as String?),
        walletProviderCode: draft['wallet_provider_code'] as String?,
        walletProviderName: draft['wallet_provider_name'] as String?,
        bankName: draft['bank_name'] as String?,
        branchName: draft['branch_name'] as String?,
        accountNumber: (draft['account_number'] as String?)?.isNotEmpty == true
            ? draft['account_number'] as String
            : draft['wallet_number'] as String?,
        iban: draft['iban'] as String?,
        swiftBic: draft['swift_bic'] as String?,
        mobileNumber: draft['mobile_number'] as String?,
        email: draft['email'] as String?,
        addressLine: draft['address_line'] as String?,
        receiverCity: draft['receiver_city'] as String?,
        receiverState: draft['receiver_state'] as String?,
        postalCode: draft['postal_code'] as String?,
        nationalId: draft['national_id'] as String?,
        purposeOfTransfer: draft['purpose_of_transfer'] as String?,
        relationship: draft['relationship'] as String?,
        isFavourite: false,
      );
      ben = await _benRepo.create(b);
    }
    if (!mounted) return;
    if (ben != null) {
      await _transferWith(ben);
      return;
    }
    if (widget.router.api.previewBypassAuth) {
      setState(() => _submitting = false);
      showXmSnack(context, 'Preview: beneficiary saved & transfer simulated');
      Navigator.pop(context);
      return;
    }
    setState(() => _submitting = false);
    showXmSnack(context, 'Could not save beneficiary', error: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.transferContext;
    final fmt = NumberFormat('#,##0.00');
    final receive = (ctx.quote?['receive_amount'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: XmoneyTheme.navyDeep,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(
          ctx.isWallet ? 'International Wallet Transfer' : 'International Bank Transfer',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: XmoneyTheme.teal))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: XmLayout.maxContentWidth(context)),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(XmLayout.horizontalPad(context), 8, XmLayout.horizontalPad(context), 24),
                  children: [
                    _SummaryStrip(
                      send: '${ctx.sender.currencyCode} ${fmt.format(ctx.sendAmount)}',
                      receive: '${ctx.receiver.currencyCode} ${fmt.format(receive)}',
                      method: ctx.isWallet
                          ? 'Wallet · ${ctx.walletProvider?.name ?? ''}'
                          : 'Bank · ${ctx.selectedBank?.name ?? 'Transfer'}',
                    ),
                    const SizedBox(height: 20),
                    XmSegmentedTabs(
                      labels: const ['Sender History', 'New Beneficiary'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _tab == 0 ? _savedTab() : _newTab(ctx),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _savedTab() {
    if (_loading) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    return Column(
      key: const ValueKey('saved'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search beneficiaries',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF3F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        if (_favourites.isNotEmpty) ...[
          Text('Favourites', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          ..._favourites.map((b) => _card(b)),
        ],
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Recent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          ..._recent.map((b) => _card(b)),
        ],
        if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No saved beneficiaries for this corridor yet.\nSwitch to New Beneficiary to add one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ),
      ],
    );
  }

  Widget _card(Beneficiary b) => SavedBeneficiaryCard(
        beneficiary: b,
        onTransfer: () => _transferWith(b),
        onEdit: () => showXmSnack(context, 'Edit coming soon'),
        onDelete: () async {
          await _benRepo.delete(b.uuid);
          await _load();
        },
        onFavourite: () async {
          await _benRepo.update(b.uuid, {'is_favourite': !b.isFavourite});
          await _load();
        },
      );

  Widget _newTab(InternationalTransferContext ctx) {
    return NewBeneficiaryWizard(
      key: const ValueKey('new'),
      api: widget.router.api,
      initialCountry: ctx.receiver,
      initialCurrency: ctx.receiver.currencyCode,
      deliveryMethod: ctx.isWallet ? TransferDeliveryType.wallet : TransferDeliveryType.bank,
      walletProvider: ctx.walletProvider,
      initialBankName: ctx.selectedBank?.name,
      senderWallets: ctx.senderWallets,
      initialPayFromWalletId: ctx.payFromWalletId,
      onSubmit: _onNewBeneficiary,
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.send, required this.receive, required this.method});
  final String send;
  final String receive;
  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [XmoneyTheme.navyDeep.withOpacity(0.95), XmoneyTheme.blue.withOpacity(0.88)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: XmoneyTheme.navyDeep.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You send $send', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('They receive $receive', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(method, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
