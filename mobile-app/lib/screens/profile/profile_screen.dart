import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  final _s = XmStrings.instance;

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
      appBar: AppBar(title: Text(_s.t('nav.profile', 'Profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: Text(_s.t('mobile.profile.name', 'Name')), subtitle: Text(_profile?['full_name'] as String? ?? '—')),
          ListTile(title: Text(_s.t('common.email', 'Email')), subtitle: Text(_profile?['email'] as String? ?? '—')),
          ListTile(title: Text(_s.t('nav.kyc', 'KYC')), subtitle: Text(_profile?['kyc_status'] as String? ?? '—')),
          ListTile(title: Text(_s.t('common.status', 'Status')), subtitle: Text(_profile?['status'] as String? ?? '—')),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(_s.t('mobile.profile.edit', 'Edit profile')),
            onTap: () async {
              if (_profile == null) return;
              final updated = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEditScreen(router: widget.router, profile: _profile!),
                ),
              );
              if (updated != null) setState(() => _profile = updated);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(_s.t('mobile.profile.kycDocs', 'KYC documents')),
            onTap: () => Navigator.pushNamed(context, AppRouter.kyc),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(_s.t('nav.settings', 'Settings')),
            onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
    );
  }
}
