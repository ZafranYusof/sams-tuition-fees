class UserModel {
  final String id;
  final String studentId;
  final String name;
  final String email;
  final String role;
  final String? faculty;
  final String? program;
  final int semester;
  final String? phone;
  final String? avatar;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.role,
    this.faculty,
    this.program,
    this.semester = 1,
    this.phone,
    this.avatar,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      faculty: json['faculty'],
      program: json['program'],
      semester: json['semester'] ?? 1,
      phone: json['phone'],
      avatar: json['avatar'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'name': name,
      'email': email,
      'role': role,
      'faculty': faculty,
      'program': program,
      'semester': semester,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
}
