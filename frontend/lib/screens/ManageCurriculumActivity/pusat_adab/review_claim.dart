import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ReviewClaimScreen extends StatefulWidget {
  const ReviewClaimScreen({super.key});

  @override
  State<ReviewClaimScreen> createState() => _ReviewClaimScreenState();
}

class _ReviewClaimScreenState extends State<ReviewClaimScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> claims = [];

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // GET /api/curriculum/claims/pending → returns pending CreditClaim docs
      // populated with student name/studentId and activity name
      final data = await ApiService.get('/curriculum/claims/pending');
      final List<dynamic> list =
          data is List ? data : (data['claims'] ?? []);
      setState(() {
        claims = list.map((e) => Map<String, dynamic>.from(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _reviewClaim(String claimId, String decision) async {
    try {
      // PUT /api/curriculum/claim/:claimId/review
      // body: { claimStatus: 'approved' | 'rejected' }
      await ApiService.put(
        '/curriculum/claim/$claimId/review',
        {'claimStatus': decision},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Claim ${decision == 'approved' ? 'approved' : 'rejected'} successfully.'),
            backgroundColor:
                decision == 'approved' ? SAMsTheme.success : SAMsTheme.error,
          ),
        );
        // Refresh list after action
        _fetchClaims();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _confirmReview(
      String claimId, String decision, String studentName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            decision == 'approved' ? 'Approve Claim' : 'Reject Claim'),
        content: Text(
          decision == 'approved'
              ? 'Approve credit claim from $studentName?'
              : 'Reject credit claim from $studentName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewClaim(claimId, decision);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  decision == 'approved' ? SAMsTheme.success : SAMsTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
                decision == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Credit Claims'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _fetchClaims,
          ),
        ],
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
                        onPressed: _fetchClaims,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : claims.isEmpty
                  ? const Center(
                      child: Text('No pending claims at the moment.'))
                  : RefreshIndicator(
                      onRefresh: _fetchClaims,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: claims.length,
                        itemBuilder: (context, index) {
                          final claim = claims[index];
                          final claimId = claim['_id'] ?? '';

                          // Student info (populated from backend)
                          final student = claim['student'];
                          final studentName = student is Map
                              ? (student['name'] ?? '-')
                              : '-';
                          final studentId = student is Map
                              ? (student['studentId'] ?? '-')
                              : '-';

                          // Activity info (populated via registration)
                          final registration = claim['registration'];
                          final activity = registration is Map
                              ? registration['activity']
                              : null;
                          final activityName = activity is Map
                              ? (activity['name'] ?? '-')
                              : '-';
                          final activityPoints = activity is Map
                              ? (activity['points'] ?? 0)
                              : 0;

                          final supportingClaim =
                              claim['supportingClaim'] ?? '-';

                          String claimDateStr = '-';
                          if (claim['createdAt'] != null) {
                            try {
                              claimDateStr = DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(
                                      claim['createdAt']));
                            } catch (_) {}
                          }

                          return GlassCard(
                            margin:
                                const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Activity name header
                                  Text(
                                    activityName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const Divider(height: 20),

                                  _infoRow('Student ID', studentId),
                                  _infoRow(
                                      'Student Name', studentName),
                                  _infoRow('Credit Points',
                                      '$activityPoints pts'),
                                  _infoRow(
                                      'Claim Date', claimDateStr),

                                  const SizedBox(height: 8),

                                  // Supporting claim text
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: SAMsTheme.textSecondary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: SAMsTheme.textSecondary
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Supporting Claim:',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(supportingClaim,
                                            style: const TextStyle(
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Approve / Reject buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _confirmReview(
                                            claimId,
                                            'approved',
                                            studentName,
                                          ),
                                          icon:
                                              const Icon(Iconsax.tick_circle),
                                          label: const Text('Approve'),
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor:
                                                SAMsTheme.success,
                                            foregroundColor:
                                                Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _confirmReview(
                                            claimId,
                                            'rejected',
                                            studentName,
                                          ),
                                          icon:
                                              const Icon(Iconsax.close_circle),
                                          label: const Text('Reject'),
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor:
                                                SAMsTheme.error,
                                            foregroundColor:
                                                Colors.white,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}