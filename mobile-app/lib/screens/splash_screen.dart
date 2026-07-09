import 'package:flutter/material.dart';
import '../routes/app_router.dart';

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
    final loggedIn = await widget.router.session.isLoggedIn;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? AppRouter.home : AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/branding/xmoney-logo-full.png'),
              width: 280,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 28),
            CircularProgressIndicator(
              color: Color(0xFFFFC107),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
