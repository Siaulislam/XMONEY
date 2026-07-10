import 'package:flutter/material.dart';

/// Shared responsive layout helpers for transfer flows.
class XmLayout {
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return 560;
    if (w >= 800) return 520;
    return double.infinity;
  }

  static double horizontalPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 800) return 32;
    if (w >= 600) return 24;
    return 18;
  }
}
