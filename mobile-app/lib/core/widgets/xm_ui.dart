import 'package:flutter/material.dart';
import '../../core/theme/xmoney_theme.dart';

class XmBrandLogo extends StatelessWidget {
  const XmBrandLogo({super.key, this.height = 40, this.full = true});

  final double height;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      full ? 'assets/branding/xmoney-logo-full.png' : 'assets/branding/xmoney-monogram.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class XmLoading extends StatelessWidget {
  const XmLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: XmoneyTheme.gold),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

void showXmSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
    ),
  );
}
