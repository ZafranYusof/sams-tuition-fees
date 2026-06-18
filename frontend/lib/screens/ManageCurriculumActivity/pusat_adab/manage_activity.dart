import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../widgets/glass_card.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class ManageActivityScreen extends StatefulWidget {
  const ManageActivityScreen({super.key});

  @override
  State<ManageActivityScreen> createState() => _ManageActivityScreenState();
}

class _ManageActivityScreenState extends State<ManageActivityScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // GET /api/curriculum → returns list of Activity documents
      final data = await ApiService.get('/curriculum');
      final List<dynamic> list = data is List ? data : [];
      setState(() {
        activities = list.map((e) => Map<String, dynamic>.from(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActivityFormSheet(
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          _fetchActivities();
        },
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: SAMsTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // PUT with status cancelled is a soft-delete workaround since
      // ApiService has no delete method. If you add ApiService.delete later,
      // replace this with: await ApiService.delete('/curriculum/$id');
      await ApiService.put('/curriculum/$id', {'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity removed.')),
        );
        _fetchActivities();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'upcoming':
        return SAMsTheme.primary;
      case 'ongoing':
        return SAMsTheme.success;
      case 'completed':
        return SAMsTheme.textSecondary;
      case 'cancelled':
        return SAMsTheme.error;
      default:
        return SAMsTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activities'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        backgroundColor: SAMsTheme.accent,
        foregroundColor: SAMsTheme.ink,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!,
                          style: const TextStyle(color: SAMsTheme.error),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchActivities,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : activities.isEmpty
                  ? const Center(
                      child: Text('No activities yet. Tap + to add one.'))
                  : RefreshIndicator(
                      onRefresh: _fetchActivities,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final a = activities[index];
                          final name = a['name'] ?? '-';
                          final category = a['category'] ?? '-';
                          final venue = a['venue'] ?? '-';
                          final points = a['points'] ?? 0;
                          final capacity = a['capacity'] ?? 0;
                          final status = a['status'] ?? 'upcoming';
                          final id = a['_id'] ?? '';

                          String dateStr = '-';
                          if (a['date'] != null) {
                            try {
                              dateStr = DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(a['date']));
                            } catch (_) {}
                          }

                          return GlassCard(
                                                      margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Name + status badge
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
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  _statusColor(status)),
                                        ),
                                        child: Text(
                                          status[0].toUpperCase() +
                                              status.substring(1),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  _row(Iconsax.category, category),
                                  _row(Iconsax.location, venue),
                                  _row(Iconsax.calendar_1, dateStr),
                                  _row(Iconsax.medal_star,
                                      '$points credit points'),
                                  _row(Iconsax.people,
                                      '$capacity slots'),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showForm(existing: a),
                                          icon: const Icon(Iconsax.edit, size: 16),
                                          label: const Text('Edit'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _confirmDelete(id, name),
                                          icon: const Icon(Iconsax.trash, size: 16, color: SAMsTheme.error),
                                          label: const Text('Delete',
                                              style: TextStyle(
                                                  color: SAMsTheme.error)),
                                          style:
                                              OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: SAMsTheme.error),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SAMsTheme.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Form Bottom Sheet ──────────────────────────────────────────────

class _ActivityFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _ActivityFormSheet({this.existing, required this.onSaved});

  @override
  State<_ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<_ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final organizerCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  final pointsCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();

  // Backend Activity model: category enum: 'club','sport','event','workshop','community'
  String selectedCategory = 'sport';
  String selectedStatus = 'upcoming';
  DateTime? selectedDate;
  bool isSaving = false;

  final List<String> categories = [
    'club', 'sport', 'event', 'workshop', 'community'
  ];
  final List<String> statuses = [
    'upcoming', 'ongoing', 'completed', 'cancelled'
  ];

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final a = widget.existing!;
      nameCtrl.text = a['name'] ?? '';
      descCtrl.text = a['description'] ?? '';
      organizerCtrl.text = a['organizer'] ?? '';
      venueCtrl.text = a['venue'] ?? '';
      pointsCtrl.text = (a['points'] ?? 0).toString();
      capacityCtrl.text = (a['capacity'] ?? 0).toString();
      selectedCategory = a['category'] ?? 'sport';
      selectedStatus = a['status'] ?? 'upcoming';
      if (a['date'] != null) {
        try {
          selectedDate = DateTime.parse(a['date']);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    organizerCtrl.dispose();
    venueCtrl.dispose();
    pointsCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an activity date.')),
      );
      return;
    }

    setState(() => isSaving = true);

    // Field names match Activity.js model exactly
    final body = {
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'category': selectedCategory,
      'organizer': organizerCtrl.text.trim(),
      'date': selectedDate!.toIso8601String(),
      'venue': venueCtrl.text.trim(),
      'points': int.tryParse(pointsCtrl.text) ?? 0,
      'capacity': int.tryParse(capacityCtrl.text) ?? 100,
      'status': selectedStatus,
    };

    try {
      if (isEdit) {
        final id = widget.existing!['_id'];
        // PUT /api/curriculum/:id
        await ApiService.put('/curriculum/$id', body);
      } else {
        // POST /api/curriculum
        await ApiService.post('/curriculum', body);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Activity' : 'Add New Activity',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Activity Name *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder()),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                              c[0].toUpperCase() + c.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: organizerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Organizer',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: selectedDate == null
                          ? 'Activity Date *'
                          : DateFormat('dd MMM yyyy')
                              .format(selectedDate!),
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          const Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: venueCtrl,
                decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Credit Points',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Capacity',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status — edit mode only
              if (isEdit) ...[
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder()),
                  items: statuses
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                s[0].toUpperCase() + s.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SAMsTheme.accent,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : Text(isEdit
                          ? 'Save Changes'
                          : 'Add Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}