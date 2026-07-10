import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/widgets/xm_action_buttons.dart';
import '../../core/widgets/xm_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.router, this.onSend, this.onTopUp});

  final AppRouter router;
  final VoidCallback? onSend;
  final VoidCallback? onTopUp;

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
    // DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION — demo data for web UI preview
    if (widget.router.api.previewBypassAuth) {
      if (!mounted) return;
      setState(() {
        _analytics = {
          'wallets': [
            {'available_balance': 12450.75, 'currency_code': 'AED'},
          ],
        };
        _recent = [
          {
            'uuid': 'preview-1',
            'reference_code': 'XM-2026-001',
            'receiver_name': 'Ahmed Khan',
            'status': 'completed',
          },
          {
            'uuid': 'preview-2',
            'reference_code': 'XM-2026-002',
            'receiver_name': 'Fatima Ali',
            'status': 'processing',
          },
        ];
        _loading = false;
      });
      return;
    }

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

  void _open(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    final wallets = (_analytics?['wallets'] as List?) ?? [];
    final w = wallets.isNotEmpty ? wallets.first as Map<String, dynamic> : null;
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final balance = w != null ? '${fmt.format(w['available_balance'])} ${w['currency_code']}' : '—';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('XMONEY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _open(AppRouter.notifications),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  XmWalletHeroCard(
                    balanceLabel: 'Available balance',
                    balanceText: balance,
                    secondaryLabel: 'Verify account',
                    onSecondary: () => _open(AppRouter.kyc),
                    onAddMoney: widget.onTopUp ?? () {},
                  ),
                  const SizedBox(height: 20),
                  XmPrimaryActionRow(
                    children: [
                      XmPrimaryActionButton(
                        label: 'Send money',
                        icon: Icons.near_me_outlined,
                        accent: XmoneyTheme.blue,
                        onTap: widget.onSend ?? () {},
                      ),
                      XmPrimaryActionButton(
                        label: 'Beneficiaries',
                        icon: Icons.people_outline,
                        accent: XmoneyTheme.teal,
                        onTap: () => _open(AppRouter.beneficiaries),
                      ),
                      XmPrimaryActionButton(
                        label: 'History',
                        icon: Icons.receipt_long_outlined,
                        accent: const Color(0xFF5B6B7C),
                        onTap: () => _open(AppRouter.transactions),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  XmPrimaryActionRow(
                    children: [
                      XmPrimaryActionButton(
                        label: 'Exchange',
                        icon: Icons.currency_exchange,
                        accent: XmoneyTheme.gold,
                        onTap: widget.onSend ?? () {},
                      ),
                      XmPrimaryActionButton(
                        label: 'Top up',
                        icon: Icons.add_card_outlined,
                        accent: const Color(0xFF2E7D6B),
                        onTap: widget.onTopUp ?? () {},
                      ),
                      XmPrimaryActionButton(
                        label: 'Support',
                        icon: Icons.headset_mic_outlined,
                        accent: const Color(0xFF6B5B95),
                        onTap: () => showXmSnack(context, 'Support chat coming soon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  XmSectionCard(
                    title: 'More with XMONEY',
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 0.82,
                      children: [
                        XmServiceTile(label: 'Profile', icon: Icons.person_outline, onTap: () => _open(AppRouter.profile)),
                        XmServiceTile(label: 'KYC', icon: Icons.verified_user_outlined, accent: XmoneyTheme.teal, onTap: () => _open(AppRouter.kyc)),
                        XmServiceTile(label: 'Security', icon: Icons.shield_outlined, onTap: () => _open(AppRouter.security)),
                        XmServiceTile(label: 'Settings', icon: Icons.settings_outlined, onTap: () => _open(AppRouter.settings)),
                        XmServiceTile(label: 'Wallet', icon: Icons.account_balance_wallet_outlined, onTap: widget.onTopUp ?? () {}),
                        XmServiceTile(label: 'Alerts', icon: Icons.notifications_outlined, onTap: () => _open(AppRouter.notifications)),
                        XmServiceTile(label: 'Send', icon: Icons.send_outlined, accent: XmoneyTheme.blue, onTap: widget.onSend ?? () {}),
                        XmServiceTile(label: 'More', icon: Icons.apps_outlined, onTap: () => _open(AppRouter.settings)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recent transfers',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : XmoneyTheme.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transfers yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ..._recent.map((t) {
                      final m = t as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: XmoneyTheme.teal.withOpacity(0.12),
                            child: const Icon(Icons.swap_horiz, color: XmoneyTheme.teal, size: 20),
                          ),
                          title: Text(
                            m['reference_code'] as String? ?? 'Transfer',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(m['receiver_name'] as String? ?? ''),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: XmoneyTheme.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m['status'] as String? ?? '',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: XmoneyTheme.teal),
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.transactionDetail,
                            arguments: {'uuid': m['uuid']},
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
