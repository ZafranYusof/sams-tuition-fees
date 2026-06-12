class FeeItem {
  final String description;
  final double amount;
  final String category;

  FeeItem({
    required this.description,
    required this.amount,
    required this.category,
  });

  factory FeeItem.fromJson(Map<String, dynamic> json) {
    return FeeItem(
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
    };
  }
}

class FeeModel {
  final String id;
  final String studentId;
  final int semester;
  final String academicYear;
  final List<FeeItem> items;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.semester,
    required this.academicYear,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.status,
    this.dueDate,
    required this.createdAt,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['student'] is Map ? json['student']['_id'] : (json['student'] ?? ''),
      semester: json['semester'] ?? 1,
      academicYear: json['academicYear'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => FeeItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'unpaid',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'student': studentId,
      'semester': semester,
      'academicYear': academicYear,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get outstandingAmount => totalAmount - paidAmount;
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
  double get paymentProgress => totalAmount > 0 ? paidAmount / totalAmount : 0;
}
