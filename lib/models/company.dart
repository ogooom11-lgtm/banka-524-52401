class Company {
  final String id;
  String name;
  double balance;

  /// Çalışan başına uygulanacak aylık maaş üst sınırı.
  double salaryLimit;

  /// Otomatik maaş dağıtımında kullanılan alt sınır (0 = limitin %50'si).
  double salaryMin;

  final DateTime createdAt;

  // --- Genişletilmiş alanlar ---
  String sector;
  String taxNumber;
  String address;
  String contactEmail;
  String contactPhone;
  int colorValue; // ARGB
  bool isActive;
  String notes;

  Company({
    required this.id,
    required this.name,
    required this.balance,
    this.salaryLimit = 50000,
    this.salaryMin = 0,
    required this.createdAt,
    this.sector = '',
    this.taxNumber = '',
    this.address = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.colorValue = 0,
    this.isActive = true,
    this.notes = '',
  });

  double get effectiveSalaryMin {
    if (salaryMin > 0) return salaryMin.clamp(0.0, salaryLimit);
    return salaryLimit * 0.5;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'salaryLimit': salaryLimit,
        'salaryMin': salaryMin,
        'createdAt': createdAt.toIso8601String(),
        'sector': sector,
        'taxNumber': taxNumber,
        'address': address,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'colorValue': colorValue,
        'isActive': isActive,
        'notes': notes,
      };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id']?.toString() ?? 'comp-0',
        name: json['name']?.toString() ?? 'Şirket',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        salaryLimit: (json['salaryLimit'] as num?)?.toDouble() ?? 50000.0,
        salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        sector: json['sector']?.toString() ?? '',
        taxNumber: json['taxNumber']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        contactEmail: json['contactEmail']?.toString() ?? '',
        contactPhone: json['contactPhone']?.toString() ?? '',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        notes: json['notes']?.toString() ?? '',
      );

  Company copy() => Company.fromJson(toJson());
}
