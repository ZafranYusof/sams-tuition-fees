import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_design/moon_design.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart' as lp;
import '../../providers/language_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pressable_card.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _imagePath;
  bool _isDarkMode = true;
  // Notification preferences (local-only persistence)
  bool _notifPaymentReminders = true;
  bool _notifNewFee = true;
  bool _notifReceipt = true;
  bool _notifSystem = false;

  String _profileImageKey() {
    final user = ref.read(authProvider).user;
    final id = user?['studentId'] ?? user?['student_id'] ?? user?['_id'] ?? user?['id'] ?? 'guest';
    return 'profile_image_$id';
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadDarkMode();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifPaymentReminders = prefs.getBool('notif_payment_reminders') ?? true;
      _notifNewFee = prefs.getBool('notif_new_fee') ?? true;
      _notifReceipt = prefs.getBool('notif_receipt') ?? true;
      _notifSystem = prefs.getBool('notif_system') ?? false;
    });
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('dark_mode') ?? true);
  }

  Future<void> _toggleDarkMode(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _imagePath = prefs.getString(_profileImageKey()));
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
                await prefs.remove(_profileImageKey());
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
      await prefs.setString(_profileImageKey(), picked.path);
      setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';
    final email = user?['email'] ?? '';
    final studentId = user?['studentId'] ?? '';
    final faculty = user?['faculty'] ?? '—';
    final program = user?['program'] ?? '—';
    final locale = ref.watch(languageProvider).locale;
    final semester = user?['semester']?.toString() ?? lp.t('not_set', locale);
    final role = user?['role'] ?? 'student';
    final studentStatus = (user?['studentStatus'] ?? 'active').toString();
    final financingType = (user?['financingType'] ?? 'unfinanced').toString();

    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    const accent = SAMsTheme.accent;
    final muted = th.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    // local alias kept to minimize churn in code below
    final t = th;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); }),
        title: Text(lp.t('profile', locale)),
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
                        style: GoogleFonts.inter(color: accent, fontSize: 38, fontWeight: FontWeight.w400),
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
            decoration: BoxDecoration(border: Border.all(color: accent.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(20)),
            child: Text(lp.t(role.toString(), locale).toUpperCase(),
              style: GoogleFonts.inter(color: accent, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w600),
            ),
          )),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(_statusLabel(studentStatus), _statusColor(studentStatus), t),
              _statusChip(_financingLabel(financingType), accent.withValues(alpha: 0.85), t),
            ],
          ),

          const SizedBox(height: 36),
          _SectionHead(lp.t('personal', locale), accent: accent, muted: muted),
          const SizedBox(height: 12),
          _infoRow(lp.t('student_id', locale), studentId.toString(), t),
          _infoRow(lp.t('faculty', locale), faculty.toString(), t),
          _infoRow(lp.t('program', locale), program.toString(), t),
          _infoRow('Financing', _financingLabel(financingType), t),
          _infoRow('Academic Status', _statusLabel(studentStatus), t),
          _infoRow(lp.t('semester', locale), semester, t),
          _infoRow(lp.t('email', locale), email.toString(), t, isLast: true),

          const SizedBox(height: 32),
          // ─── PREFERENCES ───
          _SectionHead(lp.t('preferences', locale), accent: accent, muted: muted),
          const SizedBox(height: 12),
          // Dark mode toggle (kept as-is, with Iconsax icon)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.dividerColor))),
            child: Row(children: [
              Icon(Iconsax.moon, color: accent.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 14),
              Expanded(child: Text(lp.t('dark_mode', locale), style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500))),
              SizedBox(height: 28, child: MoonSwitch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
                activeTrackColor: accent,
              )),
            ]),
          ),
          _settingsRow(t, accent, Iconsax.translate, lp.t('language', locale), () => _showLanguageSheet(t, accent)),
          _settingsRow(t, accent, Iconsax.notification, lp.t('notifications', locale), () => _showNotificationsSheet(t, accent), isLast: true),

          const SizedBox(height: 24),
          // ─── ACCOUNT ───
          _SectionHead(lp.t('account', locale), accent: accent, muted: muted),
          const SizedBox(height: 12),
          _settingsRow(t, accent, Iconsax.lock, lp.t('change_password', locale), () => _showChangePasswordSheet(t, accent)),
          _settingsRow(t, accent, Iconsax.shield_tick, lp.t('privacy_data', locale), () => _showPrivacySheet(t, accent), isLast: true),

          const SizedBox(height: 24),
          // ─── SUPPORT ───
          _SectionHead(lp.t('support', locale), accent: accent, muted: muted),
          const SizedBox(height: 12),
          _settingsRow(t, accent, Iconsax.message_question, lp.t('help_faq', locale), () => _showHelpSheet(t, accent)),
          _settingsRow(t, accent, Iconsax.call, lp.t('contact_us', locale), () => _showContactSheet(t, accent)),
          _settingsRow(t, accent, Iconsax.star, lp.t('rate_app', locale), () {
            AppToast.info(context, lp.t('coming_soon', locale));
          }, isLast: true),

          const SizedBox(height: 24),
          // ─── ABOUT ───
          _SectionHead(lp.t('about', locale), accent: accent, muted: muted),
          const SizedBox(height: 12),
          _settingsRow(t, accent, Iconsax.info_circle, lp.t('about_sams', locale), () => _showAboutDialog(t, accent)),
          _settingsRow(t, accent, Iconsax.code, lp.t('version_info', locale), () {
            AppToast.info(context, 'SAMs v1.0.0');
          }, isLast: true),

          const SizedBox(height: 32),
          MoonOutlinedButton(
            isFullWidth: true,
            buttonSize: MoonButtonSize.lg,
            onTap: () { HapticFeedback.lightImpact(); _showSignOutDialog(t); },
            borderColor: SAMsTheme.error,
            leading: const Icon(Icons.logout_rounded, size: 18, color: SAMsTheme.error),
            label: Text(lp.t('sign_out', locale), style: GoogleFonts.inter(color: SAMsTheme.error, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }


  Widget _statusChip(String label, Color color, ThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'warning':
        return 'Payment warning';
      case 'restricted_1':
        return 'Restriction level 1';
      case 'restricted_2':
        return 'Restriction level 2';
      case 'restricted_3':
        return 'Restriction level 3';
      case 'deferred':
        return 'Deferred';
      default:
        return 'Active';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'warning':
        return SAMsTheme.warning;
      case 'restricted_1':
      case 'restricted_2':
      case 'restricted_3':
      case 'deferred':
        return SAMsTheme.error;
      default:
        return SAMsTheme.success;
    }
  }

  String _financingLabel(String type) {
    switch (type) {
      case 'ptptn':
        return 'PTPTN loan';
      case 'sponsored':
        return 'Full sponsor';
      default:
        return 'Self-funded';
    }
  }

  void _showSignOutDialog(ThemeData t) {
    final locale = ref.read(languageProvider).locale;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 2, color: SAMsTheme.accent),
            const SizedBox(height: 12),
            Text(lp.t('sign_out', locale).toUpperCase(), style: GoogleFonts.inter(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600, color: t.textTheme.bodySmall?.color)),
            const SizedBox(height: 16),
            Text(lp.t('sign_out_confirm', locale), style: GoogleFonts.inter(fontSize: 14, color: t.colorScheme.onSurface)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: MoonTextButton(
                onTap: () => Navigator.pop(ctx),
                label: Text(lp.t('cancel', locale), style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color)),
              )),
              const SizedBox(width: 12),
              Expanded(child: MoonFilledButton(
                isFullWidth: true,
                backgroundColor: SAMsTheme.error,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                label: Text(lp.t('sign_out', locale), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showAboutDialog(ThemeData t, Color accent) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 2, color: accent),
            const SizedBox(height: 16),
            Text('SAMs', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('v1.0.0', style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color)),
            const SizedBox(height: 12),
            Text('UMPSA Tuition Fee Management', style: GoogleFonts.inter(fontSize: 13, color: t.textTheme.bodyMedium?.color)),
            const SizedBox(height: 20),
            MoonTextButton(
              onTap: () => Navigator.pop(ctx),
              label: Text('Close', style: GoogleFonts.inter(color: accent, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
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

  Widget _settingsRow(ThemeData t, Color accent, IconData icon, String label, VoidCallback onTap, {bool isLast = false}) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor)),
        ),
        child: Row(children: [
          Icon(icon, color: accent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500))),
          Icon(Iconsax.arrow_right_3, color: t.textTheme.bodySmall?.color, size: 14),
        ]),
      ),
    );
  }

  // ─── Bottom-sheet primitives ───
  Widget _sheetHandle(ThemeData t) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _sheetTitle(ThemeData t, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
  );

  Future<T?> _openSheet<T>(ThemeData t, Widget Function(BuildContext, StateSetter) builder) {
    return showMoonModalBottomSheet<T>(
      context: context,
      backgroundColor: t.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(c).viewInsets.bottom + 24),
            child: builder(c, setSheetState),
          ),
        ),
      ),
    );
  }

  // ─── Language sheet ───
  void _showLanguageSheet(ThemeData t, Color accent) {
    final current = ref.read(languageProvider).locale;
    String selected = current;
    _openSheet(t, (ctx, setSheetState) {
      final locale = selected; // for save/cancel labels reflecting selection
      Widget langTile(String code, String label) {
        final isSel = selected == code;
        return PressableCard(
          onTap: () { HapticFeedback.selectionClick(); setSheetState(() => selected = code); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.dividerColor))),
            child: Row(children: [
              Expanded(child: Text(label, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500))),
              if (isSel) Icon(Iconsax.tick_circle, color: accent, size: 18),
            ]),
          ),
        );
      }
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, lp.t('language', locale)),
        langTile('en', 'English'),
        langTile('ms', 'Bahasa Melayu'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: MoonOutlinedButton(
            isFullWidth: true,
            onTap: () => Navigator.pop(ctx),
            label: Text(lp.t('cancel', locale), style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 12),
          Expanded(child: MoonFilledButton(
            isFullWidth: true,
            backgroundColor: accent,
            onTap: () async {
              HapticFeedback.mediumImpact();
              await ref.read(languageProvider.notifier).setLang(selected);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            label: Text(lp.t('save', locale), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )),
        ]),
      ]);
    });
  }

  // ─── Notifications sheet ───
  void _showNotificationsSheet(ThemeData t, Color accent) {
    final locale = ref.read(languageProvider).locale;
    _openSheet(t, (ctx, setSheetState) {
      Widget toggleRow(String label, bool value, ValueChanged<bool> onChanged) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.dividerColor))),
        child: Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500))),
          SizedBox(height: 28, child: MoonSwitch(
            value: value,
            onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); },
            activeTrackColor: accent,
          )),
        ]),
      );
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, lp.t('notifications', locale)),
        toggleRow(lp.t('payment_reminders', locale), _notifPaymentReminders, (v) {
          setSheetState(() => _notifPaymentReminders = v);
          setState(() => _notifPaymentReminders = v);
          ref.read(notificationPrefsProvider.notifier).setPref('notif_payment_reminders', v);
        }),
        toggleRow(lp.t('new_fee_added', locale), _notifNewFee, (v) {
          setSheetState(() => _notifNewFee = v);
          setState(() => _notifNewFee = v);
          ref.read(notificationPrefsProvider.notifier).setPref('notif_new_fee', v);
        }),
        toggleRow(lp.t('receipt_generated', locale), _notifReceipt, (v) {
          setSheetState(() => _notifReceipt = v);
          setState(() => _notifReceipt = v);
          ref.read(notificationPrefsProvider.notifier).setPref('notif_receipt', v);
        }),
        toggleRow(lp.t('system_announcements', locale), _notifSystem, (v) {
          setSheetState(() => _notifSystem = v);
          setState(() => _notifSystem = v);
          ref.read(notificationPrefsProvider.notifier).setPref('notif_system', v);
        }),
        const SizedBox(height: 20),
        MoonFilledButton(
          isFullWidth: true,
          backgroundColor: accent,
          onTap: () => Navigator.pop(ctx),
          label: Text(lp.t('done', locale), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]);
    });
  }

  // ─── Change password sheet ───
  void _showChangePasswordSheet(ThemeData t, Color accent) {
    final locale = ref.read(languageProvider).locale;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    _openSheet(t, (ctx, setSheetState) {
      InputDecoration deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: t.textTheme.bodySmall?.color, fontSize: 13),
        filled: true,
        fillColor: t.scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.4)),
      );
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, lp.t('change_password', locale)),
        TextField(controller: currentCtrl, obscureText: true, style: GoogleFonts.inter(fontSize: 14, color: t.colorScheme.onSurface), decoration: deco(lp.t('current_password', locale))),
        const SizedBox(height: 12),
        TextField(controller: newCtrl, obscureText: true, style: GoogleFonts.inter(fontSize: 14, color: t.colorScheme.onSurface), decoration: deco(lp.t('new_password', locale))),
        const SizedBox(height: 12),
        TextField(controller: confirmCtrl, obscureText: true, style: GoogleFonts.inter(fontSize: 14, color: t.colorScheme.onSurface), decoration: deco(lp.t('confirm_password', locale))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: MoonOutlinedButton(
            isFullWidth: true,
            onTap: () => Navigator.pop(ctx),
            label: Text(lp.t('cancel', locale), style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 12),
          Expanded(child: MoonFilledButton(
            isFullWidth: true,
            backgroundColor: accent,
            onTap: () {
              if (newCtrl.text.isEmpty || newCtrl.text != confirmCtrl.text) {
                AppToast.error(ctx, lp.t('passwords_dont_match', locale));
                return;
              }
              Navigator.pop(ctx);
              if (mounted) AppToast.success(context, lp.t('password_updated', locale));
            },
            label: Text(lp.t('save', locale), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )),
        ]),
      ]);
    });
  }

  // ─── Privacy sheet ───
  void _showPrivacySheet(ThemeData t, Color accent) {
    _openSheet(t, (ctx, _) {
      const body =
          'SAMs collects only the data needed to manage your tuition fees: name, student ID, faculty, program, semester, contact details, and payment records.\n\n'
          'Your data is stored securely on UMPSA-managed servers and is never sold or shared with third parties for marketing.\n\n'
          'You may request a copy or deletion of your data by contacting the Treasury office.';
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, 'Privacy & data'),
        Text(body, style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color, fontSize: 13.5, height: 1.55)),
        const SizedBox(height: 20),
        MoonFilledButton(
          isFullWidth: true,
          backgroundColor: accent,
          onTap: () => Navigator.pop(ctx),
          label: Text('Got it', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]);
    });
  }

  // ─── Help & FAQ sheet ───
  void _showHelpSheet(ThemeData t, Color accent) {
    final faqs = <List<String>>[
      ['How do I pay my tuition fees?', 'Open the Tuition Fees module, select an outstanding fee, then tap Pay Now and choose a payment method.'],
      ['Where can I find my receipt?', 'Receipts appear in the History tab right after a successful payment and can be downloaded as PDF.'],
      ['Why is my balance not updated?', 'Bank transfers may take up to 1 business day to reflect. Pull to refresh or contact Treasury if it persists.'],
      ['Can I pay in instalments?', 'Yes — instalment plans are available for selected fees. Contact the Treasury office to set one up.'],
      ['How do I change my password?', 'Go to Profile → Account → Change password and enter your current and new password.'],
    ];
    final expanded = <int>{};
    _openSheet(t, (ctx, setSheetState) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, 'Help & FAQ'),
        ...List.generate(faqs.length, (i) {
          final isOpen = expanded.contains(i);
          return Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.dividerColor))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PressableCard(
                onTap: () => setSheetState(() {
                  if (isOpen) {
                    expanded.remove(i);
                  } else {
                    expanded.add(i);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Row(children: [
                    Expanded(child: Text(faqs[i][0], style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500))),
                    Icon(isOpen ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1, size: 14, color: t.textTheme.bodySmall?.color),
                  ]),
                ),
              ),
              if (isOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                  child: Text(faqs[i][1], style: GoogleFonts.inter(color: t.textTheme.bodyMedium?.color, fontSize: 13, height: 1.5)),
                ),
            ]),
          );
        }),
        const SizedBox(height: 20),
        MoonFilledButton(
          isFullWidth: true,
          backgroundColor: accent,
          onTap: () => Navigator.pop(ctx),
          label: Text('Close', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]);
    });
  }

  // ─── Contact us sheet ───
  void _showContactSheet(ThemeData t, Color accent) {
    _openSheet(t, (ctx, _) {
      Widget contactRow(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.dividerColor))),
        child: Row(children: [
          Icon(icon, color: accent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: t.textTheme.bodySmall?.color, fontSize: 11.5, letterSpacing: 0.4, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
        ]),
      );
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(t),
        _sheetTitle(t, 'Contact us'),
        contactRow(Iconsax.sms, 'Email', 'treasury@umpsa.edu.my'),
        contactRow(Iconsax.call, 'Phone', '+60 9-431 5000'),
        contactRow(Iconsax.location, 'Office', 'Treasury, Level 2, Canseleri'),
        const SizedBox(height: 20),
        MoonFilledButton(
          isFullWidth: true,
          backgroundColor: accent,
          onTap: () => Navigator.pop(ctx),
          label: Text('Close', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]);
    });
  }
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
