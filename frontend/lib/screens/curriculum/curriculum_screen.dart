import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';

class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({super.key});

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _activities = [];
  List<dynamic> _myActivities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final all = await ApiService.get('/curriculum');
      final my = await ApiService.get('/curriculum/my/joined');
      setState(() {
        _activities = all;
        _myActivities = my;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinActivity(String id) async {
    try {
      await ApiService.post('/curriculum/$id/join', {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined activity!'), backgroundColor: SAMsTheme.success),
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
        title: const Text('Curriculum Activities'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SAMsTheme.accent,
          labelColor: SAMsTheme.accent,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          tabs: const [Tab(text: 'Explore'), Tab(text: 'Joined')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
          : TabBarView(
              controller: _tabController,
              children: [_buildExplore(), _buildJoined()],
            ),
    );
  }

  Widget _buildExplore() {
    if (_activities.isEmpty) {
      return Center(child: Text('No activities available', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text((activity['category'] ?? '').toUpperCase(), style: const TextStyle(color: SAMsTheme.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text('${activity['points'] ?? 0} pts', style: const TextStyle(color: SAMsTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(activity['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                  if (activity['description'] != null) ...[
                    const SizedBox(height: 6),
                    Text(activity['description'], style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text('${(activity['participants'] as List?)?.length ?? 0}/${activity['capacity']}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _joinActivity(activity['_id']),
                        style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                        child: const Text('Join', style: TextStyle(fontSize: 12, color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoined() {
    if (_myActivities.isEmpty) {
      return Center(child: Text('No joined activities', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myActivities.length,
      itemBuilder: (context, index) {
        final activity = _myActivities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emoji_events, color: SAMsTheme.accent, size: 20),
              ),
              title: Text(activity['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
              subtitle: Text(activity['category'] ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              trailing: Text('${activity['points'] ?? 0} pts', style: const TextStyle(color: SAMsTheme.accent, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
