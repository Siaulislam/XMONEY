import 'package:flutter/material.dart';

/// Responsive breakpoints aligned with XMONEY web (320–1920).
class XmBreakpoints {
  static const double xs = 320;
  static const double sm = 375;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1440;
  static const double ultra = 1920;

  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width < md;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= md && w < lg;
  }
  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width >= lg;

  static double responsivePadding(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w < sm) return 12;
    if (w < md) return 16;
    if (w < xl) return 20;
    return 24;
  }

  static int gridColumns(BuildContext c, {int phone = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop(c)) return desktop;
    if (isTablet(c)) return tablet;
    return phone;
  }
}

/// Centers content on tablets/desktop with max width.
class XmResponsiveScaffold extends StatelessWidget {
  const XmResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.maxWidth = 720,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}
