import 'package:flutter/material.dart';
import '../../core/l10n/xm_strings.dart';
import '../../core/prefs/onboarding_prefs.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/widgets/xm_ui.dart';
import '../../routes/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.router});

  final AppRouter router;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;
  final _s = XmStrings.instance;

  List<_Slide> get _slides => [
        _Slide(
          title: _s.t('onboarding.slide1Title', 'Send money with confidence'),
          body: _s.t('onboarding.slide1Body', 'Bank-grade security, transparent rates, and real-time transfer tracking.'),
          icon: Icons.shield_outlined,
          accent: XmoneyTheme.teal,
        ),
        _Slide(
          title: _s.t('onboarding.slide2Title', 'Fair exchange rates'),
          body: _s.t('onboarding.slide2Body', 'See the exact rate and fee before you confirm every transfer.'),
          icon: Icons.currency_exchange,
          accent: XmoneyTheme.gold,
        ),
        _Slide(
          title: _s.t('onboarding.slide3Title', 'Your wallet, everywhere'),
          body: _s.t('onboarding.slide3Body', 'Manage beneficiaries, KYC, and notifications from one premium app.'),
          icon: Icons.account_balance_wallet_outlined,
          accent: XmoneyTheme.blue,
        ),
      ];

  Future<void> _finish() async {
    final onboarding = await OnboardingPrefs.create();
    await onboarding.markComplete();
    if (!mounted) return;
    final loggedIn = await widget.router.session.isLoggedIn;
    Navigator.pushReplacementNamed(context, loggedIn ? AppRouter.home : AppRouter.login);
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _page.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(_s.t('onboarding.skip', 'Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const XmBrandLogo(height: 44),
                        const SizedBox(height: 36),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [slide.accent.withValues(alpha: 0.25), slide.accent.withValues(alpha: 0.08)],
                            ),
                          ),
                          child: Icon(slide.icon, size: 56, color: slide.accent),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: i == _index ? XmoneyTheme.teal : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.fromLTRB(isWide ? 64 : 24, 0, isWide ? 64 : 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index >= _slides.length - 1
                        ? _s.t('onboarding.getStarted', 'Get started')
                        : _s.t('onboarding.next', 'Next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.body, required this.icon, required this.accent});
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
}
