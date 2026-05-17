import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/fees/fees_screen.dart';
import '../screens/fees/student/student_fees_shell.dart';
import '../screens/fees/treasury/treasury_shell.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String fees = '/fees';
  static const String studentFees = '/fees/student';
  static const String treasuryFees = '/fees/treasury';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(nextScreen: LoginScreen()));
      case AppRoutes.login:
        return _buildRoute(const LoginScreen());
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen());
      case AppRoutes.home:
        return _buildRoute(const MainShell());
      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen());
      case AppRoutes.profile:
        return _buildRoute(const ProfileScreen());
      case AppRoutes.fees:
        return _buildRoute(const FeesScreen());
      case AppRoutes.studentFees:
        return _buildRoute(const StudentFeesShell());
      case AppRoutes.treasuryFees:
        return _buildRoute(const TreasuryShell());
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
