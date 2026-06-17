import 'package:flutter/material.dart';
import '../screens/ManageAuth/login_screen.dart';
import '../screens/ManageAuth/register_screen.dart';
import '../screens/ManageHome/main_shell.dart';
import '../screens/ManageHome/dashboard_screen.dart';
import '../screens/ManageHome/profile_screen.dart';
import '../screens/ManageTuitionFees/fees_screen.dart';
import '../screens/ManageTuitionFees/student/student_fees_shell.dart';
import '../screens/ManageTuitionFees/treasury/treasury_shell.dart';

class AppRoutes {
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
      case AppRoutes.login:
        return _buildRoute(const LoginScreen());
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen());
      case AppRoutes.home:
        return _buildRoute(const MainShell(role: 'student'));
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
