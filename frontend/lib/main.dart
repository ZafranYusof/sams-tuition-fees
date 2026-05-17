import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: SAMsApp()));
}

class SAMsApp extends ConsumerWidget {
  const SAMsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);

    // After splash, land on login or home based on auth state
    final destination = authState.isAuthenticated ? const MainShell() : const LoginScreen();

    return MaterialApp(
      title: 'SAMs - Tuition Fees',
      debugShowCheckedModeBanner: false,
      theme: SAMsLightTheme.theme,
      darkTheme: SAMsTheme.darkTheme,
      themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(nextScreen: destination),
    );
  }
}
