import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/session_manager.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/shell/main_shell_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/transfer/transfer_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/kyc/kyc_screen.dart';
import '../screens/beneficiaries/beneficiaries_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../core/theme/theme_controller.dart';

class AppRouter {
  AppRouter({required this.session, this.themeController}) : api = ApiClient(session);

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  static const home = '/home';
  static const wallet = '/wallet';
  static const transfer = '/transfer';
  static const transactions = '/transactions';
  static const profile = '/profile';
  static const kyc = '/kyc';
  static const beneficiaries = '/beneficiaries';
  static const notifications = '/notifications';
  static const settings = '/settings';

  final SessionManager session;
  final ThemeController? themeController;
  final ApiClient api;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen(router: this));
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen(router: this));
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen(router: this));
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen(router: this));
      case verifyOtp:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            router: this,
            email: args['email'] as String? ?? '',
            purpose: args['purpose'] as String? ?? 'registration',
          ),
        );
      case home:
        return MaterialPageRoute(builder: (_) => MainShellScreen(router: this));
      case wallet:
        return MaterialPageRoute(builder: (_) => MainShellScreen(router: this, initialIndex: 3));
      case transfer:
        return MaterialPageRoute(builder: (_) => MainShellScreen(router: this, initialIndex: 1));
      case transactions:
        return MaterialPageRoute(builder: (_) => MainShellScreen(router: this, initialIndex: 2));
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen(router: this));
      case kyc:
        return MaterialPageRoute(builder: (_) => KycScreen(router: this));
      case beneficiaries:
        return MaterialPageRoute(builder: (_) => BeneficiariesScreen(router: this));
      case notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen(router: this));
      case settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen(router: this, themeController: themeController));
      default:
        return MaterialPageRoute(builder: (_) => SplashScreen(router: this));
    }
  }
}
