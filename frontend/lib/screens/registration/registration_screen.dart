import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _courses = [];
  List<dynamic> _myRegistrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final courses = await ApiService.get('/registration/courses');
      final my = await ApiService.get('/registration/my');
      setState(() {
        _courses = courses;
        _myRegistrations = my;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _registerCourse(String courseId) async {
    try {
      await ApiService.post('/registration/register', {
        'courseId': courseId,
        'semester': 1,
        'academicYear': '2025/2026',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course registered!'), backgroundColor: SAMsTheme.success),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Registration'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SAMsTheme.primary,
          labelColor: SAMsTheme.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          tabs: const [Tab(text: 'Available'), Tab(text: 'My Courses')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildCourseList(), _buildMyRegistrations()],
            ),
    );
  }

  Widget _buildCourseList() {
    if (_courses.isEmpty) {
      return Center(child: Text('No courses available', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(course['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${course['code']} | ${course['creditHours']} credits', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${course['enrolled']}/${course['capacity']} enrolled', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _registerCourse(course['_id']),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                child: const Text('Register', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyRegistrations() {
    if (_myRegistrations.isEmpty) {
      return Center(child: Text('No registered courses', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRegistrations.length,
      itemBuilder: (context, index) {
        final reg = _myRegistrations[index];
        final course = reg['course'] ?? {};
        final status = reg['status'] ?? 'pending';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(course['name'] ?? 'Unknown', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
              subtitle: Text(course['code'] ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'registered' ? SAMsTheme.success.withOpacity(0.15) : SAMsTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(color: status == 'registered' ? SAMsTheme.success : SAMsTheme.warning, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      },
    );
  }
}
