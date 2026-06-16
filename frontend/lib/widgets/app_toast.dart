import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../config/theme.dart';

/// Reusable toast helper for SAMs app — wraps the toastification package
/// with the project's design tokens (colors, typography, spacing).
///
/// Usage:
///   AppToast.success(context, 'Payment successful');
///   AppToast.error(context, 'Network error', desc: 'Check your connection');
///   AppToast.warning(context, 'Pending verification');
///   AppToast.info(context, 'New update available');
class AppToast {
  AppToast._();

  static void success(BuildContext context, String title, {String? desc}) {
    _show(
      context,
      title: title,
      desc: desc,
      type: ToastificationType.success,
      color: SAMsTheme.success,
      icon: Icons.check_circle_rounded,
      autoClose: const Duration(seconds: 3),
    );
  }

  static void error(BuildContext context, String title, {String? desc}) {
    _show(
      context,
      title: title,
      desc: desc,
      type: ToastificationType.error,
      color: SAMsTheme.error,
      icon: Icons.error_rounded,
      autoClose: const Duration(seconds: 4),
    );
  }

  static void warning(BuildContext context, String title, {String? desc}) {
    _show(
      context,
      title: title,
      desc: desc,
      type: ToastificationType.warning,
      color: SAMsTheme.warning,
      icon: Icons.warning_rounded,
      autoClose: const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String title, {String? desc}) {
    _show(
      context,
      title: title,
      desc: desc,
      type: ToastificationType.info,
      color: SAMsTheme.accent,
      icon: Icons.info_rounded,
      autoClose: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String title,
    String? desc,
    required ToastificationType type,
    required Color color,
    required IconData icon,
    required Duration autoClose,
  }) {
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: autoClose,
      primaryColor: color,
      icon: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      description: desc != null
          ? Text(
              desc,
              style: GoogleFonts.inter(fontSize: 12),
            )
          : null,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      showProgressBar: true,
      closeOnClick: true,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }
}
