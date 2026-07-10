import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../core/prefs/onboarding_prefs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await widget.router.api.loadConfig();
    final onboarding = await OnboardingPrefs.create();
    final loggedIn = await widget.router.session.isLoggedIn;
    if (!mounted) return;

    if (!onboarding.isComplete) {
      if (widget.router.api.previewBypassAuth) {
        await onboarding.markComplete();
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        return;
      }
    }

    // DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
    if (widget.router.api.previewBypassAuth) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
      return;
    }

    Navigator.pushReplacementNamed(context, loggedIn ? AppRouter.home : AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/branding/xmoney-logo-full.png',
              width: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, size: 80, color: Color(0xFFFFC107)),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
              color: Color(0xFFFFC107),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
