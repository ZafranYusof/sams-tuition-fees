import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'RegistrationResult.dart';

class SubjectRegistration extends StatefulWidget {
  const SubjectRegistration({super.key});

  @override
  State<SubjectRegistration> createState() => _SubjectRegistrationState();
}

class _SubjectRegistrationState extends State<SubjectRegistration> {
  // Mock data for demonstration - in production, this would come from a provider or API
  final List<Map<String, dynamic>> _allCourses = [
    {'code': 'CS101', 'name': 'Intro to Programming', 'credits': 3, 'quota': 5},
    {'code': 'CS202', 'name': 'Data Structures', 'credits': 4, 'quota': 2},
    {'code': 'MA101', 'name': 'Calculus I', 'credits': 3, 'quota': 10},
  ];

  final List<String> _selectedCodes = [];
  String _searchQuery = '';

  int get _totalCredits => _allCourses
      .where((c) => _selectedCodes.contains(c['code']))
      .fold(0, (sum, c) => sum + (c['credits'] as int));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final filteredCourses = _allCourses.where((c) => 
      c['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Subject Registration')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(labelText: 'Search Subjects', prefixIcon: Icon(Iconsax.search_normal_copy)),
            ),
          ),
          
          // Course List
          Expanded(
            child: ListView.builder(
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                final isSelected = _selectedCodes.contains(course['code']);
                return ListTile(
                  title: Text(course['name']),
                  subtitle: Text('${course['credits']} Credits'),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        val == true ? _selectedCodes.add(course['code']) : _selectedCodes.remove(course['code']);
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Footer with Credit Counter & Next Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: t.cardColor, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: $_totalCredits Credits', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _selectedCodes.isEmpty ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegistrationResult(selectedCodes: _selectedCodes)),
                    );
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}