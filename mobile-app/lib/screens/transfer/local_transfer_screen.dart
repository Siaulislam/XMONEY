import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/responsive/xm_layout.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/transfer/country_currency_option.dart';
import '../../core/transfer/customer_country_service.dart';
import '../../core/transfer/local_transfer_repository.dart';
import '../../core/wallets/country_wallet_mapping.dart';
import '../../core/wallets/wallet_provider.dart';
import '../../core/wallets/wallet_repository.dart';
import '../../core/widgets/wallet_selector.dart';
import '../../core/widgets/xm_segmented_tabs.dart';
import '../../core/widgets/xm_ui.dart';

/// Local bank + wallet transfers in the customer's registered country.
class LocalTransferScreen extends StatefulWidget {
  const LocalTransferScreen({super.key, required this.router});

  final AppRouter router;

  @override
  State<LocalTransferScreen> createState() => _LocalTransferScreenState();
}

class _LocalTransferScreenState extends State<LocalTransferScreen> {
  final _amount = TextEditingController(text: '500');
  late final WalletRepository _walletRepo;
  late final CustomerCountryService _countryService;

  String _countryCode = '';
  String _countryName = '';
  List<LocalBank> _banks = [];
  CountryWalletMapping? _wallets;
  int _tab = 0;
  LocalBank? _selectedBank;
  WalletProvider? _selectedWallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _walletRepo = WalletRepository(widget.router.api);
    _countryService = CustomerCountryService(widget.router.api);
    _boot();
  }

  Future<void> _boot() async {
    await LocalTransferRepository.instance.ensureLoaded();
    final cc = await _countryService.resolveCountryCode();
    final name = await _countryService.resolveCountryName(cc);
    final banks = LocalTransferRepository.instance.banksForCountry(cc);
    final wallets = await _walletRepo.forCountry(cc);
    if (!mounted) return;
    setState(() {
      _countryCode = cc;
      _countryName = name;
      _banks = banks;
      _wallets = wallets;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Local Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: XmoneyTheme.teal))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: XmLayout.maxContentWidth(context)),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(XmLayout.horizontalPad(context), 12, XmLayout.horizontalPad(context), 28),
                  children: [
                    _CountryBanner(code: _countryCode, name: _countryName),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    XmSegmentedTabs(
                      labels: const ['Local Banks', 'Local Wallets'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _tab == 0 ? _banksList() : _walletsList(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (_tab == 0 && _selectedBank != null) || (_tab == 1 && _selectedWallet != null)
                          ? () => showXmSnack(context, 'Local transfer review — coming next')
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: XmoneyTheme.blue,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _banksList() {
    if (_banks.isEmpty) {
      return Text('No local banks configured for $_countryName yet.', key: const ValueKey('no-banks'));
    }
    return Column(
      key: const ValueKey('banks'),
      children: _banks.map((b) {
        final selected = _selectedBank?.code == b.code;
        Color brand;
        try {
          brand = Color(int.parse('FF${b.brandColor.replaceFirst('#', '')}', radix: 16));
        } catch (_) {
          brand = XmoneyTheme.teal;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => setState(() => _selectedBank = b),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? XmoneyTheme.teal : const Color(0xFFE8ECF3), width: selected ? 1.6 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: brand.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text(b.name[0], style: TextStyle(fontWeight: FontWeight.w800, color: brand)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (selected) const Icon(Icons.check_circle_rounded, color: XmoneyTheme.teal),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _walletsList() {
    final mapping = _wallets;
    if (mapping == null || !mapping.hasWallets) {
      return Text('No local wallets for $_countryName yet.', key: const ValueKey('no-wallets'));
    }
    return WalletSelector(
      key: const ValueKey('wallets'),
      mapping: mapping,
      repository: _walletRepo,
      selected: _selectedWallet,
      onSelected: (p) => setState(() => _selectedWallet = p),
    );
  }
}

class _CountryBanner extends StatelessWidget {
  const _CountryBanner({required this.code, required this.name});

  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          Text(countryFlagEmoji(code), style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your country', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: XmoneyTheme.navyDeep)),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: XmoneyTheme.teal),
        ],
      ),
    );
  }
}
