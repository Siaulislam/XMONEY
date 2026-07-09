import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _submit() async {
    setState(() { _loading = true; _message = null; });
    final res = await widget.router.api.forgotPassword(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushNamed(
        context,
        AppRouter.verifyOtp,
        arguments: {'email': _email.text.trim(), 'purpose': 'password_reset'},
      );
    } else {
      setState(() => _message = res['message'] as String? ?? 'Request failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your email to receive a reset code.'),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Sending…' : 'Send reset code'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
