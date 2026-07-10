import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Send Money To — five distinct transfer modules (no duplicates).
enum SendMoneyChannel {
  internationalWallet,
  internationalBank,
  local,
  cnic,
  scanQr,
}

class SendMoneyOptionsSheet extends StatelessWidget {
  const SendMoneyOptionsSheet({super.key, required this.onSelected});

  final ValueChanged<SendMoneyChannel> onSelected;

  static Future<SendMoneyChannel?> show(BuildContext context) {
    return showModalBottomSheet<SendMoneyChannel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SendMoneyOptionsSheet(
        onSelected: (ch) => Navigator.pop(ctx, ch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send Money To',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: XmoneyTheme.navyDeep, letterSpacing: -0.3),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SendOptionTile(
                  label: 'International\nWallet Transfer',
                  child: const _XmTransferLogo(),
                  onTap: () => onSelected(SendMoneyChannel.internationalWallet),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SendOptionTile(
                  label: 'International\nBank Transfer',
                  child: const _BankTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.internationalBank),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SendOptionTile(
                  label: 'Local\nTransfer',
                  child: const _LocalTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.local),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SendOptionTile(
                  label: 'CNIC\nTransfer',
                  child: const _CnicTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.cnic),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SendOptionTile(
                  label: 'Scan QR',
                  child: const _ScanQrIcon(),
                  onTap: () => onSelected(SendMoneyChannel.scanQr),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendOptionTile extends StatelessWidget {
  const _SendOptionTile({required this.label, required this.child, required this.onTap});

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 12),
            child: Column(
              children: [
                SizedBox(height: 48, child: Center(child: child)),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: XmoneyTheme.navyDeep),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XmTransferLogo extends StatelessWidget {
  const _XmTransferLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/xmoney-monogram.png',
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text('XM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    );
  }
}

class _BankTransferIcon extends StatelessWidget {
  const _BankTransferIcon();

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(48, 44), painter: _BankIconPainter());
}

class _BankIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = XmoneyTheme.teal;
    final w = size.width;
    final h = size.height;
    final roof = Path()
      ..moveTo(w * 0.08, h * 0.28)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.92, h * 0.28)
      ..close();
    canvas.drawPath(roof, Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.82, w * 0.88, h * 0.1), Paint()..color = Colors.black);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(w * (0.22 + i * 0.22), h * 0.32, w * 0.1, h * 0.48), Paint()..color = green);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CnicTransferIcon extends StatelessWidget {
  const _CnicTransferIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 36,
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Container(
            width: 18,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: XmoneyTheme.teal.withOpacity(0.25), shape: BoxShape.circle),
            child: Icon(Icons.person, size: 14, color: XmoneyTheme.teal),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 22, color: Colors.black),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalTransferIcon extends StatelessWidget {
  const _LocalTransferIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            child: CircleAvatar(radius: 14, backgroundColor: Colors.black, child: Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.9))),
          ),
          Positioned(
            right: 2,
            child: CircleAvatar(radius: 14, backgroundColor: XmoneyTheme.teal, child: Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.95))),
          ),
          Icon(Icons.swap_horiz, size: 22, color: Colors.black.withOpacity(0.75)),
        ],
      ),
    );
  }
}

class _ScanQrIcon extends StatelessWidget {
  const _ScanQrIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
    );
  }
}
