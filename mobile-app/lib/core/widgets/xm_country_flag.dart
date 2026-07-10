import 'package:flutter/material.dart';
import '../transfer/country_currency_option.dart';

/// Official rectangular country flag (PNG assets from ISO 3166-1 alpha-2 codes).
class XmCountryFlag extends StatelessWidget {
  const XmCountryFlag({
    super.key,
    required this.countryCode,
    this.width = 32,
    this.height = 24,
    this.borderRadius = 4,
  });

  final String countryCode;
  final double width;
  final double height;
  final double borderRadius;

  static String assetPath(String countryCode) {
    final cc = countryCode.toUpperCase();
    if (cc.length != 2) return '';
    return 'assets/flags/$cc.png';
  }

  @override
  Widget build(BuildContext context) {
    final path = assetPath(countryCode);
    if (path.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(countryFlagEmoji(countryCode), style: TextStyle(fontSize: height * 0.85)),
      ),
    );
  }
}
