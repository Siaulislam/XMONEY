import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  Future<void> _changePassword() async {
    setState(() => _busy = true);
    final res = await widget.router.api.changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _current.clear();
      _next.clear();
      showXmSnack(context, 'Password updated');
    } else {
      showXmSnack(context, res['message'] as String? ?? 'Could not change password', error: true);
    }
  }

  Future<void> _logout() async {
    await widget.router.api.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _current, decoration: const InputDecoration(labelText: 'Current password'), obscureText: true),
          const SizedBox(height: 8),
          TextField(controller: _next, decoration: const InputDecoration(labelText: 'New password'), obscureText: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _changePassword,
            child: Text(_busy ? 'Saving…' : 'Change password'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: const Text('1.0.0'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
