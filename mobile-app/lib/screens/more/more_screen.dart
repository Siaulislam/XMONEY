import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.router});
  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item('Profile', Icons.person_outline, AppRouter.profile),
      _Item('KYC verification', Icons.verified_user_outlined, AppRouter.kyc),
      _Item('Beneficiaries', Icons.people_outline, AppRouter.beneficiaries),
      _Item('Notifications', Icons.notifications_outlined, AppRouter.notifications),
      _Item('Settings', Icons.settings_outlined, AppRouter.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: items.map((item) => ListTile(
          leading: Icon(item.icon),
          title: Text(item.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, item.route),
        )).toList(),
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
