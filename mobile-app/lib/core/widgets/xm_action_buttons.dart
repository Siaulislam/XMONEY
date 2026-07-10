import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Premium wallet hero card — cleaner than consumer fintech apps; XMONEY navy palette.
class XmWalletHeroCard extends StatefulWidget {
  const XmWalletHeroCard({
    super.key,
    required this.balanceLabel,
    required this.balanceText,
    required this.onAddMoney,
    this.onSecondary,
    this.secondaryLabel = 'Verify account',
  });

  final String balanceLabel;
  final String balanceText;
  final VoidCallback onAddMoney;
  final VoidCallback? onSecondary;
  final String secondaryLabel;

  @override
  State<XmWalletHeroCard> createState() => _XmWalletHeroCardState();
}

class _XmWalletHeroCardState extends State<XmWalletHeroCard> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), XmoneyTheme.navyDeep, XmoneyTheme.blue],
        ),
        boxShadow: [
          BoxShadow(
            color: XmoneyTheme.navyDeep.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.balanceLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _visible ? widget.balanceText : '••••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _visible = !_visible),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (widget.onSecondary != null)
                  Expanded(
                    child: XmWalletOutlineButton(
                      label: widget.secondaryLabel,
                      onPressed: widget.onSecondary!,
                    ),
                  ),
                if (widget.onSecondary != null) const SizedBox(width: 10),
                Expanded(
                  child: XmWalletFilledButton(
                    label: 'Add money',
                    onPressed: widget.onAddMoney,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class XmWalletOutlineButton extends StatelessWidget {
  const XmWalletOutlineButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.45), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
      child: Text(label),
    );
  }
}

class XmWalletFilledButton extends StatelessWidget {
  const XmWalletFilledButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: XmoneyTheme.navyDeep,
        padding: const EdgeInsets.symmetric(vertical: 13),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
      child: Text(label),
    );
  }
}

/// Primary home action — refined card button (Botim-inspired layout, enterprise styling).
class XmPrimaryActionButton extends StatelessWidget {
  const XmPrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? XmoneyTheme.cardDark : Colors.white;
    final border = isDark ? const Color(0xFF2A3548) : const Color(0xFFE8ECF2);

    return Material(
      color: cardBg,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: isDark ? Colors.white : XmoneyTheme.navyDeep,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(2),
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

class XmPrimaryActionRow extends StatelessWidget {
  const XmPrimaryActionRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Compact service tile for "More" grid — minimal, professional.
class XmServiceTile extends StatelessWidget {
  const XmServiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = XmoneyTheme.teal,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : accent).withOpacity(isDark ? 0.08 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : accent).withOpacity(0.12),
                  ),
                ),
                child: Icon(icon, size: 22, color: isDark ? Colors.white70 : accent),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class XmSectionCard extends StatelessWidget {
  const XmSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? XmoneyTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2A3548) : const Color(0xFFE8ECF2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : XmoneyTheme.navyDeep,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
