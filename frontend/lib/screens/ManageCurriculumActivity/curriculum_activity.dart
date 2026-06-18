import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'activity_detail.dart';

class CurriculumActivityScreen extends StatefulWidget {
  const CurriculumActivityScreen({super.key});

  @override
  State<CurriculumActivityScreen> createState() => _CurriculumActivityScreenState();
}

class _CurriculumActivityScreenState extends State<CurriculumActivityScreen> {
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  // Backend enum: ['club', 'sport', 'event', 'workshop', 'community']
  static const _categories = ['All', 'Sport', 'Event', 'Club', 'Workshop', 'Community'];
  // Map display label → backend value for comparison
  static const _catMap = {
    'All': 'all',
    'Sport': 'sport',
    'Event': 'event',
    'Club': 'club',
    'Workshop': 'workshop',
    'Community': 'community',
  };

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await ApiService.get('/curriculum');
      final List<dynamic> list = data is List ? data : (data['activities'] ?? []);
      if (!mounted) return;
      setState(() {
        _activities = list.map((e) => Map<String, dynamic>.from(e)).toList();
        _filtered = _activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    final selectedBackend = _catMap[_selectedCategory] ?? 'all';
    setState(() {
      _filtered = _activities.where((a) {
        final name = (a['name'] ?? a['activityName'] ?? '').toString().toLowerCase();
        final cat = (a['category'] ?? a['activityCategory'] ?? '').toString().toLowerCase();
        final matchSearch = q.isEmpty || name.contains(q);
        final matchCat = selectedBackend == 'all' || cat == selectedBackend;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Curriculum Activities', style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface)),
        backgroundColor: t.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_copy, color: t.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // search bar
            TextField(
              controller: _searchController,
              style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search activity...',
                hintStyle: TextStyle(color: t.textTheme.bodySmall?.color, fontFamily: 'Inter'),
                prefixIcon: Icon(Iconsax.search_normal_1, color: t.textTheme.bodySmall?.color, size: 18),
                filled: true,
                fillColor: t.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SAMsTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in _categories) _categoryChip(cat, t),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
                  : _errorMessage != null
                      ? _errorState(t)
                      : _filtered.isEmpty
                          ? Center(child: Text('No activities found.', style: TextStyle(color: t.textTheme.bodySmall?.color, fontFamily: 'Inter')))
                          : RefreshIndicator(
                              onRefresh: _fetchActivities,
                              color: SAMsTheme.accent,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (ctx, i) => _activityCard(_filtered[i], t),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(ThemeData t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: SAMsTheme.error, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchActivities, child: const Text('Retry')),
        ],
      ),
    );
  }

  // activity card
  Widget _activityCard(Map<String, dynamic> activity, ThemeData t) {
    final name = activity['name'] ?? activity['activityName'] ?? '-';
    final category = (activity['category'] ?? activity['activityCategory'] ?? '').toString();
    final status = (activity['status'] ?? activity['activityStatus'] ?? 'upcoming').toString();
    final slots = activity['capacity'] ?? activity['availableSlots'] ?? 0;
    final points = activity['points'] ?? activity['creditHours'] ?? 0;
    final id = activity['_id'] ?? activity['id'] ?? '';
    final participants = activity['participants'];
    final participantCount = participants is List ? participants.length : 0;
    final venue = activity['venue'] ?? activity['activityLocation'] ?? '';

    // Capitalize category for display
    final catDisplay = category.isEmpty ? '-' : category[0].toUpperCase() + category.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // category tag + status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SAMsTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      catDisplay.toUpperCase(),
                      style: TextStyle(
                        color: SAMsTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 10),
              // title
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: t.colorScheme.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              // category + slots
              Row(
                children: [
                  Text(
                    'Category: $catDisplay',
                    style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12, fontFamily: 'Inter'),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Slots: $participantCount/$slots',
                    style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12, fontFamily: 'Inter'),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Points: $points',
                    style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              ),
              if (venue.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  venue,
                  style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 11, fontFamily: 'Inter'),
                ),
              ],
              const SizedBox(height: 10),
              // view details
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityDetailScreen(
                      activityId: id,
                      title: name,
                      category: catDisplay,
                      location: venue,
                      creditHours: points is int ? points : (points as num).toInt(),
                      slots: slots is int ? slots : (slots as num).toInt(),
                    ),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: SAMsTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // status badge
  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = SAMsTheme.success.withValues(alpha: 0.15);
        fg = SAMsTheme.success;
        label = 'completed';
        break;
      case 'ongoing':
        bg = SAMsTheme.warning.withValues(alpha: 0.15);
        fg = SAMsTheme.warning;
        label = 'ongoing';
        break;
      default:
        bg = SAMsTheme.accent.withValues(alpha: 0.15);
        fg = SAMsTheme.accent;
        label = 'upcoming';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
    );
  }

  // category chip
  Widget _categoryChip(String category, ThemeData t) {
    final selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          category,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: selected ? Colors.white : t.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: SAMsTheme.accent,
        backgroundColor: t.colorScheme.surface,
        side: BorderSide(color: selected ? SAMsTheme.accent : t.dividerColor),
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          _applyFilter();
        },
      ),
    );
  }
}
