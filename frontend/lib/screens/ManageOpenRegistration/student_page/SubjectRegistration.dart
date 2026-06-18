import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'RegistrationResult.dart';

class SubjectRegistration extends StatefulWidget {
  const SubjectRegistration({super.key});

  @override
  State<SubjectRegistration> createState() => _SubjectRegistrationState();
}

class _SubjectRegistrationState extends State<SubjectRegistration> {
  List<Map<String, dynamic>> _allCourses = [];
  final List<String> _selectedCodes = [];
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load courses and check session in parallel
      final results = await Future.wait([
        ApiService.get('/registration/courses'),
        ApiService.get('/registration/session').catchError((_) => null),
      ]);

      final courseData = results[0];
      final sessionData = results[1];

      // Check session status
      if (sessionData != null && sessionData is Map && sessionData.isNotEmpty) {
        _sessionActive = true;
      } else {
        _sessionActive = false;
        // Show popup after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showClosedDialog();
        });
      }

      if (courseData is List) {
        setState(() {
          _allCourses = List<Map<String, dynamic>>.from(courseData.map((c) => {
            '_id': c['_id'] ?? '',
            'code': c['courseId'] ?? c['code'] ?? '',
            'name': c['courseName'] ?? c['name'] ?? '',
            'credits': c['creditHours'] ?? c['credits'] ?? 0,
            'quota': c['capacity'] ?? c['quota'] ?? 0,
          }));
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load courses'; _loading = false; _sessionActive = false; });
    }
  }

  int get _totalCredits => _allCourses
      .where((c) => _selectedCodes.contains(c['code']))
      .fold(0, (sum, c) => sum + (c['credits'] as int));

  void _showClosedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Iconsax.lock, color: SAMsTheme.error, size: 20),
            const SizedBox(width: 8),
            const Text('Registration Closed', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
          ],
        ),
        content: Text(
          'Registration is currently closed. No active session available. Please check back during the next registration period.',
          style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: SAMsTheme.accent, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : const Color(0xFF6B7280);
    final brass = SAMsTheme.primary;
    final filteredCourses = _allCourses.where((c) =>
      c['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c['code'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_copy, color: t.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SUBJECT REGISTRATION',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register for\nElective Subjects.', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('Select subjects to add to your registration cart.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Registration closed banner
          if (!_loading && !_sessionActive)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SAMsTheme.error.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SAMsTheme.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2_copy, color: SAMsTheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Registration is closed. No active session available.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: SAMsTheme.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (!_loading && !_sessionActive) const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: t.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.dividerColor),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by name or code...',
                  hintStyle: TextStyle(fontFamily: 'Inter', color: muted, fontSize: 13),
                  prefixIcon: Icon(Iconsax.search_normal_copy, color: muted, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Course List
          Expanded(
            child: _loading
              ? Center(child: CircularProgressIndicator(color: brass, strokeWidth: 2))
              : _error != null
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.warning_2_copy, color: SAMsTheme.error, size: 32),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(fontFamily: 'Inter', color: muted)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadCourses, child: Text('Retry', style: TextStyle(fontFamily: 'Inter', color: brass))),
                    ],
                  ))
                : filteredCourses.isEmpty
                  ? Center(child: Text('No courses found', style: TextStyle(fontFamily: 'Inter', color: muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        final isSelected = _selectedCodes.contains(course['code']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _sessionActive ? () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  isSelected
                                    ? _selectedCodes.remove(course['code'])
                                    : _selectedCodes.add(course['code']);
                                });
                              } : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? brass.withAlpha(30) : (isDark ? SAMsTheme.surfaceLight : SAMsTheme.surface),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isSelected ? brass : SAMsTheme.border),
                                      ),
                                      child: Center(
                                        child: isSelected
                                          ? Icon(Iconsax.tick_circle_copy, color: brass, size: 18)
                                          : Text(course['code'].toString().substring(0, min(3, course['code'].toString().length)), style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: muted)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(course['name'], style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                                          const SizedBox(height: 2),
                                          Text('${course['code']}  •  ${course['credits']} Credits  •  Quota: ${course['quota']}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: muted)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Footer with Credit Counter & Next Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: t.colorScheme.surface,
              border: Border(top: BorderSide(color: t.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TOTAL CREDITS', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: muted)),
                      const SizedBox(height: 2),
                      Text('$_totalCredits', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w400, color: t.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Material(
                        color: (_selectedCodes.isEmpty || !_sessionActive) ? (isDark ? SAMsTheme.surfaceLight : SAMsTheme.surface) : brass,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: (_selectedCodes.isEmpty || !_sessionActive) ? null : () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegistrationResult(selectedCourses: _allCourses.where((c) => _selectedCodes.contains(c['code'])).toList())),
                            );
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Next', style: TextStyle(fontFamily: 'Inter', color: (_selectedCodes.isEmpty || !_sessionActive) ? muted : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(width: 6),
                                Icon(Iconsax.arrow_right_3_copy, color: (_selectedCodes.isEmpty || !_sessionActive) ? muted : Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;
