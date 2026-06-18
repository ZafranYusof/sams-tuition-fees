// lib/models/StudentSubject.dart

class StudentSubject {
  final String studentId;
  final String courseCode;
  final String courseName;
  final DateTime registrationTimestamp;
  final String status; // e.g., 'Registered', 'Pending', 'Dropped'

  StudentSubject({
    required this.studentId,
    required this.courseCode,
    required this.courseName,
    required this.registrationTimestamp,
    this.status = 'Registered',
  });

  // Useful for displaying in the "History" tab of the Student Dashboard
  String get formattedTimestamp {
    return "${registrationTimestamp.day}/${registrationTimestamp.month}/${registrationTimestamp.year} "
           "${registrationTimestamp.hour}:${registrationTimestamp.minute}";
  }
}