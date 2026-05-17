import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _imagePath = prefs.getString('profile_image'));
  }

  Future<void> _pickImage() async {
    final t = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          Text('Change profile picture', style: t.textTheme.headlineSmall),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take photo'),
            onTap: () { Navigator.pop(context); _getImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () { Navigator.pop(context); _getImage(ImageSource.gallery); },
          ),
          if (_imagePath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: SAMsTheme.error),
              title: const Text('Remove photo', style: TextStyle(color: SAMsTheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('profile_image');
                setState(() => _imagePath = null);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', picked.path);
      setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';
    final email = user?['email'] ?? '';
    final studentId = user?['studentId'] ?? '';
    final faculty = user?['faculty'] ?? 'FKOM';
    final program = user?['program'] ?? 'Software Engineering';
    final role = user?['role'] ?? 'student';

    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = isDark ? SAMsTheme.brass : const Color(0xFFB28A3E);
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          // ─── Avatar block ───
          Center(child: Stack(
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.colorScheme.surface,
                  border: Border.all(color: accent, width: 1.2),
                  image: _imagePath != null ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover) : null,
                ),
                child: _imagePath == null
                    ? Center(child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.fraunces(color: accent, fontSize: 38, fontWeight: FontWeight.w400),
                      ))
                    : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.scaffoldBackgroundColor, width: 2.5),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: isDark ? SAMsTheme.ink : SAMsTheme.paper, size: 13),
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 18),
          Center(child: Text(name, style: t.textTheme.headlineMedium)),
          const SizedBox(height: 4),
          Center(child: Text(email, style: t.textTheme.bodyMedium)),
          const SizedBox(height: 8),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: accent.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
            child: Text(role.toUpperCase(),
              style: GoogleFonts.inter(color: accent, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w600),
            ),
          )),

          const SizedBox(height: 36),
          _SectionHead('PERSONAL', accent: accent, muted: muted),
          const SizedBox(height: 12),
          _infoRow('Student ID', studentId.toString(), t),
          _infoRow('Faculty', faculty.toString(), t),
          _infoRow('Program', program.toString(), t),
          _infoRow('Semester', '2 (2025/2026)', t),
          _infoRow('Email', email.toString(), t, isLast: true),

          const SizedBox(height: 32),
          _SectionHead('SETTINGS', accent: accent, muted: muted),
          const SizedBox(height: 12),
          _settingsItem(Icons.notifications_none_rounded, 'Notifications', () {}, t),
          _settingsItem(Icons.lock_outline_rounded, 'Change password', () {}, t),
          _settingsItem(Icons.translate_rounded, 'Language', () {}, t),
          _settingsItem(Icons.info_outline_rounded, 'About SAMs', () {}, t, isLast: true),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, size: 18, color: SAMsTheme.error),
              label: Text('Sign out', style: GoogleFonts.inter(color: SAMsTheme.error, fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SAMsTheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData t, {bool isLast = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
            style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color, fontSize: 11.5, letterSpacing: 0.4, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value,
            style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap, ThemeData t, {bool isLast = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor)),
      ),
      child: Row(children: [
        Icon(icon, color: t.textTheme.bodyMedium?.color, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14))),
        Icon(Icons.chevron_right_rounded, color: t.textTheme.bodySmall?.color, size: 18),
      ]),
    ),
  );
}

class _SectionHead extends StatelessWidget {
  final String text;
  final Color accent, muted;
  const _SectionHead(this.text, {required this.accent, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 1, color: accent),
        const SizedBox(width: 8),
        Text(text,
          style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
