import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.router});
  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    final s = XmStrings.instance;
    final items = [
      _Item(s.t('nav.profile', 'Profile'), Icons.person_outline, AppRouter.profile),
      _Item(s.t('nav.kyc', 'KYC'), Icons.verified_user_outlined, AppRouter.kyc),
      _Item(s.t('nav.beneficiaries', 'Beneficiaries'), Icons.people_outline, AppRouter.beneficiaries),
      _Item(s.t('nav.notifications', 'Notifications'), Icons.notifications_outlined, AppRouter.notifications),
      _Item(s.t('security.title', 'Security'), Icons.shield_outlined, AppRouter.security),
      _Item(s.t('nav.settings', 'Settings'), Icons.settings_outlined, AppRouter.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav.more', 'More'))),
      body: ListView(
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, item.route),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Item {
  const _Item(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
