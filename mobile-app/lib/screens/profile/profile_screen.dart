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

  Future<void> _logout() async {
    await widget.router.api.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Email'), subtitle: Text(_profile?['email'] as String? ?? '—')),
          ListTile(title: const Text('KYC'), subtitle: Text(_profile?['kyc_status'] as String? ?? '—')),
          ListTile(title: const Text('Status'), subtitle: Text(_profile?['status'] as String? ?? '—')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _logout, child: const Text('Sign out')),
        ],
      ),
    );
  }
}
