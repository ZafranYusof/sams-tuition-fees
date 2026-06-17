class Subject {
  final String code;
  final String name;
  final int credits;
  final int quota;
  final String faculty;
  final String timeSlot;
  int enrolledCount;

  Subject({
    required this.code,
    required this.name,
    required this.credits,
    required this.quota,
    required this.faculty,
    required this.timeSlot,
    this.enrolledCount = 0,
  });

  // Helper to check availability
  bool get hasCapacity => enrolledCount < quota;

  // Method to increment enrollment
  void enroll() {
    if (hasCapacity) {
      enrolledCount++;
    }
  }

  // Factory to create from your existing Map structure (if needed for migration)
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      credits: map['credits'] ?? 3,
      quota: map['quota'] ?? 0,
      faculty: map['faculty'] ?? 'Unknown',
      timeSlot: map['timeSlot'] ?? 'N/A',
      enrolledCount: map['enrolledCount'] ?? 0,
    );
  }
}