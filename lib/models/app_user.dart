enum UserRole {
  superAdmin('Süper Admin', 'Banka sahibi - sınırsız yetki'),
  companyAdmin('Şirket Yöneticisi', 'Şirket bazlı yönetici'),
  employee('Çalışan', 'Şirket çalışanı');

  final String label;
  final String description;
  const UserRole(this.label, this.description);

  static UserRole fromName(String? name) {
    for (final r in UserRole.values) {
      if (r.name == name) return r;
    }
    return UserRole.employee;
  }
}

class AppUser {
  final String id;
  String fullName;
  String email;
  String passwordHash;
  UserRole role;
  String? companyId; // superAdmin veya atanmamış kullanıcılar için null
  String title;
  double salary;
  double bonus; // aylık performans primi
  double balance; // kişisel bakiye
  DateTime salaryDate; // maaş günü
  DateTime contractStart;
  DateTime contractEnd;
  double terminationFee; // sözleşme erken fesih ücreti
  bool isActive;

  // --- Genişletilmiş alanlar (tam özelleştirme) ---
  String phone;
  String iban;
  String department;
  String notes;
  DateTime hireDate;
  int avatarColor; // ARGB; 0 ise otomatik renk üretilir
  DateTime? lastLogin;

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
    this.phone = '',
    this.iban = '',
    this.department = '',
    this.notes = '',
    DateTime? hireDate,
    this.avatarColor = 0,
    this.lastLogin,
  }) : hireDate = hireDate ?? contractStart;

  // --------- Türetilmiş bilgiler ---------
  int get contractDaysLeft =>
      contractEnd.difference(DateTime.now()).inDays;

  bool get isContractExpired =>
      contractEnd.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  bool get isContractExpiringSoon {
    final d = contractDaysLeft;
    return !isContractExpired && d <= 30;
  }

  double get monthlyCost => salary + bonus;

  String get roleLabel => role.label;

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
        'phone': phone,
        'iban': iban,
        'department': department,
        'notes': notes,
        'hireDate': hireDate.toIso8601String(),
        'avatarColor': avatarColor,
        'lastLogin': lastLogin?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final start = DateTime.tryParse(json['contractStart']?.toString() ?? '') ??
        now;
    return AppUser(
      id: json['id']?.toString() ?? 'usr-${now.microsecondsSinceEpoch}',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? '',
      role: UserRole.fromName(json['role']?.toString()),
      companyId: json['companyId']?.toString(),
      title: json['title']?.toString() ?? 'Çalışan',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      salaryDate: DateTime.tryParse(json['salaryDate']?.toString() ?? '') ??
          DateTime(now.year, now.month, 1),
      contractStart: start,
      contractEnd:
          DateTime.tryParse(json['contractEnd']?.toString() ?? '') ??
              now.add(const Duration(days: 365)),
      terminationFee: (json['terminationFee'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      phone: json['phone']?.toString() ?? '',
      iban: json['iban']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      hireDate: DateTime.tryParse(json['hireDate']?.toString() ?? '') ?? start,
      avatarColor: (json['avatarColor'] as num?)?.toInt() ?? 0,
      lastLogin: DateTime.tryParse(json['lastLogin']?.toString() ?? ''),
    );
  }

  AppUser copy() => AppUser.fromJson(toJson());
}
