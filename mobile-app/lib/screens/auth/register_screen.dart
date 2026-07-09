import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _country = TextEditingController(text: 'AE');
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final res = await widget.router.api.register({
      'full_name': _name.text.trim(),
      'email': _email.text.trim(),
      'mobile_country': '+971',
      'mobile_number': _mobile.text.trim(),
      'password': _password.text,
      'country_code': _country.text.trim().toUpperCase(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushNamed(
        context,
        AppRouter.verifyOtp,
        arguments: {'email': _email.text.trim(), 'purpose': 'registration'},
      );
    } else {
      setState(() => _error = res['message'] as String? ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: XmBrandLogo(height: 56)),
            const SizedBox(height: 24),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _mobile, decoration: const InputDecoration(labelText: 'Mobile (+971)'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country code (ISO)')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Creating…' : 'Create account'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
