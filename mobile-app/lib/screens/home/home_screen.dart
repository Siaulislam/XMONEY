import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/theme/xmoney_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _analytics;
  List<dynamic> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.router.api.get('/v1/analytics/summary'),
      widget.router.api.get('/v1/transfers?limit=5'),
    ]);
    if (!mounted) return;
    setState(() {
      _analytics = results[0]['data'] as Map<String, dynamic>?;
      final tx = results[1]['data'];
      _recent = tx is List ? tx : (tx is Map ? (tx['rows'] as List? ?? []) : []);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallets = (_analytics?['wallets'] as List?) ?? [];
    final w = wallets.isNotEmpty ? wallets.first as Map<String, dynamic> : null;
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('XMONEY'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.pushNamed(context, AppRouter.profile)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [XmoneyTheme.navyDeep, XmoneyTheme.blue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          w != null ? '${fmt.format(w['available_balance'])} ${w['currency_code']}' : '—',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRouter.transfer), child: const Text('Send'))),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                              onPressed: () => Navigator.pushNamed(context, AppRouter.wallet),
                              child: const Text('Top up'),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _quickNav(context, Icons.account_balance_wallet, 'Wallet', AppRouter.wallet),
                      _quickNav(context, Icons.swap_horiz, 'Transfers', AppRouter.transactions),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Recent transfers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._recent.map((t) {
                    final m = t as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(m['reference_code'] as String? ?? ''),
                        subtitle: Text(m['receiver_name'] as String? ?? ''),
                        trailing: Text(m['status'] as String? ?? ''),
                      ),
                    );
                  }),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Send'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        ],
        onDestinationSelected: (i) {
          final routes = [AppRouter.home, AppRouter.transfer, AppRouter.transactions, AppRouter.wallet];
          if (i != 0) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }

  Widget _quickNav(BuildContext context, IconData icon, String label, String route) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [Icon(icon, color: XmoneyTheme.teal), const SizedBox(height: 8), Text(label)]),
          ),
        ),
      ),
    );
  }
}
