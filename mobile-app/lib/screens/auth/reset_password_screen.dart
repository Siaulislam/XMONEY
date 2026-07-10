import 'package:flutter/material.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/widgets/xm_ui.dart';
import '../../routes/app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.router,
    required this.email,
    required this.otp,
  });

  final AppRouter router;
  final String email;
  final String otp;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  final _s = XmStrings.instance;

  Future<void> _submit() async {
    if (_password.text.length < 8) {
      setState(() => _error = _s.t('auth.passwordMin', 'Password must be at least 8 characters'));
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = _s.t('auth.passwordMismatch', 'Passwords do not match'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await widget.router.api.resetPassword(
      email: widget.email,
      otp: widget.otp,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      showXmSnack(context, _s.t('auth.passwordResetSuccess', 'Password updated. Please sign in.'));
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
    } else {
      setState(() => _error = res['message'] as String? ?? _s.t('auth.passwordResetFailed', 'Could not reset password'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s.t('auth.resetPassword', 'Reset password'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const XmBrandLogo(height: 48),
            const SizedBox(height: 24),
            Text(
              _s.t('auth.resetPasswordSub', 'Choose a new password for {email}').replaceAll('{email}', widget.email),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: _s.t('common.password', 'Password')),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              decoration: InputDecoration(labelText: _s.t('auth.confirmPassword', 'Confirm password')),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? _s.t('common.saving', 'Saving…') : _s.t('auth.updatePassword', 'Update password')),
            ),
          ],
        ),
      ),
    );
  }
}
