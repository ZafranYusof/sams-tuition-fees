import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moon_design/moon_design.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_toast.dart';
import '../home/main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final locale = ref.watch(languageProvider).locale;
    final theme = Theme.of(context);
    const accent = SAMsTheme.accent;
    final muted = theme.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;

    // Navigate to home when authenticated
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // ─── Editorial wordmark ───
                Row(
                  children: [
                    Container(width: 26, height: 1, color: accent),
                    const SizedBox(width: 10),
                    Text('UMPSA · SAMs',
                      style: GoogleFonts.inter(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                Text(t('welcome', locale), style: theme.textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  t('welcome_login_subtitle', locale),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 44),

                // ─── EMAIL ───
                _fieldLabel(t('email_label', locale), muted),
                const SizedBox(height: 8),
                MoonFormTextInput(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  hintText: 'name@umpsa.edu.my',
                  leading: Icon(Icons.alternate_email_rounded, size: 18, color: muted),
                  textColor: theme.textTheme.bodyLarge?.color,
                  hintTextColor: muted,
                  backgroundColor: theme.inputDecorationTheme.fillColor?.withValues(alpha: 0.4),
                  activeBorderColor: accent,
                  inactiveBorderColor: theme.dividerColor,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('email_required', locale);
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                      return t('email_invalid', locale);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ─── PASSWORD ───
                _fieldLabel(t('password_label', locale), muted),
                const SizedBox(height: 8),
                MoonFormTextInput(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  hintText: '••••••••',
                  leading: Icon(Icons.lock_outline_rounded, size: 18, color: muted),
                  trailing: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _obscurePassword = !_obscurePassword); },
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: muted,
                    ),
                  ),
                  textColor: theme.textTheme.bodyLarge?.color,
                  hintTextColor: muted,
                  backgroundColor: theme.inputDecorationTheme.fillColor?.withValues(alpha: 0.4),
                  activeBorderColor: accent,
                  inactiveBorderColor: theme.dividerColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('password_required', locale);
                    }
                    if (value.length < 6) {
                      return t('password_min', locale);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ─── Forgot password link ───
                Align(
                  alignment: Alignment.centerRight,
                  child: MoonTextButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AppToast.info(context, t('contact_admin_reset', locale));
                    },
                    label: Text(
                      t('forgot_password', locale),
                      style: GoogleFonts.inter(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: SAMsTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(authState.error!, style: const TextStyle(color: SAMsTheme.error, fontSize: 13))),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // ─── Sign In Button (Moon) ───
                MoonFilledButton(
                  isFullWidth: true,
                  buttonSize: MoonButtonSize.lg,
                  backgroundColor: accent,
                  onTap: authState.isLoading ? null : _login,
                  label: authState.isLoading
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.6, color: theme.colorScheme.onPrimary),
                        )
                      : Text(
                          t('sign_in_btn', locale),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // ─── Hairline divider with brass tick ───
                Row(children: [
                  Expanded(child: Container(height: 1, color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: accent, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Container(height: 1, color: theme.dividerColor)),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t('new_to_sams', locale), style: theme.textTheme.bodyMedium),
                      InkWell(
                        onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())); },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Text(t('create_account', locale),
                            style: GoogleFonts.inter(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: accent.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) => Text(
    label,
    style: GoogleFonts.inter(
      color: color,
      fontSize: 10.5,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w600,
    ),
  );
}
