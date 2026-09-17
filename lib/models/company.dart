class Company {
  final String id;
  String name;
  double balance;
  /// Çalışan başına uygulanacak aylık maaş üst sınırı.
  double salaryLimit;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.balance,
    this.salaryLimit = 50000,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'salaryLimit': salaryLimit,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id']?.toString() ?? 'comp-0',
        name: json['name']?.toString() ?? 'Şirket',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        salaryLimit: (json['salaryLimit'] as num?)?.toDouble() ?? 50000.0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
