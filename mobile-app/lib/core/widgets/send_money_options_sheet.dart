import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// How the user chose to send money (Send Money To sheet).
enum SendMoneyChannel {
  international,
  bank,
  cnic,
  local,
  otherWallets,
  scanQr,
}

/// Botim-style "Send Money To" picker with XMONEY branding on International transfer.
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
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send Money To',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: XmoneyTheme.navyDeep,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SendOptionTile(
                  label: 'International\nTransfer',
                  child: const _XmTransferLogo(),
                  onTap: () => onSelected(SendMoneyChannel.international),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SendOptionTile(
                  label: 'Bank\nTransfer',
                  child: const _BankTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.bank),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SendOptionTile(
                  label: 'CNIC\nTransfer',
                  child: const _CnicTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.cnic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SendOptionTile(
                  label: 'Local\nTransfer',
                  child: const _LocalTransferIcon(),
                  onTap: () => onSelected(SendMoneyChannel.local),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SendOptionTile(
                  label: 'Other\nWallets',
                  child: const _OtherWalletsIcon(),
                  onTap: () => onSelected(SendMoneyChannel.otherWallets),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SendOptionTile(
                  label: 'Scan QR',
                  child: const _ScanQrIcon(),
                  onTap: () => onSelected(SendMoneyChannel.scanQr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendOptionTile extends StatelessWidget {
  const _SendOptionTile({
    required this.label,
    required this.child,
    required this.onTap,
  });

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
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
            child: Column(
              children: [
                SizedBox(height: 52, child: Center(child: child)),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: XmoneyTheme.navyDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// XM monogram — gold X, black M (matches brand transfer tile).
class _XmTransferLogo extends StatelessWidget {
  const _XmTransferLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/xmoney-monogram.png',
      height: 44,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const _XmTransferLogoFallback(),
    );
  }
}

class _XmTransferLogoFallback extends StatelessWidget {
  const _XmTransferLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'X',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: XmoneyTheme.gold,
            height: 1,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Text(
              'M',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1,
              ),
            ),
            Positioned(
              right: -6,
              top: -4,
              child: Icon(Icons.north_east, size: 14, color: XmoneyTheme.gold),
            ),
          ],
        ),
      ],
    );
  }
}

class _BankTransferIcon extends StatelessWidget {
  const _BankTransferIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 44),
      painter: _BankIconPainter(),
    );
  }
}

class _BankIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = XmoneyTheme.teal;
    const black = Colors.black;
    final w = size.width;
    final h = size.height;

    final roof = Path()
      ..moveTo(w * 0.08, h * 0.28)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.92, h * 0.28)
      ..close();
    canvas.drawPath(roof, Paint()..color = black);

    final base = Rect.fromLTWH(w * 0.06, h * 0.82, w * 0.88, h * 0.1);
    canvas.drawRect(base, Paint()..color = black);

    for (var i = 0; i < 3; i++) {
      final x = w * (0.22 + i * 0.22);
      canvas.drawRect(
        Rect.fromLTWH(x, h * 0.32, w * 0.1, h * 0.48),
        Paint()..color = green,
      );
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: XmoneyTheme.teal.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 14, color: XmoneyTheme.teal),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 22, color: Colors.black),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: Colors.black),
                const SizedBox(height: 3),
                Container(height: 2, width: 20, color: Colors.black),
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
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.9)),
            ),
          ),
          Positioned(
            right: 2,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: XmoneyTheme.teal,
              child: Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.95)),
            ),
          ),
          Icon(Icons.swap_horiz, size: 22, color: Colors.black.withOpacity(0.75)),
        ],
      ),
    );
  }
}

class _OtherWalletsIcon extends StatelessWidget {
  const _OtherWalletsIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.black.withOpacity(0.85)),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(color: XmoneyTheme.teal, shape: BoxShape.circle),
            ),
          ),
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomPaint(
        painter: _QrPainter(),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const black = Colors.black;
    final green = XmoneyTheme.teal;
    final cell = size.width / 5;

    void cellRect(int row, int col, Color c) {
      canvas.drawRect(
        Rect.fromLTWH(col * cell + 1, row * cell + 1, cell - 2, cell - 2),
        Paint()..color = c,
      );
    }

    cellRect(0, 0, black);
    cellRect(0, 1, green);
    cellRect(1, 0, green);
    cellRect(1, 1, black);
    cellRect(2, 2, black);
    cellRect(2, 3, green);
    cellRect(3, 2, green);
    cellRect(3, 4, black);
    cellRect(4, 3, black);
    cellRect(4, 4, green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
