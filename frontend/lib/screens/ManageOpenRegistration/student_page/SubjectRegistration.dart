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

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/registration/courses');
      if (data is List) {
        setState(() {
          _allCourses = List<Map<String, dynamic>>.from(data.map((c) => {
            'code': c['courseId'] ?? c['code'] ?? '',
            'name': c['courseName'] ?? c['name'] ?? '',
            'credits': c['creditHours'] ?? c['credits'] ?? 0,
            'quota': c['quota'] ?? 0,
          }));
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load courses'; _loading = false; });
    }
  }

  int get _totalCredits => _allCourses
      .where((c) => _selectedCodes.contains(c['code']))
      .fold(0, (sum, c) => sum + (c['credits'] as int));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = SAMsTheme.textMuted;
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? SAMsTheme.cardDark : SAMsTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SAMsTheme.border),
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
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  isSelected
                                    ? _selectedCodes.remove(course['code'])
                                    : _selectedCodes.add(course['code']);
                                });
                              },
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
              color: isDark ? SAMsTheme.cardDark : Colors.white,
              border: Border(top: BorderSide(color: SAMsTheme.border)),
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
                        color: _selectedCodes.isEmpty ? (isDark ? SAMsTheme.surfaceLight : SAMsTheme.surface) : brass,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _selectedCodes.isEmpty ? null : () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegistrationResult(selectedCodes: _selectedCodes)),
                            );
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Next', style: TextStyle(fontFamily: 'Inter', color: _selectedCodes.isEmpty ? muted : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(width: 6),
                                Icon(Iconsax.arrow_right_3_copy, color: _selectedCodes.isEmpty ? muted : Colors.white, size: 16),
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
