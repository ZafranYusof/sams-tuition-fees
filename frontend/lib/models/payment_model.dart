class PaymentModel {
  final String id;
  final String studentId;
  final String feeId;
  final double amount;
  final String method;
  final String? transactionId;
  final String? bank;
  final String status;
  final DateTime paidAt;
  final String? receipt;

  PaymentModel({
    required this.id,
    required this.studentId,
    required this.feeId,
    required this.amount,
    required this.method,
    this.transactionId,
    this.bank,
    required this.status,
    required this.paidAt,
    this.receipt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['student'] is Map ? json['student']['_id'] : (json['student'] ?? ''),
      feeId: json['fee'] is Map ? json['fee']['_id'] : (json['fee'] ?? ''),
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'] ?? 'fpx',
      transactionId: json['transactionId'],
      bank: json['bank'],
      status: json['status'] ?? 'pending',
      paidAt: DateTime.tryParse(json['paidAt'] ?? '') ?? DateTime.now(),
      receipt: json['receipt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'student': studentId,
      'fee': feeId,
      'amount': amount,
      'method': method,
      'transactionId': transactionId,
      'bank': bank,
      'status': status,
      'paidAt': paidAt.toIso8601String(),
      'receipt': receipt,
    };
  }

  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get methodLabel {
    switch (method) {
      case 'fpx':
        return 'FPX Online Banking';
      case 'card':
        return 'Credit/Debit Card';
      case 'cash':
        return 'Cash Payment';
      case 'scholarship':
        return 'Scholarship';
      default:
        return method.toUpperCase();
    }
  }
}
