import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final res = await widget.router.api.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
      return;
    }

    final msg = res['message'] as String? ?? 'Login failed';
    if (msg.toLowerCase().contains('verify') || msg.toLowerCase().contains('pending')) {
      Navigator.pushNamed(
        context,
        AppRouter.verifyOtp,
        arguments: {'email': _email.text.trim(), 'purpose': 'registration'},
      );
      return;
    }
    setState(() => _error = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: XmBrandLogo(height: 72)),
              const SizedBox(height: 32),
              const Text('Sign in', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Secure international transfers', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Signing in…' : 'Sign in'),
              ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
              child: const Text('Create a free account'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.forgotPassword),
              child: const Text('Forgot password?'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
