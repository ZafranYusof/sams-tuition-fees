// lib/screens/student/StudentDashboard.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'SubjectRegistration.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _showRegisteredSubjectsPopup(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? SAMsTheme.cardDark : SAMsTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY REGISTERED SUBJECTS', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SAMsTheme.primary)),
              const SizedBox(height: 16),
              // Replace these hardcoded lines with your list logic
              _buildItemizedLine('Software Engineering Project', 'BCS3133', Theme.of(context).colorScheme.onSurface),
              _buildItemizedLine('Mobile App Development', 'BCS3233', Theme.of(context).colorScheme.onSurface),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : SAMsTheme.textMuted;
    final brass = SAMsTheme.primary;

    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Container(width: 12, height: 2, color: brass), const SizedBox(width: 8), Text('UMPSA • SAMs', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.0, color: muted))]),
              ],
            ),
            const SizedBox(height: 24),
            Text(DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted)),
            const SizedBox(height: 6),
            Text('Good morning,\nMuhammad.', style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
            const SizedBox(height: 28),
            
            // 🌟 ACADEMIC MODULES
            _SectionLabel(text: 'ACADEMIC MODULES', muted: muted, accent: brass, top: 32),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? SAMsTheme.cardDark : SAMsTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? SAMsTheme.border : SAMsTheme.border),
              ),
              child: Column(
                children: [
                  // 1. Registered Subjects (Popup)
                  _buildSimpleCourseItem(
                    title: 'Registered Courses',
                    subtitle: 'View your accepted subjects',
                    icon: Iconsax.book_1_copy,
                    onTap: () => _showRegisteredSubjectsPopup(context, isDark),
                  ),
                  Divider(color: isDark ? SAMsTheme.border : SAMsTheme.border, height: 1, indent: 20, endIndent: 20),
                  // 2. Registration (Navigate to StudentRegistration.dart)
                  _buildSimpleCourseItem(
                    title: 'Subject Registration',
                    subtitle: 'Apply for new electives',
                    icon: Iconsax.add_square_copy,
                    onTap: () {
                      // Navigates to your specified file
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubjectRegistration()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Financial Card
            GestureDetector(
              onTap: () {
                setState(() => _isFlipped = !_isFlipped);
                _isFlipped ? _flipController.forward() : _flipController.reverse();
              },
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(_flipAnim.value * 3.14159265),
                    alignment: Alignment.center,
                    child: _flipAnim.value < 0.5
                        ? _buildFinancialCardFront(t, isDark, brass, muted)
                        : Transform(transform: Matrix4.identity()..rotateX(3.14159265), alignment: Alignment.center, child: _buildFinancialCardBack(t, isDark, brass, muted)),
                  );
                },
              ),
            ),
            
            // Quick Access Section
            _SectionLabel(text: 'QUICK ACCESS', muted: muted, accent: brass),
            // ... (Add your _QuickItem Grid here as per original)
            Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 14,
                    children: [
                      _QuickItem(
                        icon: Iconsax.calendar_1_copy,
                        label: 'Calendar',
                        accent: brass,
                        muted: muted,
                        onTap: () {},
                      ),
                      _QuickItem(
                        icon: Iconsax.message_question_copy,
                        label: 'FAQ',
                        accent: brass,
                        muted: muted,
                        onTap: () {},
                      ),
                      _QuickItem(
                        icon: Iconsax.document_text_copy,
                        label: 'News',
                        accent: brass,
                        muted: muted,
                        onTap: () {},
                      ),
                      _QuickItem(
                        icon: Iconsax.map_copy,
                        label: 'Map',
                        accent: brass,
                        muted: muted,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
Widget _buildWorkspaceCard({required BuildContext context, required String number, required String title, required String subtitle, required VoidCallback onTap, required Color muted, required Color textColor}) {
    return InkWell(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Text(number, style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: SAMsTheme.primary)),
            const SizedBox(width: 24),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: textColor)), Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted))])),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCourseItem({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: SAMsTheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 16)), Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.grey))])),
            const Icon(Iconsax.arrow_right_3_copy, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCardFront(ThemeData t, bool isDark, Color brass, Color muted) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [SAMsTheme.cardDark, SAMsTheme.cardDark] : [SAMsTheme.surface, SAMsTheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: brass.withAlpha(51))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Container(width: 12, height: 1, color: brass), const SizedBox(width: 8), Text('OUTSTANDING BALANCE', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: t.colorScheme.onSurface))]),
          Icon(Iconsax.wallet_3_copy, color: t.colorScheme.onSurface.withAlpha(100), size: 18),
        ]),
        const SizedBox(height: 20),
        Row(textBaseline: TextBaseline.alphabetic, crossAxisAlignment: CrossAxisAlignment.baseline, children: [Text('RM ', style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: muted)), Text('1250.00', style: TextStyle(fontFamily: 'Inter', fontSize: 38, fontWeight: FontWeight.w400, color: t.colorScheme.onSurface))]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tap to flip breakdown statistics.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)), Icon(Iconsax.arrow_right_1_copy, size: 16, color: brass)]),
      ]),
    );
  }

  Widget _buildFinancialCardBack(ThemeData t, bool isDark, Color brass, Color muted) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? SAMsTheme.cardDark : SAMsTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: brass.withAlpha(51))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FEE DISTRIBUTION BREAKDOWN', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: brass, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildItemizedLine('Tuition Costs', 'RM 950.00', t.colorScheme.onSurface),
        _buildItemizedLine('Amenities & Lab Access', 'RM 150.00', t.colorScheme.onSurface),
        _buildItemizedLine('Digital Library Levy', 'RM 50.00', t.colorScheme.onSurface),
        _buildItemizedLine('Campus Insurance Protection', 'RM 100.00', t.colorScheme.onSurface),
      ]),
    );
  }

  Widget _buildItemizedLine(String label, String value, Color textCol) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: textCol.withAlpha(180))), Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: textCol))]));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted;
  final Color accent;
  final double top;

  const _SectionLabel({
    required this.text,
    required this.muted,
    required this.accent,
    this.top = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top, 24, 0),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 1,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontFamily: 'Inter', 
              color: muted,
              fontSize: 10.5,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color muted;
  final VoidCallback onTap;

  const _QuickItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.muted,
    required this.onTap,
  });

  @override
  State<_QuickItem> createState() => _QuickItemState();
}

class _QuickItemState extends State<_QuickItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.dividerColor,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: t.colorScheme.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', 
                  color: widget.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}