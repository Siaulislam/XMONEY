import 'package:flutter/material.dart';
import 'core/theme/xmoney_theme.dart';
import 'routes/app_router.dart';
import 'core/api/session_manager.dart';

class XmoneyApp extends StatefulWidget {
  const XmoneyApp({super.key});

  @override
  State<XmoneyApp> createState() => _XmoneyAppState();
}

class _XmoneyAppState extends State<XmoneyApp> {
  final _session = SessionManager();
  late final _router = AppRouter(session: _session);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XMONEY',
      debugShowCheckedModeBanner: false,
      theme: XmoneyTheme.light,
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
