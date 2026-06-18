import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'activity_detail.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';

class CurriculumActivityScreen extends ConsumerStatefulWidget {
  const CurriculumActivityScreen({super.key});

  @override
  ConsumerState<CurriculumActivityScreen> createState() =>
      _CurriculumActivityScreenState();
}

class _CurriculumActivityScreenState
    extends ConsumerState<CurriculumActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _filtered = [];

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
    setState(() {
      _filtered = _activities.where((a) {
        final name = (a['name'] ?? a['activityName'] ?? '').toString().toLowerCase();
        final cat = (a['category'] ?? a['activityCategory'] ?? '').toString().toLowerCase();
        final matchSearch = q.isEmpty || name.contains(q);
        final matchCat = _selectedCategory == 'All' || cat == _selectedCategory.toLowerCase();
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
        title: const Text('Curriculum Activities'),
        leading: IconButton(
          Icon(Iconsax.refresh, color: t.colorScheme.onSurface
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── search bar ──
            TextField(
              controller: _searchController,
              style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search activity...',
                hintStyle: TextStyle(color: t.textTheme.bodySmall?.color, fontFamily: 'Inter'),
                prefixIcon: Icon(Iconsax.search_normal_1, color: t.textTheme.bodySmall?.color, size: 18),
                filled: true,
                fillColor: SAMsTheme.surface,
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
                  borderSide: const BorderSide(color: SAMsTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ── filter chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('All'),
                  _categoryChip('Sports'),
                  _categoryChip('Cultural'),
                  _categoryChip('Academic'),
                  _categoryChip('Community'),
                  _categoryChip('Leadership'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ── list ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
                  : _errorMessage != null
                      ? _errorState()
                      : _filtered.isEmpty
                          ? Center(child: Text('No activities found.', style: TextStyle(color: t.textTheme.bodySmall?.color, fontFamily: 'Inter')))
                          : RefreshIndicator(
                              onRefresh: _fetchActivities,
                              color: SAMsTheme.accent,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (ctx, i) => _activityCard(_filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: SAMsTheme.error, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchActivities, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ── activity card ──────────────────────────────────────
  Widget _activityCard(Map<String, dynamic> activity) {
    final t = Theme.of(context);
    final name = activity['name'] ?? activity['activityName'] ?? '-';
    final category = (activity['category'] ?? activity['activityCategory'] ?? '').toString();
    final status = (activity['status'] ?? activity['activityStatus'] ?? 'upcoming').toString();
    final slots = activity['capacity'] ?? activity['availableSlots'] ?? 0;
    final points = activity['points'] ?? activity['creditHours'] ?? 0;
    final id = activity['_id'] ?? activity['id'] ?? '';
    final participants = activity['participants'];
    final participantCount = participants is List ? participants.length : 0;
    final venue = activity['venue'] ?? activity['activityLocation'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── top row: category tag + status badge ──
              Row(
                children: [
                  // category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SAMsTheme.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const Spacer(),
                  // status badge
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 10),
              // ── title ──
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: t.colorScheme.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              // ── category + slots ──
              Row(
                children: [
                  Text(
                    'Category: ${category.isEmpty ? "-" : category}',
                    style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12, fontFamily: 'Inter'),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Available Slots: $slots',
                    style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── view details ──
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityDetailScreen(
                      activityId: id,
                      title: name,
                      category: category,
                      location: venue,
                      creditHours: points is int ? points : (points as num).toInt(),
                      slots: slots is int ? slots : (slots as num).toInt(),
                    ),
                  ),
                ),
                child: const Text(
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

  // ── status badge ───────────────────────────────────────
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

  // ── category chip ──────────────────────────────────────
  Widget _categoryChip(String category) {
    final selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          category,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: selected ? Colors.white : SAMsTheme.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: SAMsTheme.accent,
        backgroundColor: SAMsTheme.surface,
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
