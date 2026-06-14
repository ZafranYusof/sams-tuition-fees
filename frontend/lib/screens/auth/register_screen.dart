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
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedFaculty;
  String? _selectedProgram;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _autoValidate = false;

  static const List<String> _faculties = [
    'FTKK - Faculty of Chemical and Process Engineering Technology',
    'FTKA - Faculty of Civil Engineering Technology',
    'FTKEE - Faculty of Electrical and Electronics Engineering Technology',
    'FTKPM - Faculty of Manufacturing and Mechatronic Engineering Technology',
    'FTKMA - Faculty of Mechanical and Automotive Engineering Technology',
    'FK - Faculty of Computing',
    'FIST - Faculty of Industrial Sciences and Technology',
    'FIM - Faculty of Industrial Management',
  ];

  static const List<String> _programs = [
    // Engineering
    'B.Eng (Hons.) Mechanical Engineering',
    'B.Eng (Hons.) Electrical Engineering',
    'B.Eng (Hons.) Mechatronics Engineering',
    'B.Eng (Hons.) Chemical Engineering',
    'B.Eng (Hons.) Civil Engineering',
    // Engineering Technology - Chemical
    'B.Eng Tech (Hons.) Chemical Engineering Technology',
    'B.Eng Tech (Hons.) Manufacturing (Pharmaceutical)',
    'B.Eng Tech (Hons.) Mechanical (Petroleum)',
    // Engineering Technology - Civil
    'B.Eng Tech (Hons.) Civil (Building)',
    // Engineering Technology - Mechanical & Automotive
    'B.Eng Tech (Hons.) Mechanical (Design and Analysis)',
    'B.Eng Tech (Hons.) Mechanical (Oil and Gas)',
    'B.Eng Tech (Hons.) Mechanical (Automotive)',
    // Engineering Technology - Manufacturing & Mechatronic
    'B.Eng Tech (Hons.) Manufacturing (Advanced Manufacturing)',
    'B.Eng Tech (Hons.) Manufacturing (Industrial Automation)',
    'B.Eng Tech (Hons.) Mechatronic (Robotics)',
    // Engineering Technology - Electrical & Electronics
    'B.Eng Tech (Hons.) Electrical (Energy)',
    'B.Eng Tech (Hons.) Electronics (Computer System)',
    // Applied Science
    'B.Applied Science (Hons.) Industrial Chemistry',
    'B.Applied Science (Hons.) Industrial Biotechnology',
    'B.Applied Science (Hons.) Material Technology',
    'B.Occupational Safety & Health (Hons.)',
    // Mathematical Sciences
    'B.Applied Science (Hons.) Data Analytics',
    // Computer
    'B.Computer Science (Hons.) Software Engineering',
    'B.Computer Science (Hons.) Computer Systems & Networking',
    'B.Computer Science (Hons.) Multimedia Software',
    'B.Computer Science (Hons.) Cyber Security',
    // Management
    'B.Financial Technology (Hons.)',
    'B.Project Management (Hons.)',
    'B.Industrial Technology Management (Hons.)',
    'B.Business Analytics (Hons.)',
    // Technology (DVM/DKM/DLKM)
    'B.Technology (Hons.) Building Construction',
    'B.Technology (Hons.) Facilities Management',
    'B.Technology (Hons.) Oil & Gas Facilities Maintenance',
    'B.Technology (Hons.) Industrial Machining',
    'B.Technology (Hons.) Welding',
    'B.Technology (Hons.) Automotive',
    'B.Technology (Hons.) Electrical System Maintenance',
    'B.Technology (Hons.) Industrial Electronic Automation',
  ];

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final studentId = _studentIdController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final faculty = _selectedFaculty ?? '';
    final program = _selectedProgram ?? '';

    ref.read(authProvider.notifier).register(
      studentId,
      name,
      email,
      password,
      faculty,
      program,
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
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
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

                // ─── Student ID ───
                _label('STUDENT ID', muted),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentIdController,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'CB23000',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18, color: muted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Student ID is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Full Name ───
                _label('FULL NAME', muted),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline, size: 18, color: muted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Email ───
                _label('EMAIL', muted),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'name@umpsa.edu.my',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: muted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Password ───
                _label('PASSWORD', muted),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: muted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: muted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Confirm Password ───
                _label('CONFIRM PASSWORD', muted),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: muted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: muted,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Faculty Dropdown ───
                _label('FACULTY', muted),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFaculty,
                  style: GoogleFonts.inter(fontSize: 15, color: t.textTheme.bodyLarge?.color),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: muted),
                  decoration: InputDecoration(
                    hintText: 'Select faculty',
                    prefixIcon: Icon(Icons.account_balance_outlined, size: 18, color: muted),
                  ),
                  items: _faculties.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f, style: GoogleFonts.inter(fontSize: 15)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedFaculty = v),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please select a faculty';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Program Dropdown ───
                _label('PROGRAM', muted),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProgram,
                  style: GoogleFonts.inter(fontSize: 15, color: t.textTheme.bodyLarge?.color),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: muted),
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select program',
                    prefixIcon: Icon(Icons.menu_book_outlined, size: 18, color: muted),
                  ),
                  items: _programs.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: GoogleFonts.inter(fontSize: 15)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedProgram = v),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please select a program';
                    return null;
                  },
                ),

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
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: GoogleFonts.inter(color: color, fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
  );
}
