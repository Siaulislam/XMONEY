import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../home/home_screen.dart';
import '../wallet/wallet_screen.dart';
import '../transfer/transfer_screen.dart';
import '../transactions/transactions_screen.dart';
import '../more/more_screen.dart';
import '../../core/theme/xmoney_theme.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.router, this.initialIndex = 0});

  final AppRouter router;
  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index = widget.initialIndex;

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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'Send'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
        onDestinationSelected: _goTab,
      ),
    );
  }
}
