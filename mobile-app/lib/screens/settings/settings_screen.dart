import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/l10n/xm_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.router, this.themeController});

  final AppRouter router;
  final ThemeController? themeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  final _s = XmStrings.instance;

  Future<void> _changePassword() async {
    setState(() => _busy = true);
    final res = await widget.router.api.changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _current.clear();
      _next.clear();
      showXmSnack(context, _s.t('mobile.settings.passwordUpdated', 'Password updated'));
    } else {
      showXmSnack(context, res['message'] as String? ?? _s.t('mobile.settings.passwordUpdateFailed', 'Could not change password'), error: true);
    }
  }

  Future<void> _logout() async {
    await widget.router.api.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.themeController;
    return Scaffold(
      appBar: AppBar(title: Text(_s.t('nav.settings', 'Settings'))),
      body: ListView(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 375 ? 12 : 16),
        children: [
          if (tc != null) ...[
            Text(_s.t('theme.label', 'Theme'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<XmThemeMode>(
              segments: [
                ButtonSegment(value: XmThemeMode.light, label: Text(_s.t('theme.light', 'Light'))),
                ButtonSegment(value: XmThemeMode.dark, label: Text(_s.t('theme.dark', 'Dark'))),
                ButtonSegment(value: XmThemeMode.system, label: Text(_s.t('theme.system', 'System'))),
              ],
              selected: {tc.themeMode},
              onSelectionChanged: (s) => tc.setThemeMode(s.first),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _s.lang,
              decoration: InputDecoration(labelText: _s.t('lang.label', 'Language')),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'ur', child: Text('اردو')),
              ],
              onChanged: (v) { if (v != null) tc.setLocale(v); },
            ),
            const Divider(height: 32),
          ],
          Text(_s.t('mobile.settings.security', 'Security'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _current, decoration: InputDecoration(labelText: _s.t('mobile.settings.currentPassword', 'Current password')), obscureText: true),
          const SizedBox(height: 8),
          TextField(controller: _next, decoration: InputDecoration(labelText: _s.t('mobile.settings.newPassword', 'New password')), obscureText: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _changePassword,
            child: Text(_busy ? _s.t('mobile.settings.saving', 'Saving…') : _s.t('mobile.settings.changePassword', 'Change password')),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size.fromHeight(44)),
            child: Text(_s.t('nav.logout', 'Sign out')),
          ),
        ],
      ),
    );
  }
}
