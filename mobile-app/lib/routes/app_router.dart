import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/session_manager.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/transfer/transfer_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  AppRouter({required this.session}) : api = ApiClient(session);

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const wallet = '/wallet';
  static const transfer = '/transfer';
  static const transactions = '/transactions';
  static const profile = '/profile';

  final SessionManager session;
  final ApiClient api;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen(router: this));
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen(router: this));
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen(router: this));
      case wallet:
        return MaterialPageRoute(builder: (_) => WalletScreen(router: this));
      case transfer:
        return MaterialPageRoute(builder: (_) => TransferScreen(router: this));
      case transactions:
        return MaterialPageRoute(builder: (_) => TransactionsScreen(router: this));
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen(router: this));
      default:
        return MaterialPageRoute(builder: (_) => SplashScreen(router: this));
    }
  }
}
