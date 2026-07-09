import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/responsive/xm_breakpoints.dart';
import '../../core/theme/xmoney_theme.dart';
import '../home/home_screen.dart';
import '../wallet/wallet_screen.dart';
import '../transfer/transfer_screen.dart';
import '../transactions/transactions_screen.dart';
import '../more/more_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.router, this.initialIndex = 0});

  final AppRouter router;
  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index = widget.initialIndex;
  final _s = XmStrings.instance;

  void _goTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(router: widget.router, onSend: () => _goTab(1), onTopUp: () => _goTab(3)),
      TransferScreen(router: widget.router),
      TransactionsScreen(router: widget.router),
      WalletScreen(router: widget.router),
      MoreScreen(router: widget.router),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: XmoneyTheme.navyDeep,
        indicatorColor: XmoneyTheme.gold.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: _s.t('nav.home', 'Home')),
          NavigationDestination(icon: const Icon(Icons.send_outlined), selectedIcon: const Icon(Icons.send), label: _s.t('nav.send', 'Send')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: _s.t('nav.history', 'History')),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: _s.t('nav.wallet', 'Wallet')),
          NavigationDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more_horiz), label: _s.t('nav.more', 'More')),
        ],
        onDestinationSelected: _goTab,
      ),
    );
  }
}
