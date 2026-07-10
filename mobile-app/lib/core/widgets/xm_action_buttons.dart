import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Botim-style home header — profile, brand, search, alerts.
class XmHomeHeader extends StatelessWidget {
  const XmHomeHeader({
    super.key,
    required this.onProfile,
    required this.onSearch,
    required this.onNotifications,
    this.onLogout,
  });

  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Material(
            color: isDark ? XmoneyTheme.cardDark : Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.person_outline, color: isDark ? Colors.white70 : XmoneyTheme.navyDeep),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'XMONEY',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : XmoneyTheme.blue,
                ),
              ),
            ),
          ),
          _HeaderIcon(icon: Icons.search, onTap: onSearch),
          _HeaderIcon(icon: Icons.notifications_outlined, onTap: onNotifications, showDot: true),
          if (onLogout != null) _HeaderIcon(icon: Icons.logout, onTap: onLogout!),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: isDark ? Colors.white70 : XmoneyTheme.navyDeep),
                if (showDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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

/// Premium wallet hero card — Botim layout, XMONEY enterprise styling.
class XmWalletHeroCard extends StatefulWidget {
  const XmWalletHeroCard({
    super.key,
    required this.balanceLabel,
    required this.balanceText,
    required this.onAddMoney,
    this.onSecondary,
    this.secondaryLabel = 'Upgrade account',
    this.onRewards,
  });

  final String balanceLabel;
  final String balanceText;
  final VoidCallback onAddMoney;
  final VoidCallback? onSecondary;
  final String secondaryLabel;
  final VoidCallback? onRewards;

  @override
  State<XmWalletHeroCard> createState() => _XmWalletHeroCardState();
}

class _XmWalletHeroCardState extends State<XmWalletHeroCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4FD6), Color(0xFF2563EB), XmoneyTheme.blue],
        ),
        boxShadow: [
          BoxShadow(
            color: XmoneyTheme.blue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                const SizedBox(width: 6),
                Text(
                  'XMONEY Wallet',
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                if (widget.onRewards != null)
                  InkWell(
                    onTap: widget.onRewards,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_outlined, color: XmoneyTheme.gold, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'My Rewards',
                            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _visible = !_visible),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.balanceLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _visible ? widget.balanceText : '•••••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white.withOpacity(0.85),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view balance',
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  child: Column(
                    children: [
                      if (widget.onSecondary != null)
                        XmWalletOutlineButton(
                          label: widget.secondaryLabel,
                          onPressed: widget.onSecondary!,
                          compact: true,
                        ),
                      if (widget.onSecondary != null) const SizedBox(height: 8),
                      XmWalletFilledButton(
                        label: 'Add money',
                        onPressed: widget.onAddMoney,
                        compact: true,
                      ),
                    ],
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
  const XmWalletOutlineButton({super.key, required this.label, required this.onPressed, this.compact = false});

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.55), width: 1.2),
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 13),
        minimumSize: Size(compact ? 0 : 44, compact ? 36 : 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: compact ? 11.5 : 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label, textAlign: TextAlign.center, maxLines: 2),
    );
  }
}

class XmWalletFilledButton extends StatelessWidget {
  const XmWalletFilledButton({super.key, required this.label, required this.onPressed, this.compact = false});

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: XmoneyTheme.blue,
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 13),
        minimumSize: Size(compact ? 0 : 44, compact ? 36 : 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: compact ? 11.5 : 14, fontWeight: FontWeight.w700),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class XmPrimaryActionButton extends StatelessWidget {
  const XmPrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? XmoneyTheme.cardDark : Colors.white;
    final border = isDark ? const Color(0xFF2A3548) : const Color(0xFFE8ECF2);
    final iconSize = compact ? 40.0 : 48.0;
    final iconGlyph = compact ? 22.0 : 24.0;

    return Material(
      color: cardBg,
      elevation: 0,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: border),
            color: accent.withOpacity(isDark ? 0.06 : 0.04),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 6 : 10, compact ? 12 : 16, compact ? 6 : 10, compact ? 10 : 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  ),
                  child: Icon(icon, color: accent, size: iconGlyph),
                ),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: isDark ? Colors.white : XmoneyTheme.navyDeep,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Container(
                  width: compact ? 22 : 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.9),
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

/// Five quick actions in one row (Botim-style); scrolls on very narrow screens.
class XmQuickActionStrip extends StatelessWidget {
  const XmQuickActionStrip({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useScroll = constraints.maxWidth < 380;
        if (useScroll) {
          return SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => SizedBox(width: 72, child: actions[i]),
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: actions[i]),
            ],
          ],
        );
      },
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
  const XmSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onViewAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : XmoneyTheme.navyDeep,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: XmoneyTheme.blue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
