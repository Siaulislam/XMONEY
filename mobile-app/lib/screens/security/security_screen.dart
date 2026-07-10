import 'package:flutter/material.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/widgets/xm_ui.dart';
import '../../routes/app_router.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key, required this.router});

  final AppRouter router;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _devices = [];
  final _s = XmStrings.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.router.api.get('/v1/me/devices');
    if (!mounted) return;
    setState(() {
      _loading = false;
      final data = res['data'];
      _devices = data is List ? data.cast<Map<String, dynamic>>() : [];
    });
  }

  Future<void> _revoke(int id) async {
    final res = await widget.router.api.delete('/v1/me/devices/$id');
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, _s.t('security.deviceRevoked', 'Device signed out'));
      _load();
    } else {
      showXmSnack(context, res['message'] as String? ?? _s.t('security.revokeFailed', 'Could not revoke device'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s.t('security.title', 'Security'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(_s.t('security.changePassword', 'Change password')),
                      subtitle: Text(_s.t('security.changePasswordSub', 'Update your account password')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRouter.settings),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_s.t('security.devices', 'Signed-in devices'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_s.t('security.noDevices', 'No devices found'), textAlign: TextAlign.center),
                    )
                  else
                    ..._devices.map((d) {
                      final id = d['id'] as int? ?? 0;
                      final platform = d['platform'] as String? ?? '—';
                      final model = d['device_model'] as String? ?? d['device_name'] as String? ?? 'Device';
                      final last = d['last_seen_at'] as String? ?? '';
                      return Card(
                        child: ListTile(
                          leading: Icon(platform == 'ios' ? Icons.phone_iphone : Icons.phone_android),
                          title: Text(model),
                          subtitle: Text('$platform · $last'),
                          trailing: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            tooltip: _s.t('security.signOutDevice', 'Sign out device'),
                            onPressed: () => _revoke(id),
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
