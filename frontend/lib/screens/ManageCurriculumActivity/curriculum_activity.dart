import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  bool isLoading = true;
  String? errorMessage;

  // Real data from backend
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // GET /api/curriculum returns a list of Activity objects
      final data = await ApiService.get('/curriculum');
      final List<dynamic> list = data is List ? data : (data['activities'] ?? []);
      setState(() {
        activities = list.map((e) => Map<String, dynamic>.from(e)).toList();
        filteredActivities = activities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredActivities = activities.where((activity) {
        final name = (activity['name'] ?? activity['activityName'] ?? '').toString().toLowerCase();
        final category = (activity['category'] ?? activity['activityCategory'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty || name.contains(query);
        final matchesCategory = selectedCategory == 'All' ||
            category == selectedCategory.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Activities'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search activity...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: SAMsTheme.error),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchActivities,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredActivities.isEmpty
                          ? const Center(child: Text('No activities found.'))
                          : ListView.builder(
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) {
                                final activity = filteredActivities[index];
                                // Backend uses either 'name' or 'activityName'
                                final name = activity['name'] ?? activity['activityName'] ?? '-';
                                final category = activity['category'] ?? activity['activityCategory'] ?? '-';
                                final status = activity['status'] ?? activity['activityStatus'] ?? '-';
                                final slots = activity['capacity'] ?? activity['availableSlots'] ?? 0;
                                final creditHours = activity['points'] ?? activity['creditHours'] ?? 0;
                                final location = activity['venue'] ?? activity['activityLocation'] ?? '-';
                                // Backend _id is the real MongoDB id
                                final id = activity['_id'] ?? activity['id'] ?? '';

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
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: SAMsTheme.accent,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Category: $category'),
                                          const SizedBox(height: 4),
                                          Text('Available Slots: $slots'),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ActivityDetailScreen(
                                                      activityId: id,
                                                      title: name,
                                                      category: category,
                                                      location: location,
                                                      creditHours: creditHours is int
                                                          ? creditHours
                                                          : (creditHours as num).toInt(),
                                                      slots: slots is int
                                                          ? slots
                                                          : (slots as num).toInt(),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('View Details'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    final selected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedCategory = category;
          });
          _applyFilter();
        },
      ),
    );
  }
}