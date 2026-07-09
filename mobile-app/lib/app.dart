import 'package:flutter/material.dart';
import 'core/theme/xmoney_theme.dart';
import 'core/theme/theme_controller.dart';
import 'routes/app_router.dart';
import 'core/api/session_manager.dart';

class XmoneyApp extends StatelessWidget {
  const XmoneyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final router = AppRouter(session: session, themeController: themeController);

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'XMONEY',
          debugShowCheckedModeBanner: false,
          theme: XmoneyTheme.light,
          darkTheme: XmoneyTheme.dark,
          themeMode: themeController.materialThemeMode,
          locale: themeController.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('ur'),
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: themeController.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          onGenerateRoute: router.onGenerateRoute,
          initialRoute: AppRouter.splash,
        );
      },
    );
  }
}
