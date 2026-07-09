import 'dart:async';
import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/widgets/xm_ui.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.router, required this.email, required this.purpose});

  final AppRouter router;
  final String email;
  final String purpose;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;
  final _s = XmStrings.instance;

  @override
  void initState() {
    super.initState();
    _startResendTimer(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    final res = await widget.router.api.verifyOtp(
      email: widget.email,
      otp: _otp.text.trim(),
      purpose: widget.purpose,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      if (widget.purpose == 'registration') {
        showXmSnack(context, _s.t('otp.accountVerified', 'Account verified. Please sign in.'));
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
      }
    } else {
      setState(() => _error = res['message'] as String? ?? _s.t('otp.invalid', 'Invalid OTP'));
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    final res = await widget.router.api.resendOtp(email: widget.email, purpose: widget.purpose);
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, _s.t('otp.sent', 'OTP sent'));
      _startResendTimer(60);
    } else {
      showXmSnack(context, res['message'] as String? ?? _s.t('otp.resendFail', 'Could not resend OTP'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s.t('otp.title', 'Verify OTP'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const XmBrandLogo(height: 48),
            const SizedBox(height: 24),
            Text('${_s.t('otp.subtitle', 'Enter the 6-digit code sent to')}\n${widget.email}', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _otp,
              decoration: InputDecoration(labelText: _s.t('otp.code', 'OTP code')),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: Text(_loading ? _s.t('otp.verifying', 'Verifying…') : _s.t('otp.verify', 'Verify')),
            ),
            TextButton(
              onPressed: _resendIn > 0 ? null : _resend,
              child: Text(_resendIn > 0
                  ? _s.t('otp.resendIn', 'Resend in {seconds} s').replaceAll('{seconds}', '$_resendIn')
                  : _s.t('otp.resend', 'Resend code')),
            ),
          ],
        ),
      ),
    );
  }
}
