class Student {
  final String id;
  final String name;
  final String email;
  final int creditLimit;
  final List<String> registeredSubjectCodes;
  final double outstandingBalance;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.creditLimit = 20,
    this.registeredSubjectCodes = const [],
    this.outstandingBalance = 0.0,
  });

  // Calculate current total credits based on subjects
  // (In a real app, this would cross-reference with a Subject model)
  int calculateCurrentCredits(List<Map<String, dynamic>> allSubjects) {
    return allSubjects
        .where((s) => registeredSubjectCodes.contains(s['code']))
        .fold(0, (sum, s) => sum + (s['credits'] as int? ?? 0));
  }

  // Method to check if adding a subject is valid
  bool canRegister(int subjectCredits, List<Map<String, dynamic>> allSubjects) {
    return (calculateCurrentCredits(allSubjects) + subjectCredits) <= creditLimit;
  }
}