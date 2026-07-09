import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/me');
    setState(() => _profile = res['data'] as Map<String, dynamic>?);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Name'), subtitle: Text(_profile?['full_name'] as String? ?? '—')),
          ListTile(title: const Text('Email'), subtitle: Text(_profile?['email'] as String? ?? '—')),
          ListTile(title: const Text('KYC'), subtitle: Text(_profile?['kyc_status'] as String? ?? '—')),
          ListTile(title: const Text('Status'), subtitle: Text(_profile?['status'] as String? ?? '—')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('KYC documents'),
            onTap: () => Navigator.pushNamed(context, AppRouter.kyc),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
    );
  }
}
