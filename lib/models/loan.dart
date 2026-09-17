/// Çalışan kredisi (taksitli avans) modeli.
class Loan {
  final String id;
  final String userId;
  final double principal; // kullanılan kredi tutarı
  final double totalPayable; // faiz dahil toplam geri ödeme
  final double installmentAmount; // aylık taksit
  final int totalInstallments;
  int paidInstallments;
  final DateTime startDate;
  DateTime nextDueDate;
  bool isActive;
  String note;

  Loan({
    required this.id,
    required this.userId,
    required this.principal,
    required this.totalPayable,
    required this.installmentAmount,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
    this.note = '',
  });

  double get remaining => (totalPayable - installmentAmount * paidInstallments)
      .clamp(0, double.infinity)
      .toDouble();

  double get paidAmount => installmentAmount * paidInstallments;

  double get progress =>
      totalInstallments == 0 ? 0 : paidInstallments / totalInstallments;

  bool get isFinished => paidInstallments >= totalInstallments || remaining <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'principal': principal,
        'totalPayable': totalPayable,
        'installmentAmount': installmentAmount,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'isActive': isActive,
        'note': note,
      };

  factory Loan.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final start =
        DateTime.tryParse(json['startDate']?.toString() ?? '') ?? now;
    return Loan(
      id: json['id']?.toString() ?? 'loan-0',
      userId: json['userId']?.toString() ?? '',
      principal: (json['principal'] as num?)?.toDouble() ?? 0,
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0,
      installmentAmount: (json['installmentAmount'] as num?)?.toDouble() ?? 0,
      totalInstallments:
          (json['totalInstallments'] as num?)?.toInt().abs() ?? 1,
      paidInstallments: (json['paidInstallments'] as num?)?.toInt() ?? 0,
      startDate: start,
      nextDueDate: DateTime.tryParse(json['nextDueDate']?.toString() ?? '') ??
          start.add(const Duration(days: 30)),
      isActive: json['isActive'] as bool? ?? true,
      note: json['note']?.toString() ?? '',
    );
  }
}
