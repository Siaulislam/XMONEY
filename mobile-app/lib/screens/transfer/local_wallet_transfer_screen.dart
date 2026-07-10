import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/responsive/xm_layout.dart';
import '../../core/theme/xmoney_theme.dart';
import 'local_transfer_shared.dart';
import '../../core/wallets/country_wallet_mapping.dart';
import '../../core/wallets/wallet_provider.dart';
import '../../core/wallets/wallet_repository.dart';
import '../../core/widgets/wallet_selector.dart';
import '../../core/widgets/xm_ui.dart';

/// Local digital wallet transfer in the customer's registered country.
class LocalWalletTransferScreen extends StatefulWidget {
  const LocalWalletTransferScreen({super.key, required this.router});

  final AppRouter router;

  @override
  State<LocalWalletTransferScreen> createState() => _LocalWalletTransferScreenState();
}

class _LocalWalletTransferScreenState extends State<LocalWalletTransferScreen> {
  final _amount = TextEditingController(text: '500');
  late final WalletRepository _walletRepo;

  LocalTransferCountryContext? _country;
  CountryWalletMapping? _wallets;
  WalletProvider? _selectedWallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _walletRepo = WalletRepository(widget.router.api);
    _boot();
  }

  Future<void> _boot() async {
    final country = await resolveLocalTransferCountry(widget.router);
    final wallets = await _walletRepo.forCountry(country.countryCode);
    if (!mounted) return;
    setState(() {
      _country = country;
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
    final country = _country;
    final currencyCode = country?.currency?.currencyCode;

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
        title: const Text('Local Wallet Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: _loading || country == null
          ? const Center(child: CircularProgressIndicator(color: XmoneyTheme.teal))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: XmLayout.maxContentWidth(context)),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(XmLayout.horizontalPad(context), 12, XmLayout.horizontalPad(context), 28),
                  children: [
                    LocalTransferCountryBanner(
                      countryCode: country.countryCode,
                      countryName: country.countryName,
                      currencyCode: currencyCode,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: XmoneyTheme.listRowText, fontWeight: FontWeight.w600),
                      cursorColor: XmoneyTheme.teal,
                      decoration: InputDecoration(
                        labelText: currencyCode != null ? 'Amount ($currencyCode)' : 'Amount',
                        labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Local digital wallets',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: XmoneyTheme.listRowText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wallets available in ${country.countryName}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    _walletsList(country.countryName),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _selectedWallet != null
                          ? () => showXmSnack(context, 'Local wallet transfer review — coming next')
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

  Widget _walletsList(String countryName) {
    final mapping = _wallets;
    if (mapping == null || !mapping.hasWallets) {
      return Text(
        'No local wallets configured for $countryName yet.',
        style: const TextStyle(color: XmoneyTheme.listRowText, fontWeight: FontWeight.w600),
      );
    }
    return WalletSelector(
      mapping: mapping,
      repository: _walletRepo,
      selected: _selectedWallet,
      onSelected: (p) => setState(() => _selectedWallet = p),
    );
  }
}
