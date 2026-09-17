enum UserRole { superAdmin, companyAdmin, employee }

class AppUser {
  final String id;
  String fullName;
  final String email;
  final String passwordHash;
  UserRole role;
  String? companyId; // null for superAdmin or unassigned
  String title;
  double salary;
  double bonus; // aylık performans primi
  double balance; // kişisel bakiye
  DateTime salaryDate; // maaş günü
  DateTime contractStart;
  DateTime contractEnd;
  double terminationFee; // sözleşme erken fesih ücreti
  bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.companyId,
    this.title = 'Çalışan',
    this.salary = 0,
    this.bonus = 0,
    this.balance = 0,
    required this.salaryDate,
    required this.contractStart,
    required this.contractEnd,
    this.terminationFee = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'companyId': companyId,
        'title': title,
        'salary': salary,
        'bonus': bonus,
        'balance': balance,
        'salaryDate': salaryDate.toIso8601String(),
        'contractStart': contractStart.toIso8601String(),
        'contractEnd': contractEnd.toIso8601String(),
        'terminationFee': terminationFee,
        'isActive': isActive,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return AppUser(
      id: json['id']?.toString() ?? 'usr-${now.microsecondsSinceEpoch}',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      companyId: json['companyId']?.toString(),
      title: json['title']?.toString() ?? 'Çalışan',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      salaryDate: DateTime.tryParse(json['salaryDate']?.toString() ?? '') ??
          DateTime(now.year, now.month, 1),
      contractStart:
          DateTime.tryParse(json['contractStart']?.toString() ?? '') ?? now,
      contractEnd:
          DateTime.tryParse(json['contractEnd']?.toString() ?? '') ??
              now.add(const Duration(days: 365)),
      terminationFee:
          (json['terminationFee'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
