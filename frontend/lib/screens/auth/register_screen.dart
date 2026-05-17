import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _facultyController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _register() {
    ref.read(authProvider.notifier).register(
      _studentIdController.text.trim(),
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _facultyController.text.trim(),
      _programController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = isDark ? SAMsTheme.brass : const Color(0xFFB28A3E);
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;

    // Navigate to home when authenticated after registration
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 26, height: 1, color: accent),
                  const SizedBox(width: 10),
                  Text('NEW STUDENT',
                    style: GoogleFonts.inter(color: muted, fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Join SAMs', style: t.textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'A few details and you\'re in.',
                style: t.textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 36),
              _label('STUDENT ID', muted),
              const SizedBox(height: 8),
              TextField(controller: _studentIdController, decoration: InputDecoration(hintText: 'CB23000', prefixIcon: Icon(Icons.badge_outlined, size: 18, color: muted))),
              const SizedBox(height: 16),
              _label('FULL NAME', muted),
              const SizedBox(height: 8),
              TextField(controller: _nameController, decoration: InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline, size: 18, color: muted))),
              const SizedBox(height: 16),
              _label('EMAIL', muted),
              const SizedBox(height: 8),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'name@umpsa.edu.my', prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: muted))),
              const SizedBox(height: 16),
              _label('PASSWORD', muted),
              const SizedBox(height: 8),
              TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(hintText: '••••••••', prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: muted))),
              const SizedBox(height: 16),
              _label('FACULTY', muted),
              const SizedBox(height: 8),
              TextField(controller: _facultyController, decoration: InputDecoration(hintText: 'Faculty of Computing', prefixIcon: Icon(Icons.account_balance_outlined, size: 18, color: muted))),
              const SizedBox(height: 16),
              _label('PROGRAM', muted),
              const SizedBox(height: 8),
              TextField(controller: _programController, decoration: InputDecoration(hintText: 'Software Engineering', prefixIcon: Icon(Icons.menu_book_outlined, size: 18, color: muted))),
              if (authState.error != null) ...[
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.error_outline, color: SAMsTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(authState.error!, style: const TextStyle(color: SAMsTheme.error, fontSize: 13))),
                ]),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
                  child: authState.isLoading
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.6, color: t.colorScheme.primary),
                        )
                      : const Text('Create account', style: TextStyle(fontSize: 14.5, letterSpacing: 0.4)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: GoogleFonts.inter(color: color, fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
  );
}
