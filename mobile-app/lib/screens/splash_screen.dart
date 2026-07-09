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
    await widget.router.api.loadConfig();
    final loggedIn = await widget.router.session.isLoggedIn;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? AppRouter.home : AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('XMONEY', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
