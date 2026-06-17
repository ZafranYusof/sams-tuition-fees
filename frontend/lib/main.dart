import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'config/moon_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'providers/auth_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  // Initialize Firebase + FCM (non-blocking — failure shouldn't crash app)
  FcmService().initialize().catchError((e) {
    debugPrint('[main] FCM init failed: $e');
  });
  runApp(const ProviderScope(child: SAMsApp()));
}

class SAMsApp extends ConsumerWidget {
  const SAMsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);

    // No splash. Show plain background while auth resolves, then route directly.
    final Widget home;
    if (authState.isInitializing) {
      home = Scaffold(
        backgroundColor: themeState.isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        body: const Center(
          child: SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF5C33CF)),
          ),
        ),
      );
    } else {
      if (authState.isAuthenticated) {
        final role = authState.user?['role'] ?? 'student';
        home = MainShell(role: role);
      } else {
        home = const LoginScreen();
      }
    }

    return ToastificationWrapper(
      child: MaterialApp(
        title: 'SAMs - Tuition Fees',
        debugShowCheckedModeBanner: false,
        theme: SAMsMoonTheme.lightTheme,
        darkTheme: SAMsMoonTheme.darkTheme,
        themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
        home: home,
      ),
    );
  }
}
