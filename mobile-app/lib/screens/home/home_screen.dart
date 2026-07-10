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
    if (widget.router.api.previewBypassAuth) {
      if (!mounted) return;
      setState(() {
        _analytics = {
          'wallets': [
            {'available_balance': 12450.75, 'currency_code': 'AED'},
          ],
        };
        _recent = [
          {'uuid': 'preview-1', 'reference_code': 'XM-2026-001', 'receiver_name': 'Ahmed Khan', 'status': 'completed'},
          {'uuid': 'preview-2', 'reference_code': 'XM-2026-002', 'receiver_name': 'Fatima Ali', 'status': 'processing'},
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

  void _soon(String label) => showXmSnack(context, '$label — coming soon');

  List<_ServiceItem> get _moreServices => [
        _ServiceItem('Intl transfer', Icons.public, XmoneyTheme.blue, widget.onSend ?? () {}),
        _ServiceItem('Gold & silver', Icons.trending_up, const Color(0xFFD4A017), () => _soon('Gold & silver')),
        _ServiceItem('Instant loan', Icons.campaign_outlined, XmoneyTheme.blue, () => _soon('Instant loan')),
        _ServiceItem('My cards', Icons.credit_card_outlined, XmoneyTheme.blue, widget.onTopUp ?? () {}),
        _ServiceItem('Bill & recharge', Icons.receipt_long_outlined, const Color(0xFF2E7D6B), () => _soon('Bill & recharge')),
        _ServiceItem('Salary card', Icons.badge_outlined, XmoneyTheme.blue, () => _soon('Salary card')),
        _ServiceItem('Remittance', Icons.currency_exchange, const Color(0xFF2E7D6B), widget.onSend ?? () {}),
        _ServiceItem('Insurance', Icons.health_and_safety_outlined, XmoneyTheme.teal, () => _soon('Insurance')),
        _ServiceItem('Credit score', Icons.speed_outlined, const Color(0xFF6B5B95), () => _soon('Credit score')),
        _ServiceItem('More', Icons.apps, XmoneyTheme.navyDeep, _showAllServices),
      ];

  void _showAllServices() {
    final extra = [
      _ServiceItem('Beneficiaries', Icons.people_outline, XmoneyTheme.teal, () => _open(AppRouter.beneficiaries)),
      _ServiceItem('View statement', Icons.description_outlined, const Color(0xFF5B6B7C), () => _open(AppRouter.transactions)),
      _ServiceItem('Mobile packages', Icons.sim_card_outlined, const Color(0xFF7C5CBF), () => _soon('Mobile packages')),
      _ServiceItem('Scan & pay', Icons.qr_code_scanner, XmoneyTheme.blue, () => _soon('Scan & pay')),
      _ServiceItem('Profile', Icons.person_outline, XmoneyTheme.navyDeep, () => _open(AppRouter.profile)),
      _ServiceItem('KYC', Icons.verified_user_outlined, XmoneyTheme.teal, () => _open(AppRouter.kyc)),
      _ServiceItem('Security', Icons.shield_outlined, XmoneyTheme.blue, () => _open(AppRouter.security)),
      _ServiceItem('Support', Icons.headset_mic_outlined, const Color(0xFF6B5B95), () => _soon('Support')),
      _ServiceItem('Settings', Icons.settings_outlined, const Color(0xFF5B6B7C), () => _open(AppRouter.settings)),
      _ServiceItem('Notifications', Icons.notifications_outlined, XmoneyTheme.gold, () => _open(AppRouter.notifications)),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('All services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scroll,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: [..._moreServices, ...extra].length,
                  itemBuilder: (_, i) {
                    final item = [..._moreServices, ...extra][i];
                    return XmServiceTile(
                      label: item.label,
                      icon: item.icon,
                      accent: item.accent,
                      onTap: () {
                        Navigator.pop(ctx);
                        item.onTap();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = (_analytics?['wallets'] as List?) ?? [];
    final w = wallets.isNotEmpty ? wallets.first as Map<String, dynamic> : null;
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final balance = w != null ? '${fmt.format(w['available_balance'])} ${w['currency_code']}' : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  XmHomeHeader(
                    onProfile: () => _open(AppRouter.profile),
                    onSearch: () => _soon('Search'),
                    onNotifications: () => _open(AppRouter.notifications),
                  ),
                  XmWalletHeroCard(
                    balanceLabel: 'Available balance',
                    balanceText: balance,
                    secondaryLabel: 'Upgrade account',
                    onSecondary: () => _open(AppRouter.kyc),
                    onRewards: () => _soon('Rewards'),
                    onAddMoney: widget.onTopUp ?? () {},
                  ),
                  const SizedBox(height: 16),
                  XmQuickActionStrip(
                    actions: [
                      XmPrimaryActionButton(
                        compact: true,
                        label: 'Send money',
                        icon: Icons.near_me_outlined,
                        accent: XmoneyTheme.blue,
                        onTap: widget.onSend ?? () {},
                      ),
                      XmPrimaryActionButton(
                        compact: true,
                        label: 'Bill payment',
                        icon: Icons.receipt_outlined,
                        accent: const Color(0xFF2E7D6B),
                        onTap: () => _soon('Bill payment'),
                      ),
                      XmPrimaryActionButton(
                        compact: true,
                        label: 'Mobile packages',
                        icon: Icons.sim_card_outlined,
                        accent: const Color(0xFF7C5CBF),
                        onTap: () => _soon('Mobile packages'),
                      ),
                      XmPrimaryActionButton(
                        compact: true,
                        label: 'Top up',
                        icon: Icons.add_circle_outline,
                        accent: const Color(0xFFE67E22),
                        onTap: widget.onTopUp ?? () {},
                      ),
                      XmPrimaryActionButton(
                        compact: true,
                        label: 'Scan & pay',
                        icon: Icons.qr_code_scanner,
                        accent: XmoneyTheme.blue,
                        onTap: () => _soon('Scan & pay'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  XmSectionCard(
                    title: 'More with XMONEY',
                    onViewAll: _showAllServices,
                    child: GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.72,
                      children: _moreServices
                          .map(
                            (s) => XmServiceTile(
                              label: s.label,
                              icon: s.icon,
                              accent: s.accent,
                              onTap: s.onTap,
                            ),
                          )
                          .toList(),
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
                      child: Center(child: Text('No transfers yet', style: TextStyle(color: Colors.grey.shade600))),
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

class _ServiceItem {
  const _ServiceItem(this.label, this.icon, this.accent, this.onTap);
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}
