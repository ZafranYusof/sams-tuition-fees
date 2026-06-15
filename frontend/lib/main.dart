import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'config/moon_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
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

class SAMsApp extends ConsumerStatefulWidget {
  const SAMsApp({super.key});

  @override
  ConsumerState<SAMsApp> createState() => _SAMsAppState();
}

class _SAMsAppState extends ConsumerState<SAMsApp> {
  bool _splashShown = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);

    // Splash always shown first 2.2s, regardless of auth speed
    Widget home;
    if (!_splashShown) {
      home = SplashScreen(
        onFinish: () {
          if (mounted) setState(() => _splashShown = true);
        },
      );
    } else if (authState.isInitializing) {
      // Edge case: auth still loading after splash duration
      home = SplashScreen(onFinish: () {});
    } else {
      home = authState.isAuthenticated ? const MainShell() : const LoginScreen();
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
