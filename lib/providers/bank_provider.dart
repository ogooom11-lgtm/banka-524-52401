import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/bank_settings.dart';
import '../models/company.dart';
import '../models/loan.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

export '../models/app_notification.dart';
export '../models/app_user.dart';
export '../models/audit_log.dart';
export '../models/bank_settings.dart';
export '../models/company.dart';
export '../models/loan.dart';
export '../models/transaction.dart';

/// TXT / CSV içe aktarma sonucu.
class ImportUsersResult {
  final int added;
  final List<String> skipped;
  final List<String> messages;
  final double totalSalary;

  const ImportUsersResult({
    required this.added,
    this.skipped = const [],
    this.messages = const [],
    this.totalSalary = 0,
  });
}

/// Toplu işlem sonucu.
class BulkResult {
  final int affected;
  final List<String> failures;

  const BulkResult({required this.affected, this.failures = const []});

  String get summary =>
      failures.isEmpty ? '$affected kayıt güncellendi.' : '$affected kayıt güncellendi, ${failures.length} kayıt atlandı.';
}

/// Şirket bazlı özet istatistikler.
class CompanyStats {
  final int employees;
  final int activeEmployees;
  final double monthlySalaries;
  final double averageSalary;
  final double balance;
  final double limitUsage;

  const CompanyStats({
    required this.employees,
    required this.activeEmployees,
    required this.monthlySalaries,
    required this.averageSalary,
    required this.balance,
    required this.limitUsage,
  });
}

/// Aylık grafik verisi.
class MonthPoint {
  final DateTime month;
  final double income;
  final double expense;
  final double salaries;

  const MonthPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.salaries,
  });

  double get net => income - expense;
}

/// Güvenli, platformlar arası tutarlı hash (DJB2 32-bit)
String hashPassword(String s) {
  int hash = 5381;
  for (final c in s.codeUnits) {
    hash = (((hash << 5) + hash) + c) & 0x7FFFFFFF;
  }
  return hash.toRadixString(16);
}

String _hash(String s) => hashPassword(s);

class BankProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Random _rnd = Random();

  List<AppUser> _users = [];
  List<Company> _companies = [];
  List<Txn> _transactions = [];
  List<Loan> _loans = [];
  List<AuditEntry> _audit = [];
  List<AppNotification> _notifications = [];

  /// Geri alma (undo) için anlık görüntüler.
  final List<Map<String, dynamic>> _history = [];
  final List<String> _historyLabels = [];

  BankSettings settings = BankSettings();

  AppUser? currentUser;
  bool initialized = false;

  Timer? _scheduler;
  DateTime? _lastAlertCheck;
  bool _disposed = false;

  // ---------------------------------------------------------------- Getter
  List<AppUser> get users => List.unmodifiable(_users);
  List<Company> get companies => List.unmodifiable(_companies);
  List<Txn> get transactions => List.unmodifiable(_transactions.reversed);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<AuditEntry> get auditLog => List.unmodifiable(_audit.reversed);
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.reversed);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  String get currency => settings.currency;
  String get bankName => settings.bankName;
  String get logoEmoji => settings.logoEmoji;
  int get decimalDigits => settings.decimalDigits;
  bool get symbolAfter => settings.symbolAfter;
  bool get animationsEnabled => settings.animationsEnabled;
  bool get gradientBackground => settings.gradientBackground;
  String get accentId => settings.accentId;
  String get densityId => settings.density;

  ThemeMode get themeMode {
    switch (settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get canUndo => _history.isNotEmpty;
  String? get lastUndoLabel =>
      _historyLabels.isEmpty ? null : _historyLabels.last;

  String money(double value, {bool signed = false, bool compact = false}) =>
      Fmt.money(
        value,
        currency,
        digits: decimalDigits,
        symbolAfter: symbolAfter,
        signed: signed,
        compact: compact,
      );

  // ------------------------------------------------------------- Başlatma
  Future<void> init() async {
    // tr_TR tarih sembolleri (DateFormat) yüklenmeden para/tarih biçimlendirme
    // yapılamaz; bu yüzden veri yüklemeden önce hazırlanır.
    try {
      await initializeDateFormatting('tr_TR', null);
    } catch (_) {}
    try {
      final data = await _storage.loadAll();

      _users = _mapList(data['users'], AppUser.fromJson);
      _companies = _mapList(data['companies'], Company.fromJson);
      _transactions = _mapList(data['transactions'], Txn.fromJson);
      _loans = _mapList(data['loans'], Loan.fromJson);
      _audit = _mapList(data['audit'], AuditEntry.fromJson);
      _notifications =
          _mapList(data['notifications'], AppNotification.fromJson);

      final s = data['settings'];
      if (s is Map && s.isNotEmpty) {
        settings = BankSettings.fromJson(Map<String, dynamic>.from(s));
      }
    } catch (_) {
      _users = [];
      _companies = [];
      _transactions = [];
      _loans = [];
      _audit = [];
      _notifications = [];
      settings = BankSettings();
    }

    if (_users.isEmpty && _companies.isEmpty) {
      _seed();
    } else {
      _ensureSuperAdmin();
    }

    if (settings.autoPayroll) {
      processDueSalaries(silent: true);
      payDueLoanInstallments(silent: true);
    }

    initialized = true;
    _safeNotify();
  }

  static List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) build) {
    if (raw is! List) return <T>[];
    final result = <T>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          result.add(build(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    _scheduler?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Arka plan zamanlayıcısı: vadesi gelen maaşlar, kredi taksitleri ve sözleşme uyarıları.
  void startScheduler({Duration interval = const Duration(minutes: 1)}) {
    _scheduler?.cancel();
    _scheduler = Timer.periodic(interval, (_) => tick());
    tick();
  }

  void stopScheduler() {
    _scheduler?.cancel();
    _scheduler = null;
  }

  /// Tek bir zamanlayıcı döngüsü (test edilebilir).
  void tick() {
    if (_disposed) return;
    var changed = false;
    if (settings.autoPayroll) {
      final paid = processDueSalaries(silent: true);
      final installments = payDueLoanInstallments(silent: true);
      if (paid > 0 || installments > 0) changed = true;
    }
    final now = DateTime.now();
    if (_lastAlertCheck == null ||
        now.difference(_lastAlertCheck!).inHours >= 6) {
      _lastAlertCheck = now;
      checkContractAlerts();
      if (settings.autoContractRenewal) renewExpiredContracts(silent: true);
    }
    if (changed) _safeNotify();
  }

  // ----------------------------------------------------------------- Tohum
  void _seed() {
    final now = DateTime.now();

    final admin = AppUser(
      id: 'admin-001',
      fullName: 'Banka Sahibi',
      email: 'admin@bank.com',
      passwordHash: _hash('admin123'),
      role: UserRole.superAdmin,
      title: 'Süper Admin',
      salaryDate: now,
      contractStart: now,
      contractEnd: now.add(const Duration(days: 36500)),
      avatarColor: 0xFF4F5BD5,
      hireDate: DateTime(now.year - 2, 1, 15),
    );
    _users.add(admin);

    // --- Demo şirketler ---
    final tech = Company(
      id: 'comp-001',
      name: 'TechCorp A.Ş.',
      balance: 1000000,
      salaryLimit: 50000,
      salaryMin: 25000,
      createdAt: now.subtract(const Duration(days: 720)),
      sector: 'Yazılım',
      taxNumber: '1234567890',
      address: 'Teknopark, İstanbul',
      contactEmail: 'info@techcorp.com',
      contactPhone: '+90 212 000 00 01',
      colorValue: 0xFF4F5BD5,
      notes: 'Ana teknoloji iştiraki.',
    );
    final nova = Company(
      id: 'comp-002',
      name: 'Nova Enerji Ltd.',
      balance: 640000,
      salaryLimit: 62000,
      salaryMin: 30000,
      createdAt: now.subtract(const Duration(days: 430)),
      sector: 'Enerji',
      taxNumber: '9876543210',
      address: 'Ataşehir, İstanbul',
      contactEmail: 'info@novaenerji.com',
      contactPhone: '+90 216 000 00 02',
      colorValue: 0xFF0E9F6E,
    );
    final atlas = Company(
      id: 'comp-003',
      name: 'Atlas Lojistik',
      balance: 380000,
      salaryLimit: 40000,
      salaryMin: 20000,
      createdAt: now.subtract(const Duration(days: 200)),
      sector: 'Lojistik',
      taxNumber: '5554443332',
      address: 'Gebze, Kocaeli',
      contactEmail: 'info@atlaslojistik.com',
      colorValue: 0xFFF97316,
    );
    _companies.addAll([tech, nova, atlas]);

    _users.add(AppUser(
      id: 'emp-001',
      fullName: 'Ahmet Yılmaz',
      email: 'ahmet@techcorp.com',
      passwordHash: _hash('123456'),
      role: UserRole.employee,
      companyId: tech.id,
      title: 'Yazılım Geliştirici',
      department: 'Yazılım',
      salary: 45000,
      bonus: 2500,
      balance: 128500,
      salaryDate: DateTime(now.year, now.month, settings.salaryDay),
      contractStart: now.subtract(const Duration(days: 210)),
      contractEnd: now.add(const Duration(days: 155)),
      terminationFee: 90000,
      phone: '+90 532 111 11 11',
      iban: 'TR00 0001 0002 0003 0004 0005 01',
      hireDate: now.subtract(const Duration(days: 210)),
      avatarColor: 0xFF4F5BD5,
    ));

    const demoEmployees = <List<dynamic>>[
      ['Elif Kaya', 'Ürün Yöneticisi', 'Ürün', 48000.0, 0, 96000.0, 'comp-001', 'emp-002', 300],
      ['Mert Demir', 'Kıdemli Geliştirici', 'Yazılım', 42000.0, 1200.0, 84000.0, 'comp-001', 'emp-003', 120],
      ['Zeynep Şahin', 'Tasarımcı', 'Tasarım', 32000.0, 0, 64000.0, 'comp-001', 'emp-004', 45],
      ['Burak Aydın', 'DevOps Mühendisi', 'Altyapı', 39000.0, 800.0, 78000.0, 'comp-001', 'emp-005', 620],
      ['Selin Arslan', 'Veri Analisti', 'Veri', 35000.0, 0, 70000.0, 'comp-001', 'emp-006', 95],
      ['Kerem Koç', 'Santral Mühendisi', 'Üretim', 52000.0, 3000.0, 104000.0, 'comp-002', 'emp-007', 480],
      ['Ayşe Yıldız', 'Enerji Uzmanı', 'Analiz', 44000.0, 0, 88000.0, 'comp-002', 'emp-008', 250],
      ['Emre Tunç', 'Saha Teknisyeni', 'Saha', 31000.0, 0, 62000.0, 'comp-002', 'emp-009', 30],
      ['Deniz Polat', 'Finans Sorumlusu', 'Finans', 41000.0, 1500.0, 82000.0, 'comp-002', 'emp-010', 380],
      ['Cem Bulut', 'Operasyon Şefi', 'Operasyon', 28000.0, 0, 56000.0, 'comp-003', 'emp-011', 150],
      ['Nazlı Erdem', 'Depo Sorumlusu', 'Depo', 24000.0, 500.0, 48000.0, 'comp-003', 'emp-012', 75],
      ['Okan Sarı', 'Şoför', 'Saha', 21000.0, 0, 42000.0, 'comp-003', 'emp-013', 400],
      ['Gizem Acar', 'Müşteri Temsilcisi', 'Satış', 26000.0, 700.0, 52000.0, 'comp-003', 'emp-014', 210],
      ['Hakan Öztürk', 'Bölge Müdürü', 'Satış', 38000.0, 2000.0, 76000.0, 'comp-003', 'emp-015', 95],
    ];

    for (final row in demoEmployees) {
      final daysAgo = row[8] as int;
      _users.add(AppUser(
        id: row[7] as String,
        fullName: row[0] as String,
        email: '${_slugify(row[0] as String)}@bank.local',
        passwordHash: _hash('123456'),
        role: UserRole.employee,
        companyId: row[6] as String,
        title: row[1] as String,
        department: row[2] as String,
        salary: row[3] as double,
        bonus: row[4] as double,
        balance: (row[3] as double) * (1 + _rnd.nextDouble() * 2.4),
        salaryDate: DateTime(now.year, now.month, settings.salaryDay),
        contractStart: now.subtract(Duration(days: daysAgo + 30)),
        contractEnd: now.add(Duration(days: 60 + _rnd.nextInt(700))),
        terminationFee: (row[3] as double) * 2,
        phone: '+90 5${_rnd.nextInt(9)}${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
        hireDate: now.subtract(Duration(days: daysAgo)),
        avatarColor: _paletteColor(_users.length),
      ));
    }

    // Şirket yöneticisi örneği
    _users.add(AppUser(
      id: 'emp-000',
      fullName: 'Yönetici Paneli',
      email: 'yonetici@techcorp.com',
      passwordHash: _hash('123456'),
      role: UserRole.companyAdmin,
      companyId: tech.id,
      title: 'Şirket Yöneticisi',
      department: 'Yönetim',
      salary: 60000,
      balance: 210000,
      salaryDate: DateTime(now.year, now.month, settings.salaryDay),
      contractStart: now.subtract(const Duration(days: 400)),
      contractEnd: now.add(const Duration(days: 330)),
      terminationFee: 120000,
      avatarColor: 0xFF8B3DFF,
      hireDate: now.subtract(const Duration(days: 400)),
    ));

    // --- Geçmiş hareketler (son 6 ay) ---
    addTxn(TxnType.credit, tech.balance, 'BANK', tech.id,
        'TechCorp A.Ş. kuruldu ve başlangıç kredisi yüklendi');
    addTxn(TxnType.credit, nova.balance, 'BANK', nova.id,
        'Nova Enerji Ltd. kuruldu ve başlangıç kredisi yüklendi');
    addTxn(TxnType.credit, atlas.balance, 'BANK', atlas.id,
        'Atlas Lojistik kuruldu ve başlangıç kredisi yüklendi');

    final employees =
        _users.where((u) => u.role == UserRole.employee).toList();
    for (int m = 5; m >= 0; m--) {
      final monthDate = DateTime(now.year, now.month - m, settings.salaryDay);
      for (final u in employees) {
        final company = companyById(u.companyId);
        if (company == null) continue;
        _transactions.add(Txn(
          id: 'txn-seed-$m-${u.id}',
          type: TxnType.salary,
          amount: u.salary,
          fromId: company.id,
          toId: u.id,
          description:
              '${DateFormat('MMMM yyyy', 'tr_TR').format(monthDate)} maaş ödemesi',
          date: monthDate,
          actorId: 'BANK',
          reference: 'MAAS-${monthDate.year}${monthDate.month.toString().padLeft(2, '0')}-${u.id}',
        ));
        if (_rnd.nextDouble() > 0.72) {
          _transactions.add(Txn(
            id: 'txn-seed-b-$m-${u.id}',
            type: TxnType.bonus,
            amount: (500 + _rnd.nextInt(3000)).toDouble(),
            fromId: company.id,
            toId: u.id,
            description: 'Aylık performans primi',
            date: monthDate.add(const Duration(days: 6)),
            actorId: 'BANK',
            reference: 'PRIM-${monthDate.month}-${u.id}',
          ));
        }
        if (_rnd.nextDouble() > 0.9) {
          _transactions.add(Txn(
            id: 'txn-seed-p-$m-${u.id}',
            type: TxnType.penalty,
            amount: (200 + _rnd.nextInt(900)).toDouble(),
            fromId: u.id,
            toId: company.id,
            description: 'Geç kalma cezası',
            date: monthDate.add(const Duration(days: 12)),
            actorId: 'BANK',
            reference: 'CEZA-${monthDate.month}-${u.id}',
          ));
        }
      }
    }

    // Demo kredi kayıtları
    final loanUserA = _users.firstWhere((u) => u.id == 'emp-003',
        orElse: () => _users.first);
    final loanA = _buildLoan(
      userId: loanUserA.id,
      amount: 60000,
      installments: 12,
      note: 'Konut tadilat avansı',
      startDate: now.subtract(const Duration(days: 95)),
    );
    loanA.paidInstallments = 3;
    _loans.add(loanA);

    final loanUserB = _users.firstWhere((u) => u.id == 'emp-007',
        orElse: () => _users.first);
    final loanB = _buildLoan(
      userId: loanUserB.id,
      amount: 30000,
      installments: 6,
      note: 'Eğitim desteği',
      startDate: now.subtract(const Duration(days: 40)),
    );
    loanB.paidInstallments = 1;
    _loans.add(loanB);

    _audit.add(AuditEntry(
      id: 'log-seed',
      actorId: 'BANK',
      actorName: 'Sistem',
      action: 'Demo verisi oluşturuldu',
      detail:
          '${_companies.length} şirket, ${_users.length} kullanıcı ve ${_transactions.length} hareket yüklendi.',
      level: LogLevel.info,
      date: now,
    ));

    _notify(
      '${_companies.length} şirket ve ${employees.length} çalışan hazır',
      'Demo verisiyle başladınız. Ayarlar sekmesinden kendi bankanızı kurabilirsiniz.',
      NotifyKind.info,
      persist: false,
    );

    _persist();
  }

  int _paletteColor(int index) {
    const palette = [
      0xFF4F5BD5,
      0xFF0E9F6E,
      0xFFF97316,
      0xFF8B3DFF,
      0xFFE11D48,
      0xFF06B6D4,
      0xFFC79217,
    ];
    return palette[index % palette.length];
  }

  void _ensureSuperAdmin() {
    if (_users.any((u) => u.role == UserRole.superAdmin)) return;
    final now = DateTime.now();
    _users.add(AppUser(
      id: 'admin-001',
      fullName: 'Banka Sahibi',
      email: 'admin@bank.com',
      passwordHash: _hash('admin123'),
      role: UserRole.superAdmin,
      title: 'Süper Admin',
      salaryDate: now,
      contractStart: now,
      contractEnd: now.add(const Duration(days: 36500)),
    ));
    _persist();
  }

  Future<void> _persist() async {
    await _storage.saveAll(
      users: _users.map((e) => e.toJson()).toList(),
      companies: _companies.map((e) => e.toJson()).toList(),
      transactions: _transactions.map((e) => e.toJson()).toList(),
      settings: settings.toJson(),
      loans: _loans.map((e) => e.toJson()).toList(),
      audit: _audit.map((e) => e.toJson()).toList(),
      notifications: _notifications.map((e) => e.toJson()).toList(),
      meta: {'lastSaved': DateTime.now().toIso8601String()},
    );
  }

  // ------------------------------------------------------- Kayıt & Günlük
  void addTxn(TxnType type, double amount, String from, String to, String desc,
      {DateTime? date}) {
    final now = date ?? DateTime.now();
    _transactions.add(Txn(
      id: 'txn-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(9999)}',
      type: type,
      amount: amount.abs(),
      fromId: from,
      toId: to,
      description: desc,
      date: now,
      actorId: currentUser?.id ?? 'BANK',
      reference:
          '${type.name.toUpperCase()}-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
    ));
  }

  void log(String action, {String detail = '', LogLevel level = LogLevel.info}) {
    _audit.add(AuditEntry(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(999)}',
      actorId: currentUser?.id ?? 'BANK',
      actorName: currentUser?.fullName ?? 'Sistem',
      action: action,
      detail: detail,
      level: level,
      date: DateTime.now(),
    ));
    final limit = settings.auditLimit;
    if (_audit.length > limit) {
      _audit.removeRange(0, _audit.length - limit);
    }
  }

  void clearAudit() {
    _audit.clear();
    log('Sistem günlüğü temizlendi', level: LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void _notify(
    String title,
    String body,
    NotifyKind kind, {
    String? userId,
    bool persist = true,
  }) {
    if (!settings.notificationsEnabled) return;
    _notifications.add(AppNotification(
      id: 'ntf-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(999)}',
      title: title,
      body: body,
      kind: kind,
      date: DateTime.now(),
      userId: userId,
    ));
    if (_notifications.length > 200) {
      _notifications.removeRange(0, _notifications.length - 200);
    }
    if (persist) _persist();
  }

  void markNotificationRead(String id) {
    for (final n in _notifications) {
      if (n.id == id) n.isRead = true;
    }
    _persist();
    _safeNotify();
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _persist();
    _safeNotify();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persist();
    _safeNotify();
  }

  void clearNotifications() {
    _notifications.clear();
    _persist();
    _safeNotify();
  }

  // ------------------------------------------------------------ Geri alma
  void pushSnapshot(String label) {
    _history.add({
      'users': _users.map((e) => e.toJson()).toList(),
      'companies': _companies.map((e) => e.toJson()).toList(),
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'loans': _loans.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
    });
    _historyLabels.add(label);
    if (_history.length > 15) {
      _history.removeAt(0);
      _historyLabels.removeAt(0);
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final data = _history.removeLast();
    final label = _historyLabels.removeLast();
    _users = _mapList(data['users'], AppUser.fromJson);
    _companies = _mapList(data['companies'], Company.fromJson);
    _transactions = _mapList(data['transactions'], Txn.fromJson);
    _loans = _mapList(data['loans'], Loan.fromJson);
    final s = data['settings'];
    if (s is Map) settings = BankSettings.fromJson(Map<String, dynamic>.from(s));
    if (currentUser != null) {
      currentUser = userById(currentUser!.id);
    }
    log('İşlem geri alındı', detail: label, level: LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void clearHistory() {
    _history.clear();
    _historyLabels.clear();
    _safeNotify();
  }

  // ------------------------------------------------------------------ Auth
  /// Başarılıysa `null`, aksi halde kullanıcıya gösterilecek hata metni.
  /// Yalnızca yönetici (süper admin) girişi için kullanılır.
  String? login(String email, String password) {
    final err = _authenticate(email, password, requireSuperAdmin: true);
    return err;
  }

  /// Her rol için giriş (çalışan portalı dahil).
  String? loginUser(String email, String password) {
    return _authenticate(email, password, requireSuperAdmin: false);
  }

  String? _authenticate(
    String email,
    String password, {
    required bool requireSuperAdmin,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final hash = _hash(password);
    AppUser? found;
    for (final u in _users) {
      if (u.email.toLowerCase() == cleanEmail && u.passwordHash == hash) {
        found = u;
        break;
      }
    }
    if (found == null) return 'E-posta veya şifre hatalı.';
    if (!found.isActive) return 'Hesap aktif değil. Yöneticinizle iletişime geçin.';
    if (requireSuperAdmin && found.role != UserRole.superAdmin) {
      return 'Bu panele yalnızca yönetici giriş yapabilir.';
    }
    found.lastLogin = DateTime.now();
    currentUser = found;
    log('Oturum açıldı',
        detail: '${found.fullName} (${found.roleLabel})', level: LogLevel.success);
    _persist();
    _safeNotify();
    return null;
  }

  void logout() {
    if (currentUser != null) {
      log('Oturum kapatıldı',
          detail: currentUser!.fullName, level: LogLevel.info);
    }
    currentUser = null;
    _persist();
    _safeNotify();
  }

  // -------------------------------------------------------------- Şirketler
  void addCompany(
    String name,
    double balance, {
    double salaryLimit = 50000,
    double salaryMin = 0,
    String sector = '',
    String taxNumber = '',
    String address = '',
    String contactEmail = '',
    String contactPhone = '',
    int colorValue = 0,
    String notes = '',
    bool persist = true,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Şirket adı boş bırakılamaz.');
    if (balance < 0) throw Exception('Başlangıç bakiyesi negatif olamaz.');
    if (salaryLimit <= 0) {
      throw Exception('Çalışan maaş sınırı sıfırdan büyük olmalıdır.');
    }
    if (salaryMin > salaryLimit) {
      throw Exception('Alt maaş sınırı üst sınırı aşamaz.');
    }

    pushSnapshot('Şirket eklendi: $cleanName');
    final c = Company(
      id: 'comp-${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      balance: balance,
      salaryLimit: salaryLimit,
      salaryMin: salaryMin,
      createdAt: DateTime.now(),
      sector: sector.trim(),
      taxNumber: taxNumber.trim(),
      address: address.trim(),
      contactEmail: contactEmail.trim(),
      contactPhone: contactPhone.trim(),
      colorValue: colorValue == 0 ? _paletteColor(_companies.length) : colorValue,
      notes: notes.trim(),
      isActive: isActive,
    );
    _companies.add(c);
    if (balance > 0) {
      addTxn(TxnType.credit, balance, 'BANK', c.id,
          'Şirket oluşturuldu - başlangıç kredisi');
    }
    log('Şirket eklendi',
        detail: '$cleanName • başlangıç: ${money(balance)}',
        level: LogLevel.success);
    _notify('Yeni şirket: $cleanName', 'Başlangıç bakiyesi ${money(balance)}',
        NotifyKind.info);
    if (persist) {
      _persist();
      _safeNotify();
    }
  }

  void depositToCompany(String companyId, double amount, String reason) {
    if (amount <= 0) throw Exception('Yüklenecek tutar sıfırdan büyük olmalıdır.');
    final c = _company(companyId);
    pushSnapshot('${c.name} kredi yükleme');
    c.balance += amount;
    final cleanReason =
        reason.trim().isEmpty ? 'Banka tarafından kredi yüklendi' : reason.trim();
    addTxn(TxnType.credit, amount, 'BANK', c.id, cleanReason);
    log('Kredi yükleme',
        detail: '${c.name} • ${money(amount)} • $cleanReason',
        level: LogLevel.success);
    _persist();
    _safeNotify();
  }

  void withdrawFromCompany(String companyId, double amount, String reason) {
    if (amount <= 0) throw Exception('Düşülecek tutar sıfırdan büyük olmalıdır.');
    final c = _company(companyId);
    if (c.balance < amount) {
      throw Exception(
          'Şirket bakiyesi yetersiz. Mevcut: ${money(c.balance)}, gerekli: ${money(amount)}.');
    }
    pushSnapshot('${c.name} bakiye düşümü');
    c.balance -= amount;
    final cleanReason =
        reason.trim().isEmpty ? 'Banka tarafından bakiye düşüldü' : reason.trim();
    addTxn(TxnType.transfer, amount, c.id, 'BANK', cleanReason);
    log('Bakiye düşümü', detail: '${c.name} • ${money(amount)} • $cleanReason');
    _persist();
    _safeNotify();
  }

  void updateCompanyBalance(String companyId, double newBalance, String reason) {
    if (newBalance < 0) throw Exception('Şirket bakiyesi negatif olamaz.');
    final c = _company(companyId);
    final diff = newBalance - c.balance;
    pushSnapshot('${c.name} bakiye güncelleme');
    c.balance = newBalance;
    final cleanReason = reason.trim().isEmpty ? 'Bakiye güncellendi' : reason.trim();
    if (diff > 0) {
      addTxn(TxnType.credit, diff, 'BANK', c.id, cleanReason);
    } else if (diff < 0) {
      addTxn(TxnType.transfer, diff.abs(), c.id, 'BANK', cleanReason);
    }
    log('Bakiye güncellendi',
        detail: '${c.name} • yeni bakiye ${money(newBalance)}');
    _persist();
    _safeNotify();
  }

  void updateCompany({
    required String id,
    String? name,
    double? salaryLimit,
    double? salaryMin,
    String? sector,
    String? taxNumber,
    String? address,
    String? contactEmail,
    String? contactPhone,
    int? colorValue,
    bool? isActive,
    String? notes,
  }) {
    final c = _company(id);
    if (name != null) {
      final cleanName = name.trim();
      if (cleanName.isEmpty) throw Exception('Şirket adı boş bırakılamaz.');
      c.name = cleanName;
    }
    if (salaryLimit != null) {
      if (salaryLimit <= 0) {
        throw Exception('Çalışan maaş sınırı sıfırdan büyük olmalıdır.');
      }
      c.salaryLimit = salaryLimit;
    }
    if (salaryMin != null) {
      if (salaryMin < 0) throw Exception('Alt maaş sınırı negatif olamaz.');
      if (salaryMin > c.salaryLimit) {
        throw Exception('Alt maaş sınırı üst sınırı aşamaz.');
      }
      c.salaryMin = salaryMin;
    }
    if (sector != null) c.sector = sector.trim();
    if (taxNumber != null) c.taxNumber = taxNumber.trim();
    if (address != null) c.address = address.trim();
    if (contactEmail != null) c.contactEmail = contactEmail.trim();
    if (contactPhone != null) c.contactPhone = contactPhone.trim();
    if (colorValue != null && colorValue != 0) c.colorValue = colorValue;
    if (isActive != null) c.isActive = isActive;
    if (notes != null) c.notes = notes.trim();

    // Limit düşerse mevcut maaşları bilgilendir (otomatik kesmeyiz, sadece uyarı).
    final overLimit = _users
        .where((u) => u.companyId == id && u.salary > c.salaryLimit)
        .map((u) => u.fullName)
        .toList();
    log('Şirket güncellendi', detail: c.name);
    if (overLimit.isNotEmpty) {
      _notify(
        '${c.name}: maaş sınırı aşıldı',
        '${overLimit.length} çalışanın maaşı yeni sınırın üzerinde: ${overLimit.take(3).join(', ')}',
        NotifyKind.risk,
      );
    }
    _persist();
    _safeNotify();
  }

  void setCompanyActive(String id, bool active) {
    final c = _company(id);
    c.isActive = active;
    log(active ? 'Şirket aktif edildi' : 'Şirket pasife alındı',
        detail: c.name, level: active ? LogLevel.success : LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void deleteCompany(String id, {bool purgeUsers = false}) {
    final c = _company(id);
    pushSnapshot('Şirket silindi: ${c.name}');
    if (purgeUsers) {
      _users.removeWhere((u) => u.companyId == id);
    } else {
      for (final u in _users.where((u) => u.companyId == id)) {
        u.companyId = null;
      }
    }
    _loanCleanupForMissingUsers();
    _companies.removeWhere((x) => x.id == id);
    log('Şirket silindi',
        detail: '${c.name}${purgeUsers ? ' • çalışanlar da silindi' : ' • çalışanlar şirketsiz kaldı'}',
        level: LogLevel.danger);
    _persist();
    _safeNotify();
  }

  Company _company(String id) {
    for (final c in _companies) {
      if (c.id == id) return c;
    }
    throw Exception('Şirket bulunamadı.');
  }

  // -------------------------------------------------------------- Kullanıcı
  String _slugify(String input) {
    const map = {
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'İ': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
    };
    final buf = StringBuffer();
    for (final r in input.runes) {
      final ch = String.fromCharCode(r);
      buf.write(map[ch] ?? ch);
    }
    final slug = buf
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s.]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '.');
    return slug.isEmpty ? 'kullanici' : slug;
  }

  String generateEmail(String fullName) {
    final slug = _slugify(fullName);
    var email = '$slug@bank.local';
    var i = 1;
    while (_users.any((u) => u.email.toLowerCase() == email)) {
      email = '$slug$i@bank.local';
      i++;
    }
    return email;
  }

  String generateIban(String userId) {
    final digits = userId.hashCode.abs().toString().padLeft(10, '0');
    final rand = (_rnd.nextInt(99999999)).toString().padLeft(8, '0');
    return 'TR${(10 + _rnd.nextInt(89))} 0006 2000 $digits 0006 $rand';
  }

  /// Şirket maaş sınırlarına göre (alt–üst aralıkta) rastgele maaş üretir.
  double distributeSalary(double salaryLimit, {double salaryMin = 0}) {
    if (salaryLimit <= 0) return 0;
    final ratio = settings.salaryMinRatio.clamp(0.05, 1.0);
    final minS = salaryMin > 0 ? salaryMin : salaryLimit * ratio;
    final lower = minS.clamp(0.0, salaryLimit);
    final raw = lower >= salaryLimit
        ? salaryLimit
        : lower + _rnd.nextDouble() * (salaryLimit - lower);
    final rounded = (raw / 100).round() * 100.0;
    return rounded.clamp(1, salaryLimit).toDouble();
  }

  void addUser({
    required String fullName,
    String? email,
    String? password,
    required UserRole role,
    String? companyId,
    String title = 'Çalışan',
    double salary = 0,
    DateTime? salaryDate,
    DateTime? contractEnd,
    DateTime? contractStart,
    double terminationFee = 0,
    String phone = '',
    String iban = '',
    String department = '',
    String notes = '',
    int avatarColor = 0,
    bool isActive = true,
    double balance = 0,
    double bonus = 0,
    bool persist = true,
  }) {
    final cleanName = fullName.trim();
    if (cleanName.isEmpty) throw Exception('Ad Soyad boş bırakılamaz.');

    final cleanEmail = (email == null || email.trim().isEmpty)
        ? generateEmail(cleanName)
        : email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || cleanEmail.endsWith('@')) {
      throw Exception('Geçerli bir e-posta adresi girin.');
    }
    if (_users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('Bu e-posta adresi zaten kullanılıyor.');
    }

    final rawPassword =
        (password == null || password.isEmpty) ? '123456' : password;
    if (rawPassword.length < 4) {
      throw Exception('Şifre en az 4 karakter olmalıdır.');
    }
    if (salary < 0) throw Exception('Maaş negatif olamaz.');
    if (terminationFee < 0) throw Exception('Fesih ücreti negatif olamaz.');

    if (companyId != null) {
      final company = companyById(companyId);
      if (company == null) throw Exception('Seçilen şirket bulunamadı.');
      if (company.salaryLimit > 0 && salary > company.salaryLimit) {
        throw Exception(
            'Maaş, ${company.name} şirketinin maaş sınırını (${money(salary)} > ${money(company.salaryLimit)}) aşıyor.');
      }
    }

    final now = DateTime.now();
    final start = contractStart ?? now;
    final sDate = salaryDate ??
        DateTime(now.year, now.month, settings.salaryDay.clamp(1, 28));

    final u = AppUser(
      id: 'usr-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(9999)}',
      fullName: cleanName,
      email: cleanEmail,
      passwordHash: _hash(rawPassword),
      role: role,
      companyId: companyId,
      title: title.trim().isEmpty ? 'Çalışan' : title.trim(),
      salary: salary,
      bonus: bonus,
      balance: balance,
      salaryDate: sDate,
      contractStart: start,
      contractEnd: contractEnd ??
          start.add(Duration(days: settings.defaultContractMonths * 30)),
      terminationFee: terminationFee,
      isActive: isActive,
      phone: phone.trim(),
      iban: iban.trim().isEmpty ? generateIban(cleanEmail) : iban.trim(),
      department: department.trim(),
      notes: notes.trim(),
      avatarColor: avatarColor == 0 ? _paletteColor(_users.length) : avatarColor,
      hireDate: start,
    );
    _users.add(u);
    addTxn(TxnType.system, 0, 'BANK', u.id,
        'Kullanıcı hesabı oluşturuldu: $cleanName (${role.label})');
    log('Kullanıcı eklendi',
        detail: '$cleanName • $cleanEmail • ${role.label}',
        level: LogLevel.success);
    if (persist) {
      _persist();
      _safeNotify();
    }
  }

  void updateUserFields(
    String userId, {
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    Object? companyId = _unset,
    String? title,
    double? salary,
    double? bonus,
    double? balance,
    DateTime? salaryDate,
    DateTime? contractStart,
    DateTime? contractEnd,
    double? terminationFee,
    bool? isActive,
    String? phone,
    String? iban,
    String? department,
    String? notes,
    int? avatarColor,
  }) {
    final u = _user(userId);
    if (fullName != null) {
      final clean = fullName.trim();
      if (clean.isEmpty) throw Exception('Ad Soyad boş bırakılamaz.');
      u.fullName = clean;
    }
    if (email != null) {
      final clean = email.trim().toLowerCase();
      if (!clean.contains('@')) throw Exception('Geçerli bir e-posta adresi girin.');
      if (_users.any((x) => x.id != userId && x.email.toLowerCase() == clean)) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor.');
      }
      u.email = clean;
    }
    if (password != null && password.isNotEmpty) {
      if (password.length < 4) throw Exception('Şifre en az 4 karakter olmalıdır.');
      u.passwordHash = _hash(password);
    }
    if (role != null) u.role = role;
    if (!identical(companyId, _unset)) {
      final newCompany = companyId?.toString();
      if (newCompany == null || newCompany.isEmpty) {
        u.companyId = null;
      } else {
        if (companyById(newCompany) == null) {
          throw Exception('Seçilen şirket bulunamadı.');
        }
        u.companyId = newCompany;
      }
    }
    if (title != null) {
      u.title = title.trim().isEmpty ? 'Çalışan' : title.trim();
    }
    if (salary != null) {
      if (salary < 0) throw Exception('Maaş negatif olamaz.');
      final company = companyById(u.companyId);
      if (company != null &&
          company.salaryLimit > 0 &&
          salary > company.salaryLimit) {
        throw Exception(
            'Maaş, ${company.name} şirketinin maaş sınırını (${money(company.salaryLimit)}) aşıyor.');
      }
      u.salary = salary;
    }
    if (bonus != null) {
      if (bonus < 0) throw Exception('Aylık prim negatif olamaz.');
      u.bonus = bonus;
    }
    if (balance != null) {
      if (balance < 0) throw Exception('Bakiye negatif olamaz.');
      u.balance = balance;
    }
    if (salaryDate != null) u.salaryDate = salaryDate;
    if (contractStart != null) u.contractStart = contractStart;
    if (contractEnd != null) u.contractEnd = contractEnd;
    if (terminationFee != null) {
      if (terminationFee < 0) throw Exception('Fesih ücreti negatif olamaz.');
      u.terminationFee = terminationFee;
    }
    if (isActive != null) u.isActive = isActive;
    if (phone != null) u.phone = phone.trim();
    if (iban != null) u.iban = iban.trim();
    if (department != null) u.department = department.trim();
    if (notes != null) u.notes = notes.trim();
    if (avatarColor != null && avatarColor != 0) u.avatarColor = avatarColor;

    if (currentUser?.id == userId) currentUser = u;
    log('Kullanıcı güncellendi', detail: u.fullName);
    _persist();
    _safeNotify();
  }

  static const Object _unset = Object();

  void updateUser(AppUser updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _users[idx] = updated;
      if (currentUser?.id == updated.id) currentUser = updated;
      _persist();
      _safeNotify();
    }
  }

  void updateUserName(String userId, String newName) {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) throw Exception('Ad Soyad boş bırakılamaz.');
    final u = _user(userId);
    final oldName = u.fullName;
    u.fullName = cleanName;
    if (currentUser?.id == userId) currentUser = u;
    log('Kullanıcı adı güncellendi', detail: '$oldName → $cleanName');
    _persist();
    _safeNotify();
  }

  void changePassword(String userId, String newPassword) {
    if (newPassword.length < 4) {
      throw Exception('Şifre en az 4 karakter olmalıdır.');
    }
    final u = _user(userId);
    u.passwordHash = _hash(newPassword);
    log('Şifre değiştirildi',
        detail: u.fullName, level: LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void setUserActive(String userId, bool active) {
    final u = _user(userId);
    u.isActive = active;
    log(active ? 'Hesap aktif edildi' : 'Hesap pasife alındı',
        detail: u.fullName, level: active ? LogLevel.success : LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void deleteUser(String id) {
    final u = _user(id);
    if (u.role == UserRole.superAdmin &&
        _users.where((x) => x.role == UserRole.superAdmin).length <= 1) {
      throw Exception('Sistemdeki son süper admin silinemez.');
    }
    pushSnapshot('Kullanıcı silindi: ${u.fullName}');
    _users.removeWhere((x) => x.id == id);
    _loans.removeWhere((l) => l.userId == id);
    if (currentUser?.id == id) currentUser = null;
    log('Kullanıcı silindi', detail: u.fullName, level: LogLevel.danger);
    _persist();
    _safeNotify();
  }

  void _loanCleanupForMissingUsers() {
    final ids = _users.map((u) => u.id).toSet();
    _loans.removeWhere((l) => !ids.contains(l.userId));
  }

  AppUser _user(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    throw Exception('Kullanıcı bulunamadı.');
  }

  // ---------------------------------------------------------------- Toplu işler
  BulkResult bulkSetActive(List<String> ids, bool active) {
    final failures = <String>[];
    pushSnapshot(active ? 'Toplu aktifleştirme' : 'Toplu pasifleştirme');
    for (final id in ids) {
      try {
        final u = _user(id);
        if (!active &&
            u.role == UserRole.superAdmin &&
            _users.where((x) => x.role == UserRole.superAdmin).length <= 1) {
          failures.add(u.fullName);
          continue;
        }
        u.isActive = active;
      } catch (_) {
        failures.add(id);
      }
    }
    log(active ? 'Toplu aktifleştirme' : 'Toplu pasifleştirme',
        detail: '${ids.length - failures.length} kayıt',
        level: active ? LogLevel.success : LogLevel.warning);
    _persist();
    _safeNotify();
    return BulkResult(affected: ids.length - failures.length, failures: failures);
  }

  BulkResult bulkDelete(List<String> ids) {
    final failures = <String>[];
    pushSnapshot('Toplu kullanıcı silme');
    final superAdmins = _users.where((x) => x.role == UserRole.superAdmin).length;
    var removedSuper = 0;
    for (final id in ids) {
      final u = userById(id);
      if (u == null) {
        failures.add(id);
        continue;
      }
      if (u.role == UserRole.superAdmin && superAdmins - removedSuper <= 1) {
        failures.add(u.fullName);
        continue;
      }
      if (u.role == UserRole.superAdmin) removedSuper++;
      _users.removeWhere((x) => x.id == id);
      _loans.removeWhere((l) => l.userId == id);
      if (currentUser?.id == id) currentUser = null;
    }
    if (currentUser == null) {
      AppUser? fallback;
      for (final u in _users) {
        if (u.role == UserRole.superAdmin) {
          fallback = u;
          break;
        }
      }
      currentUser = fallback ?? (_users.isNotEmpty ? _users.first : null);
    }
    log('Toplu kullanıcı silme',
        detail: '${ids.length - failures.length} kayıt silindi, ${failures.length} atlandı',
        level: LogLevel.danger);
    _persist();
    _safeNotify();
    return BulkResult(affected: ids.length - failures.length, failures: failures);
  }

  BulkResult bulkMoveToCompany(List<String> ids, String companyId) {
    final company = _company(companyId);
    final failures = <String>[];
    pushSnapshot('Toplu şirket transferi');
    for (final id in ids) {
      try {
        final u = _user(id);
        if (u.salary > company.salaryLimit) {
          failures.add('${u.fullName} (maaş sınırı)');
          continue;
        }
        u.companyId = companyId;
      } catch (_) {
        failures.add(id);
      }
    }
    log('Toplu şirket transferi',
        detail: '${company.name} • ${ids.length - failures.length} kayıt');
    _persist();
    _safeNotify();
    return BulkResult(affected: ids.length - failures.length, failures: failures);
  }

  BulkResult bulkBonus(List<String> ids, double amount, String note) {
    if (amount <= 0) throw Exception('Prim tutarı sıfırdan büyük olmalıdır.');
    pushSnapshot('Toplu prim dağıtımı');
    final failures = <String>[];
    final desc = note.trim().isEmpty ? 'Toplu prim dağıtımı' : note.trim();
    for (final id in ids) {
      try {
        final u = _user(id);
        final company = companyById(u.companyId);
        if (company != null) {
          if (company.balance < amount) {
            failures.add('${u.fullName} (şirket bakiyesi)');
            continue;
          }
          company.balance -= amount;
          u.balance += amount;
          addTxn(TxnType.bonus, amount, company.id, u.id, desc);
        } else {
          u.balance += amount;
          addTxn(TxnType.bonus, amount, 'BANK', u.id, desc);
        }
      } catch (_) {
        failures.add(id);
      }
    }
    log('Toplu prim', detail: '${ids.length - failures.length} çalışan • ${money(amount)}');
    _persist();
    _safeNotify();
    return BulkResult(affected: ids.length - failures.length, failures: failures);
  }

  BulkResult bulkPenalty(
    List<String> ids,
    double amount,
    String reason, {
    bool percentage = false,
  }) {
    if (amount <= 0) throw Exception('Ceza tutarı sıfırdan büyük olmalıdır.');
    if (percentage && amount > settings.penaltyMaxPercent) {
      throw Exception(
          'Yüzdesel ceza, ayarlardaki üst sınırı (%${settings.penaltyMaxPercent.toStringAsFixed(0)}) aşamaz.');
    }
    pushSnapshot('Toplu ceza uygulaması');
    final failures = <String>[];
    final cleanReason = reason.trim().isEmpty ? 'Toplu disiplin cezası' : reason.trim();
    var affected = 0;
    for (final id in ids) {
      try {
        final u = _user(id);
        final penalty = percentage ? u.salary * (amount / 100) : amount;
        if (penalty <= 0 || u.balance < penalty) {
          failures.add(u.fullName);
          continue;
        }
        u.balance -= penalty;
        final company = companyById(u.companyId);
        if (company != null) {
          company.balance += penalty;
          addTxn(TxnType.penalty, penalty, u.id, company.id, 'Ceza: $cleanReason');
        } else {
          addTxn(TxnType.penalty, penalty, u.id, 'BANK', 'Ceza: $cleanReason');
        }
        affected++;
      } catch (_) {
        failures.add(id);
      }
    }
    log('Toplu ceza',
        detail: '$affected çalışan • ${percentage ? '%${amount.toStringAsFixed(0)}' : money(amount)}',
        level: LogLevel.warning);
    _persist();
    _safeNotify();
    return BulkResult(affected: affected, failures: failures);
  }

  BulkResult bulkPromote(
    List<String> ids,
    String newTitle,
    double salaryIncreasePercent,
    double bonus,
  ) {
    if (salaryIncreasePercent < 0) {
      throw Exception('Maaş artış oranı negatif olamaz.');
    }
    pushSnapshot('Toplu terfi');
    final failures = <String>[];
    final cleanTitle = newTitle.trim();
    var affected = 0;
    for (final id in ids) {
      try {
        final u = _user(id);
        final newSalary = u.salary * (1 + salaryIncreasePercent / 100);
        final company = companyById(u.companyId);
        if (company != null && newSalary > company.salaryLimit) {
          failures.add('${u.fullName} (maaş sınırı)');
          continue;
        }
        if (bonus > 0) {
          if (company != null) {
            if (company.balance < bonus) {
              failures.add('${u.fullName} (şirket bakiyesi)');
              continue;
            }
            company.balance -= bonus;
          }
          u.balance += bonus;
          addTxn(TxnType.promotion, bonus, u.companyId ?? 'BANK', u.id,
              'Toplu terfi primi');
        }
        final oldTitle = u.title;
        u.title = cleanTitle.isEmpty ? oldTitle : cleanTitle;
        u.salary = newSalary;
        addTxn(
          TxnType.promotion,
          0,
          u.companyId ?? 'BANK',
          u.id,
          'Toplu terfi: $oldTitle → ${u.title} (${money(u.salary)})',
        );
        affected++;
      } catch (_) {
        failures.add(id);
      }
    }
    log('Toplu terfi', detail: '$affected çalışan • +%${salaryIncreasePercent.toStringAsFixed(0)}');
    _persist();
    _safeNotify();
    return BulkResult(affected: affected, failures: failures);
  }

  BulkResult bulkSetMonthlyBonus(List<String> ids, double amount) {
    if (amount < 0) throw Exception('Aylık prim negatif olamaz.');
    pushSnapshot('Toplu aylık prim tanımı');
    final failures = <String>[];
    for (final id in ids) {
      try {
        _user(id).bonus = amount;
      } catch (_) {
        failures.add(id);
      }
    }
    log('Toplu aylık prim tanımı', detail: '${money(amount)} • ${ids.length} kayıt');
    _persist();
    _safeNotify();
    return BulkResult(affected: ids.length - failures.length, failures: failures);
  }

  /// Şirket çalışanlarının maaşlarını limit aralığında yeniden dağıtır.
  BulkResult redistributeSalaries(String companyId) {
    final company = _company(companyId);
    pushSnapshot('${company.name} maaş yeniden dağıtımı');
    final employees = _users
        .where((u) => u.companyId == companyId && u.role != UserRole.superAdmin)
        .toList();
    for (final u in employees) {
      u.salary = distributeSalary(company.salaryLimit, salaryMin: company.effectiveSalaryMin);
    }
    addTxn(TxnType.system, 0, 'BANK', company.id,
        '${employees.length} çalışanın maaşı yeniden dağıtıldı (${money(company.effectiveSalaryMin)} - ${money(company.salaryLimit)})');
    log('Maaş yeniden dağıtımı',
        detail: '${company.name} • ${employees.length} çalışan');
    _persist();
    _safeNotify();
    return BulkResult(affected: employees.length);
  }

  // -------------------------------------------------------- TXT / CSV içeri
  /// TXT içindeki isimleri şirket maaş sınırına göre kullanıcı olarak ekler.
  ImportUsersResult importUsersFromNames({
    required List<String> names,
    required String companyId,
  }) {
    final company = _company(companyId);
    if (company.salaryLimit <= 0) {
      throw Exception('${company.name} için çalışan maaş sınırı belirlenmemiş.');
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final raw in names) {
      final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) continue;
      if (name.length > 80) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) unique.add(name);
    }
    if (unique.isEmpty) {
      throw Exception('Eklenecek geçerli bir isim bulunamadı.');
    }

    pushSnapshot('TXT içe aktarma (${unique.length} isim)');
    int added = 0;
    double totalSalary = 0;
    final skipped = <String>[];
    final now = DateTime.now();

    for (final name in unique) {
      final salary = distributeSalary(company.salaryLimit,
          salaryMin: company.effectiveSalaryMin);
      final months = settings.defaultContractMonths;
      final multiplier = settings.defaultTerminationMultiplier;
      try {
        addUser(
          fullName: name,
          role: UserRole.employee,
          companyId: companyId,
          salary: salary,
          contractEnd: now.add(Duration(days: months * 30)),
          terminationFee: salary * multiplier,
          persist: false,
        );
        added++;
        totalSalary += salary;
      } catch (_) {
        skipped.add(name);
      }
    }

    if (added > 0) {
      addTxn(
        TxnType.system,
        0,
        'BANK',
        company.id,
        'TXT ile $added kullanıcı eklendi (${company.name})',
      );
      log('TXT içe aktarma',
          detail: '${company.name} • $added kullanıcı eklendi',
          level: LogLevel.success);
      _persist();
      _safeNotify();
    }
    return ImportUsersResult(
      added: added,
      skipped: skipped,
      totalSalary: totalSalary,
    );
  }

  /// CSV metnini kullanıcılara dönüştürür. Başlık satırı otomatik algılanır.
  ImportUsersResult importUsersFromCsv(String csv, {String? fallbackCompanyId}) {
    final rows = ExportService.csvDecode(csv);
    if (rows.isEmpty) throw Exception('Dosya boş görünüyor.');

    var startIndex = 0;
    var map = <String, int>{};
    final header = rows.first.map((c) => c.toLowerCase()).toList();
    final headerSignals = ['ad', 'isim', 'e-posta', 'email', 'maas', 'maaş', 'şirket', 'sirket'];
    final hasHeader = header.any((h) => headerSignals.any((s) => h.contains(s)));

    if (hasHeader) {
      startIndex = 1;
      for (var i = 0; i < header.length; i++) {
        final h = header[i];
        if (h.contains('ad') || h.contains('isim') || h.contains('name')) {
          map.putIfAbsent('name', () => i);
        } else if (h.contains('e-posta') || h.contains('email') || h.contains('eposta')) {
          map.putIfAbsent('email', () => i);
        } else if (h.contains('unvan') || h.contains('görev') || h.contains('pozisyon') || h.contains('title')) {
          map.putIfAbsent('title', () => i);
        } else if (h.contains('maaş') || h.contains('maas') || h.contains('ücret') || h.contains('salary')) {
          map.putIfAbsent('salary', () => i);
        } else if (h.contains('şirket') || h.contains('sirket') || h.contains('firma') || h.contains('company')) {
          map.putIfAbsent('company', () => i);
        } else if (h.contains('departman') || h.contains('birim')) {
          map.putIfAbsent('department', () => i);
        } else if (h.contains('telefon') || h.contains('tel')) {
          map.putIfAbsent('phone', () => i);
        } else if (h.contains('şifre') || h.contains('sifre') || h.contains('password')) {
          map.putIfAbsent('password', () => i);
        } else if (h.contains('sözleşme') || h.contains('sozlesme') || h.contains('ay')) {
          map.putIfAbsent('months', () => i);
        } else if (h.contains('bakiye') || h.contains('balance')) {
          map.putIfAbsent('balance', () => i);
        }
      }
      map.putIfAbsent('name', () => 0);
    } else {
      map = {
        'name': 0,
        'email': 1,
        'title': 2,
        'salary': 3,
        'company': 4,
      };
    }

    pushSnapshot('CSV içe aktarma');
    var added = 0;
    double totalSalary = 0;
    final skipped = <String>[];
    final now = DateTime.now();

    String cell(List<String> row, String key) {
      final idx = map[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].trim();
    }

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      final name = cell(row, 'name');
      if (name.isEmpty) continue;

      final companyName = cell(row, 'company');
      Company? target;
      for (final c in _companies) {
        if (c.name.toLowerCase() == companyName.toLowerCase()) {
          target = c;
          break;
        }
      }
      if (target == null && fallbackCompanyId != null) {
        target = companyById(fallbackCompanyId);
      }
      if (target == null && companyName.isEmpty && _companies.isNotEmpty) {
        target = _companies.first;
      }
      if (target == null) {
        skipped.add('$name (şirket bulunamadı: $companyName)');
        continue;
      }

      var salary = Fmt.parseAmount(cell(row, 'salary')) ?? 0;
      if (salary <= 0) {
        salary = distributeSalary(target.salaryLimit,
            salaryMin: target.effectiveSalaryMin);
      }
      if (salary > target.salaryLimit) {
        skipped.add('$name (maaş sınırı aşılıyor)');
        continue;
      }

      final months = Fmt.parseInt(cell(row, 'months')) ??
          settings.defaultContractMonths;

      try {
        addUser(
          fullName: name,
          email: cell(row, 'email').isEmpty ? null : cell(row, 'email'),
          password: cell(row, 'password').isEmpty ? null : cell(row, 'password'),
          role: UserRole.employee,
          companyId: target.id,
          title: cell(row, 'title').isEmpty ? 'Çalışan' : cell(row, 'title'),
          department: cell(row, 'department'),
          phone: cell(row, 'phone'),
          salary: salary,
          balance: Fmt.parseAmount(cell(row, 'balance')) ?? 0,
          terminationFee: salary * settings.defaultTerminationMultiplier,
          contractEnd: now.add(Duration(days: months.clamp(1, 120) * 30)),
          persist: false,
        );
        added++;
        totalSalary += salary;
      } catch (e) {
        skipped.add('$name (${e.toString().replaceAll('Exception: ', '')})');
      }
    }

    if (added > 0) {
      addTxn(TxnType.system, 0, 'BANK', fallbackCompanyId ?? 'BANK',
          'CSV ile $added kullanıcı eklendi');
      log('CSV içe aktarma',
          detail: '$added kullanıcı eklendi', level: LogLevel.success);
      _persist();
      _safeNotify();
    }
    return ImportUsersResult(
        added: added, skipped: skipped, totalSalary: totalSalary);
  }

  String exportUsersCsv() {
    final rows = <List<String>>[
      [
        'Ad Soyad',
        'E-posta',
        'Şirket',
        'Unvan',
        'Departman',
        'Maaş',
        'Aylık Prim',
        'Bakiye',
        'Kıdem',
        'Sözleşme Bitişi',
        'Fesih Ücreti',
        'Durum',
        'Telefon',
      ],
      for (final u in _users)
        [
          u.fullName,
          u.email,
          companyById(u.companyId)?.name ?? '-',
          u.title,
          u.department,
          u.salary.toStringAsFixed(2),
          u.bonus.toStringAsFixed(2),
          u.balance.toStringAsFixed(2),
          Fmt.date(u.hireDate),
          Fmt.date(u.contractEnd),
          u.terminationFee.toStringAsFixed(2),
          u.isActive ? 'Aktif' : 'Pasif',
          u.phone,
        ],
    ];
    return ExportService.csvEncode(rows);
  }

  String exportTransactionsCsv({List<Txn>? source}) {
    final list = source ?? transactions;
    final rows = <List<String>>[
      [
        'Tarih',
        'Tür',
        'Tutar',
        'Gönderen',
        'Alıcı',
        'Açıklama',
        'Referans',
      ],
      for (final t in list)
        [
          Fmt.dateTime(t.date),
          t.type.label,
          t.amount.toStringAsFixed(2),
          accountLabel(t.fromId),
          accountLabel(t.toId),
          t.description,
          t.reference,
        ],
    ];
    return ExportService.csvEncode(rows);
  }

  String exportAuditCsv() {
    final rows = <List<String>>[
      ['Tarih', 'Kullanıcı', 'İşlem', 'Detay', 'Seviye'],
      for (final a in auditLog)
        [
          Fmt.dateTime(a.date),
          a.actorName,
          a.action,
          a.detail,
          a.level.label,
        ],
    ];
    return ExportService.csvEncode(rows);
  }

  String exportCsvTemplate() {
    return ExportService.csvEncode([
      ['Ad Soyad', 'E-posta', 'Unvan', 'Maaş', 'Şirket', 'Departman', 'Telefon', 'Sözleşme (ay)', 'Şifre'],
      [
        'Örnek Çalışan',
        'ornek@firma.com',
        'Uzman',
        '32000',
        _companies.isEmpty ? 'Şirketim' : _companies.first.name,
        'Operasyon',
        '+90 555 000 00 00',
        '12',
        '123456',
      ],
    ]);
  }

  Map<String, dynamic> snapshotData() => {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
        'users': _users.map((e) => e.toJson()).toList(),
        'companies': _companies.map((e) => e.toJson()).toList(),
        'transactions': _transactions.map((e) => e.toJson()).toList(),
        'loans': _loans.map((e) => e.toJson()).toList(),
        'audit': _audit.map((e) => e.toJson()).toList(),
        'notifications': _notifications.map((e) => e.toJson()).toList(),
      };

  String exportBackupJson() => ExportService.jsonPretty(snapshotData());

  /// Yedekten geri yükleme. Hata varsa mesaj döndürür, başarılıysa null.
  String? importBackupJson(String raw, {bool merge = false}) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      return 'Yedek dosyası okunamadı: ${e.toString().replaceAll('Exception: ', '')}';
    }
    if (decoded is! Map) return 'Yedek dosyası geçersiz (JSON nesnesi bekleniyordu).';
    final data = Map<String, dynamic>.from(decoded);
    if (!data.containsKey('users') && !data.containsKey('companies')) {
      return 'Bu dosya bir Arena Bank yedeği değil.';
    }

    pushSnapshot(merge ? 'Yedek birleştirme' : 'Yedekten geri yükleme');
    try {
      if (!merge) {
        _users = _mapList(data['users'], AppUser.fromJson);
        _companies = _mapList(data['companies'], Company.fromJson);
        _transactions = _mapList(data['transactions'], Txn.fromJson);
        _loans = _mapList(data['loans'], Loan.fromJson);
        _audit = _mapList(data['audit'], AuditEntry.fromJson);
        _notifications =
            _mapList(data['notifications'], AppNotification.fromJson);
        final s = data['settings'];
        if (s is Map && s.isNotEmpty) {
          settings = BankSettings.fromJson(Map<String, dynamic>.from(s));
        }
      } else {
        final existingEmails = _users.map((u) => u.email.toLowerCase()).toSet();
        for (final u in _mapList(data['users'], AppUser.fromJson)) {
          if (existingEmails.contains(u.email.toLowerCase())) continue;
          _users.add(u);
          existingEmails.add(u.email.toLowerCase());
        }
        for (final c in _mapList(data['companies'], Company.fromJson)) {
          if (_companies.any((x) => x.id == c.id)) continue;
          _companies.add(c);
        }
        for (final t in _mapList(data['transactions'], Txn.fromJson)) {
          if (_transactions.any((x) => x.id == t.id)) continue;
          _transactions.add(t);
        }
        for (final l in _mapList(data['loans'], Loan.fromJson)) {
          if (_loans.any((x) => x.id == l.id)) continue;
          _loans.add(l);
        }
      }
    } catch (e) {
      return 'Geri yükleme sırasında hata: ${e.toString().replaceAll('Exception: ', '')}';
    }

    _ensureSuperAdmin();
    _loanCleanupForMissingUsers();
    if (currentUser != null) currentUser = userById(currentUser!.id);
    log(merge ? 'Yedek birleştirildi' : 'Yedekten geri yüklendi',
        detail: '${_users.length} kullanıcı • ${_companies.length} şirket',
        level: LogLevel.warning);
    _persist();
    _safeNotify();
    return null;
  }

  // ---------------------------------------------------------------- Maaşlar
  void paySalary(String userId, {bool notify = true}) {
    final u = _user(userId);
    if (u.companyId == null) throw Exception('Kullanıcı herhangi bir şirkete bağlı değil.');
    final c = _company(u.companyId!);
    if (c.balance < u.salary) {
      throw Exception(
          '${c.name} şirketinin bakiyesi yetersiz (${money(u.salary)} gerekli).');
    }

    final gross = u.salary;
    final tax = settings.taxEnabled ? gross * (settings.taxPercent / 100) : 0.0;
    final net = gross - tax;

    c.balance -= gross;
    u.balance += net;

    final monthLabel = DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now());
    addTxn(TxnType.salary, gross, c.id, u.id,
        '${monthLabel} maaş ödemesi${tax > 0 ? ' (brüt)' : ''}');
    if (tax > 0) {
      addTxn(TxnType.tax, tax, u.id, 'BANK',
          '${monthLabel} gelir vergisi (%${settings.taxPercent.toStringAsFixed(0)})');
    }
    log('Maaş ödendi',
        detail: '${u.fullName} • net ${money(net)}${tax > 0 ? ' • vergi ${money(tax)}' : ''}',
        level: LogLevel.success);
    if (notify) {
      _notify('Maaş ödemesi yapıldı',
          '${u.fullName} → ${money(net)}${tax > 0 ? ' (vergi: ${money(tax)})' : ''}',
          NotifyKind.salary, userId: u.id);
    }
    _advanceSalaryDate(u);
    _persist();
    _safeNotify();
  }

  void _advanceSalaryDate(AppUser u) {
    final today = DateTime.now();
    var year = today.year;
    var month = today.month + 1;
    if (month > 12) {
      year++;
      month = 1;
    }
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = settings.salaryDay.clamp(1, daysInMonth);
    u.salaryDate = DateTime(year, month, day);
  }

  /// Tüm vadesi gelen maaşları öder.
  int processDueSalaries({bool silent = false}) {
    final today = DateTime.now();
    int count = 0;
    double totalPaid = 0;
    for (final u in _users.where((u) =>
        u.role != UserRole.superAdmin && u.companyId != null && u.isActive)) {
      if (u.salaryDate.isAfter(today)) continue;
      try {
        final idx = _companies.indexWhere((x) => x.id == u.companyId);
        if (idx == -1) continue;
        final company = _companies[idx];
        if (company.balance < u.salary) continue;

        final gross = u.salary;
        final tax = settings.taxEnabled ? gross * (settings.taxPercent / 100) : 0.0;
        final net = gross - tax;
        company.balance -= gross;
        u.balance += net;
        addTxn(
          TxnType.salary,
          gross,
          company.id,
          u.id,
          '${DateFormat('MMMM yyyy', 'tr_TR').format(today)} otomatik maaş ödemesi',
        );
        if (tax > 0) {
          addTxn(TxnType.tax, tax, u.id, 'BANK',
              '${DateFormat('MMMM yyyy', 'tr_TR').format(today)} gelir vergisi');
        }
        _advanceSalaryDate(u);
        count++;
        totalPaid += net;
      } catch (_) {}
    }
    if (count > 0) {
      log('Otomatik maaş ödemesi',
          detail: '$count çalışana toplam ${money(totalPaid)} ödendi',
          level: LogLevel.success);
      if (!silent) {
        _notify('Otomatik maaş ödemesi',
            '$count çalışana toplam ${money(totalPaid)} ödendi',
            NotifyKind.salary);
      }
      _persist();
      _safeNotify();
    }
    return count;
  }

  /// Maaş ödemesi yapılabilecek (bakiyesi yeterli) çalışanlar.
  List<AppUser> get payableEmployees => _users
      .where((u) => u.role != UserRole.superAdmin && u.companyId != null && u.isActive)
      .toList();

  // ------------------------------------------------------------------ Prim
  int giveBonusToCompany(String companyId, double amount, [String? note]) {
    if (amount <= 0) throw Exception('Prim tutarı sıfırdan büyük olmalıdır.');
    final company = _company(companyId);
    final employees = _users
        .where((u) =>
            u.companyId == companyId &&
            u.role != UserRole.superAdmin &&
            u.isActive)
        .toList();
    if (employees.isEmpty) {
      throw Exception('Bu şirkette prim verilecek aktif çalışan bulunmuyor.');
    }

    final total = amount * employees.length;
    if (company.balance < total) {
      throw Exception(
          'Şirket bakiyesi yetersiz. ${employees.length} çalışana toplam ${money(total)} gerekli.');
    }

    pushSnapshot('${company.name} toplu prim');
    final desc = note != null && note.trim().isNotEmpty
        ? note.trim()
        : 'Şirket geneli toplu prim';

    for (final u in employees) {
      company.balance -= amount;
      u.balance += amount;
      addTxn(TxnType.bonus, amount, company.id, u.id, desc);
    }
    log('Toplu prim dağıtıldı',
        detail: '${company.name} • ${employees.length} çalışan • ${money(amount)} kişi başı',
        level: LogLevel.success);
    _notify('Toplu prim dağıtıldı',
        '${company.name} • ${employees.length} çalışan • ${money(total)}',
        NotifyKind.bonus);
    _persist();
    _safeNotify();
    return employees.length;
  }

  void giveBonus(String userId, double amount, [String? note]) {
    if (amount <= 0) throw Exception('Prim tutarı sıfırdan büyük olmalıdır.');
    final u = _user(userId);

    pushSnapshot('${u.fullName} prim ödemesi');
    String payerId = 'BANK';
    final company = companyById(u.companyId);
    if (company != null) {
      if (company.balance < amount) {
        throw Exception('Şirket bakiyesi prim ödemesi için yetersiz.');
      }
      company.balance -= amount;
      payerId = company.id;
    }

    u.balance += amount;
    final desc = note != null && note.trim().isNotEmpty
        ? note.trim()
        : 'Performans primi ödendi';
    addTxn(TxnType.bonus, amount, payerId, u.id, desc);
    log('Prim ödendi', detail: '${u.fullName} • ${money(amount)}',
        level: LogLevel.success);
    _notify('Prim ödemesi', '${u.fullName} → ${money(amount)}', NotifyKind.bonus,
        userId: u.id);
    _persist();
    _safeNotify();
  }

  void setMonthlyBonus(String userId, double amount) {
    if (amount < 0) throw Exception('Aylık prim negatif olamaz.');
    final u = _user(userId);
    u.bonus = amount;
    log('Aylık prim tanımlandı', detail: '${u.fullName} • ${money(amount)}');
    _persist();
    _safeNotify();
  }

  /// Tanımlı aylık primleri tüm çalışanlara öder.
  int payMonthlyBonuses() {
    int count = 0;
    double total = 0;
    for (final u in _users.where((u) =>
        u.bonus > 0 && u.isActive && u.role != UserRole.superAdmin)) {
      final company = companyById(u.companyId);
      if (company == null || company.balance < u.bonus) continue;
      company.balance -= u.bonus;
      u.balance += u.bonus;
      addTxn(TxnType.bonus, u.bonus, company.id, u.id, 'Aylık tanımlı prim');
      count++;
      total += u.bonus;
    }
    if (count > 0) {
      log('Aylık primler ödendi',
          detail: '$count çalışan • ${money(total)}', level: LogLevel.success);
      _persist();
      _safeNotify();
    }
    return count;
  }

  // ------------------------------------------------------------------ Ceza
  void applyPenalty(String userId, double amount, String reason,
      {bool percentage = false}) {
    if (amount <= 0) throw Exception('Ceza tutarı sıfırdan büyük olmalıdır.');
    if (!settings.penaltyEnabled) {
      throw Exception('Ceza sistemi ayarlardan kapatılmış.');
    }
    final u = _user(userId);

    double penalty = amount;
    if (percentage) {
      if (amount > settings.penaltyMaxPercent) {
        throw Exception(
            'Maaş kesintisi yüzde ${settings.penaltyMaxPercent.toStringAsFixed(0)}\'den fazla olamaz.');
      }
      penalty = u.salary * (amount / 100);
    }

    if (penalty <= 0) throw Exception('Hesaplanan ceza tutarı geçersiz.');
    if (u.balance < penalty) {
      throw Exception(
          'Kullanıcı bakiyesi cezayı karşılamıyor (Mevcut: ${money(u.balance)}, Ceza: ${money(penalty)}).');
    }

    pushSnapshot('${u.fullName} ceza');
    u.balance -= penalty;
    String receiverId = 'BANK';
    final company = companyById(u.companyId);
    if (company != null) {
      company.balance += penalty;
      receiverId = company.id;
    }

    final reasonStr = reason.trim().isEmpty ? 'Disiplin cezası' : reason.trim();
    addTxn(
      TxnType.penalty,
      penalty,
      u.id,
      receiverId,
      'Ceza: $reasonStr${percentage ? ' (%${amount.toStringAsFixed(0)} maaş kesintisi)' : ''}',
    );
    log('Ceza uygulandı',
        detail: '${u.fullName} • ${money(penalty)} • $reasonStr',
        level: LogLevel.warning);
    _notify('Ceza uygulandı', '${u.fullName} • ${money(penalty)} • $reasonStr',
        NotifyKind.penalty, userId: u.id);
    _persist();
    _safeNotify();
  }

  // ----------------------------------------------------------------- Terfi
  void promote(String userId, String newTitle, double newSalary,
      [double bonus = 0]) {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) throw Exception('Unvan boş bırakılamaz.');
    if (newSalary < 0) throw Exception('Yeni maaş negatif olamaz.');
    if (bonus < 0) throw Exception('Terfi primi negatif olamaz.');

    final u = _user(userId);
    final company = companyById(u.companyId);
    if (company != null &&
        company.salaryLimit > 0 &&
        newSalary > company.salaryLimit) {
      throw Exception(
          'Yeni maaş, ${company.name} maaş sınırını (${money(company.salaryLimit)}) aşıyor.');
    }

    pushSnapshot('${u.fullName} terfi');
    final oldTitle = u.title;
    final oldSalary = u.salary;

    if (bonus > 0 && company != null) {
      if (company.balance < bonus) {
        throw Exception('Şirket bakiyesi terfi primi için yetersiz.');
      }
      company.balance -= bonus;
    }

    u.title = cleanTitle;
    u.salary = newSalary;
    if (bonus > 0) u.balance += bonus;

    addTxn(
      TxnType.promotion,
      bonus,
      u.companyId ?? 'BANK',
      u.id,
      'Terfi: $oldTitle → $cleanTitle (Maaş: ${money(oldSalary)} → ${money(newSalary)})${bonus > 0 ? ' + ${money(bonus)} terfi primi' : ''}',
    );
    log('Terfi verildi',
        detail: '${u.fullName} • $oldTitle → $cleanTitle • ${money(newSalary)}',
        level: LogLevel.success);
    _notify('Terfi', '${u.fullName} → $cleanTitle (${money(newSalary)})',
        NotifyKind.info, userId: u.id);
    _persist();
    _safeNotify();
  }

  // ------------------------------------------------- Rastgele kredi kesintisi
  double applyRandomDeduction(String userId) {
    if (!settings.randomDeductionEnabled) return 0.0;
    final u = _user(userId);
    if (u.balance <= 0) return 0.0;

    double amount;
    if (settings.randomDeductionPercent) {
      final minP = min(settings.randomDeductionMin, settings.randomDeductionMax);
      final maxP = max(settings.randomDeductionMin, settings.randomDeductionMax);
      final pct = minP == maxP ? minP : minP + _rnd.nextDouble() * (maxP - minP);
      amount = u.salary * (pct.clamp(0.0, 90.0) / 100);
    } else {
      final minVal = min(settings.randomDeductionMin, settings.randomDeductionMax);
      final maxVal = max(settings.randomDeductionMin, settings.randomDeductionMax);
      amount = minVal == maxVal ? minVal : minVal + _rnd.nextDouble() * (maxVal - minVal);
    }

    final deduction = min<num>(amount, u.balance).toDouble();
    if (deduction <= 0) return 0.0;

    u.balance -= deduction;
    addTxn(TxnType.randomDeduction, deduction, u.id, 'BANK',
        'Rastgele kredi kesintisi${settings.randomDeductionPercent ? ' (% maaş)' : ''}');
    return deduction;
  }

  int applyRandomDeductionsToAll() {
    if (!settings.randomDeductionEnabled) {
      throw Exception('Rastgele kesinti sistemi ayarlardan kapatılmış.');
    }
    pushSnapshot('Rastgele kesinti uygulaması');
    int count = 0;
    double total = 0;
    for (final u in _users.where((u) =>
        u.role != UserRole.superAdmin && u.isActive && u.balance > 0)) {
      final d = applyRandomDeduction(u.id);
      if (d > 0) {
        count++;
        total += d;
      }
    }
    if (count > 0) {
      log('Rastgele kesinti uygulandı',
          detail: '$count çalışan • toplam ${money(total)}',
          level: LogLevel.warning);
      _notify('Rastgele kredi kesintisi',
          '$count çalışandan toplam ${money(total)} kesildi',
          NotifyKind.penalty);
      _persist();
      _safeNotify();
    }
    return count;
  }

  // -------------------------------------------------------------- Sözleşme
  void transferEmployee(String userId, String newCompanyId,
      {bool chargeTerminationFee = true}) {
    final u = _user(userId);
    if (u.companyId == newCompanyId) {
      throw Exception('Kullanıcı zaten bu şirkette çalışıyor.');
    }
    final targetComp = _company(newCompanyId);
    pushSnapshot('${u.fullName} transfer');
    final now = DateTime.now();
    final oldCompanyId = u.companyId;

    if (chargeTerminationFee && u.contractEnd.isAfter(now) && u.terminationFee > 0) {
      final fee = u.terminationFee;
      if (u.balance < fee) {
        throw Exception(
            'Erken fesih ücreti (${money(fee)}) için bakiye yetersiz. Fesih ücretini devre dışı bırakabilirsiniz.');
      }
      u.balance -= fee;
      final oldCompany = companyById(oldCompanyId);
      oldCompany?.balance += fee;
      addTxn(TxnType.terminationFee, fee, u.id, oldCompanyId ?? 'BANK',
          'Sözleşme erken fesih tazminatı ödendi');
    }

    u.companyId = newCompanyId;
    u.contractStart = now;
    u.contractEnd = now.add(Duration(days: settings.defaultContractMonths * 30));
    u.isActive = true;

    addTxn(TxnType.transfer, 0, oldCompanyId ?? 'BANK', targetComp.id,
        '${u.fullName} adlı çalışan ${targetComp.name} şirketine transfer edildi');
    log('Şirket transferi',
        detail: '${u.fullName} → ${targetComp.name}', level: LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void renewContract(String userId, int months, double newTerminationFee) {
    if (months <= 0) throw Exception('Sözleşme süresi en az 1 ay olmalıdır.');
    if (newTerminationFee < 0) throw Exception('Fesih ücreti negatif olamaz.');

    final u = _user(userId);
    pushSnapshot('${u.fullName} sözleşme yenileme');
    final baseDate = u.contractEnd.isAfter(DateTime.now()) ? u.contractEnd : DateTime.now();
    u.contractEnd = baseDate.add(Duration(days: months * 30));
    u.terminationFee = newTerminationFee;

    addTxn(TxnType.system, 0, 'BANK', u.id,
        'Sözleşme $months ay uzatıldı (Yeni Bitiş: ${Fmt.date(u.contractEnd)})');
    log('Sözleşme yenilendi',
        detail: '${u.fullName} • $months ay • bitiş ${Fmt.date(u.contractEnd)}',
        level: LogLevel.success);
    _persist();
    _safeNotify();
  }

  /// İşten çıkarma: fesih tazminatı şirketten çalışana ödenir.
  void dismissEmployee(String userId, String reason,
      {bool payTerminationFee = true}) {
    final u = _user(userId);
    pushSnapshot('${u.fullName} işten çıkarma');
    double paid = 0;
    if (payTerminationFee && u.terminationFee > 0) {
      final company = companyById(u.companyId);
      final fee = u.terminationFee;
      if (company != null && company.balance >= fee) {
        company.balance -= fee;
        u.balance += fee;
        paid = fee;
        addTxn(TxnType.terminationFee, fee, company.id, u.id,
            'İşten çıkarma tazminatı${reason.trim().isEmpty ? '' : ' • ${reason.trim()}'}');
      }
    }
    u.isActive = false;
    final loans = _loans.where((l) => l.userId == u.id && l.isActive).toList();
    for (final l in loans) {
      l.isActive = false;
    }
    log('Çalışan işten çıkarıldı',
        detail:
            '${u.fullName}${paid > 0 ? ' • tazminat ${money(paid)}' : ''}${reason.trim().isEmpty ? '' : ' • ${reason.trim()}'}',
        level: LogLevel.danger);
    _notify('İşten çıkarma', '${u.fullName} pasife alındı', NotifyKind.risk,
        userId: u.id);
    _persist();
    _safeNotify();
  }

  /// Ayarlardaki gün sayısına göre süresi yaklaşan sözleşmeleri bildirir.
  int checkContractAlerts() {
    final soon = riskyContracts();
    if (soon.isEmpty) return 0;
    final alreadyNotified = _notifications
        .where((n) =>
            n.kind == NotifyKind.contract &&
            n.date.isAfter(DateTime.now().subtract(const Duration(hours: 12))))
        .length;
    if (alreadyNotified > 0) return 0;
    _notify(
      '${soon.length} sözleşme yenileme zamanı',
      '${soon.take(3).map((u) => u.fullName).join(', ')}${soon.length > 3 ? ' ve ${soon.length - 3} kişi daha' : ''}',
      NotifyKind.contract,
    );
    _safeNotify();
    return soon.length;
  }

  int renewExpiredContracts({bool silent = false}) {
    final expired = _users
        .where((u) =>
            u.role != UserRole.superAdmin &&
            u.companyId != null &&
            u.isActive &&
            u.contractEnd.isBefore(DateTime.now()))
        .toList();
    if (expired.isEmpty) return 0;
    for (final u in expired) {
      u.contractStart = DateTime.now();
      u.contractEnd =
          DateTime.now().add(Duration(days: settings.defaultContractMonths * 30));
      u.terminationFee = u.salary * settings.defaultTerminationMultiplier;
      addTxn(TxnType.system, 0, 'BANK', u.id,
          'Sözleşme otomatik olarak ${settings.defaultContractMonths} ay uzatıldı');
    }
    log('Otomatik sözleşme yenileme',
        detail: '${expired.length} sözleşme uzatıldı', level: LogLevel.info);
    if (!silent) {
      _notify('Sözleşmeler yenilendi',
          '${expired.length} sözleşme otomatik uzatıldı', NotifyKind.contract);
    }
    _persist();
    _safeNotify();
    return expired.length;
  }

  // ---------------------------------------------------------------- Krediler
  Loan _buildLoan({
    required String userId,
    required double amount,
    required int installments,
    String note = '',
    DateTime? startDate,
  }) {
    final interest = settings.loanInterestPercent;
    final totalPayable = amount * (1 + interest / 100);
    final installmentAmount = totalPayable / installments;
    final start = startDate ?? DateTime.now();
    return Loan(
      id: 'loan-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(999)}',
      userId: userId,
      principal: amount,
      totalPayable: totalPayable,
      installmentAmount: installmentAmount,
      totalInstallments: installments,
      paidInstallments: 0,
      startDate: start,
      nextDueDate: start.add(const Duration(days: 30)),
      note: note,
    );
  }

  double maxLoanFor(AppUser user) {
    final byLimit = user.salary * settings.loanMaxSalaryMultiplier;
    return min(byLimit, settings.loanMaxAmount);
  }

  void giveLoan(String userId, double amount, int installments, {String note = ''}) {
    if (!settings.loansEnabled) {
      throw Exception('Kredi sistemi ayarlardan kapatılmış.');
    }
    if (amount <= 0) throw Exception('Kredi tutarı sıfırdan büyük olmalıdır.');
    if (installments < 1) throw Exception('Taksit sayısı en az 1 olmalıdır.');
    if (installments > settings.loanMaxInstallments) {
      throw Exception(
          'Taksit sayısı en fazla ${settings.loanMaxInstallments} olabilir.');
    }
    final u = _user(userId);
    if (u.role == UserRole.superAdmin) {
      throw Exception('Süper admine kredi verilemez.');
    }
    final maxLoan = maxLoanFor(u);
    if (amount > maxLoan) {
      throw Exception(
          'Bu çalışan için en fazla ${money(maxLoan)} kredi verilebilir (maaşın ${settings.loanMaxSalaryMultiplier.toStringAsFixed(0)} katı / üst limit).');
    }

    pushSnapshot('${u.fullName} kredi kullanımı');
    final loan = _buildLoan(
      userId: userId,
      amount: amount,
      installments: installments,
      note: note.trim(),
    );
    _loans.add(loan);
    u.balance += amount;
    addTxn(TxnType.loan, amount, 'BANK', u.id,
        'Kredi kullanımı • $installments taksit${note.trim().isEmpty ? '' : ' • ${note.trim()}'}');
    log('Kredi verildi',
        detail: '${u.fullName} • ${money(amount)} • $installments taksit',
        level: LogLevel.info);
    _notify('Kredi kullanımı',
        '${u.fullName} → ${money(amount)} ($installments taksit)',
        NotifyKind.info, userId: u.id);
    _persist();
    _safeNotify();
  }

  double payLoanInstallment(String loanId, {bool silent = false}) {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1) throw Exception('Kredi kaydı bulunamadı.');
    final loan = _loans[idx];
    if (loan.isFinished) throw Exception('Bu kredinin taksitleri tamamlanmış.');
    final u = _user(loan.userId);
    final amount = min(loan.installmentAmount, loan.remaining);
    if (u.balance < amount) {
      throw Exception(
          '${u.fullName} bakiyesi taksit için yetersiz (gerekli: ${money(amount)}).');
    }
    u.balance -= amount;
    loan.paidInstallments += 1;
    loan.nextDueDate = DateTime.now().add(const Duration(days: 30));
    if (loan.isFinished) loan.isActive = false;
    _loans[idx] = loan;
    addTxn(TxnType.loanRepayment, amount, u.id, 'BANK',
        'Kredi taksidi (${loan.paidInstallments}/${loan.totalInstallments})');
    if (!silent) {
      log('Kredi taksidi tahsil edildi',
          detail: '${u.fullName} • ${money(amount)}',
          level: LogLevel.success);
      _notify('Kredi taksidi', '${u.fullName} → ${money(amount)}',
          NotifyKind.info, userId: u.id);
      _persist();
      _safeNotify();
    }
    return amount;
  }

  /// Maaş ödemesi sırasında kredisi olan çalışanların taksitlerini tahsil eder.
  int payDueLoanInstallments({bool silent = false}) {
    int count = 0;
    final active = _loans.where((l) => l.isActive && !l.isFinished).toList();
    for (final loan in active) {
      final u = userById(loan.userId);
      if (u == null || !u.isActive) continue;
      try {
        payLoanInstallment(loan.id, silent: true);
        count++;
      } catch (_) {}
    }
    if (count > 0) {
      log('Kredi taksitleri tahsil edildi',
          detail: '$count taksit', level: LogLevel.info);
      if (!silent) {
        _notify('Kredi taksitleri', '$count taksit tahsil edildi',
            NotifyKind.info);
      }
      _persist();
      _safeNotify();
    }
    return count;
  }

  void closeLoan(String loanId) {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1) throw Exception('Kredi kaydı bulunamadı.');
    _loans[idx].isActive = false;
    log('Kredi kapatıldı', detail: _loans[idx].id, level: LogLevel.warning);
    _persist();
    _safeNotify();
  }

  void deleteLoan(String loanId) {
    _loans.removeWhere((l) => l.id == loanId);
    log('Kredi kaydı silindi', detail: loanId, level: LogLevel.danger);
    _persist();
    _safeNotify();
  }

  List<Loan> loansOfUser(String userId) =>
      _loans.where((l) => l.userId == userId).toList();

  // ---------------------------------------------------------------- Transfer
  void userTransfer(String fromUserId, String toUserId, double amount,
      String note, {bool bypassSettings = false}) {
    if (fromUserId == toUserId) {
      throw Exception('Kendi hesabınıza transfer yapamazsınız.');
    }
    if (amount <= 0 || amount.isNaN || amount.isInfinite) {
      throw Exception('Geçerli bir transfer tutarı girin.');
    }

    final from = _user(fromUserId);
    final to = _user(toUserId);

    if (!bypassSettings) {
      if (!settings.transfersEnabled) {
        throw Exception('Para transferleri ayarlardan kapatılmış.');
      }
      if (!settings.allowCrossCompanyTransfers &&
          from.companyId != to.companyId &&
          from.role != UserRole.superAdmin) {
        throw Exception('Farklı şirketler arası transfer kapalı.');
      }
      if (amount < settings.transferMinAmount) {
        throw Exception(
            'En az ${money(settings.transferMinAmount)} transfer edilebilir.');
      }
      if (settings.transferMaxAmount > 0 && amount > settings.transferMaxAmount) {
        throw Exception(
            'Tek işlemde en fazla ${money(settings.transferMaxAmount)} transfer edilebilir.');
      }
      if (settings.requireTransferNote && note.trim().length < 3) {
        throw Exception('Bu bankada transfer için açıklama zorunludur.');
      }
    }

    if (!from.isActive) throw Exception('Gönderen hesap aktif değil.');
    if (!to.isActive) throw Exception('Alıcı hesap aktif değil.');

    final fee = amount * (settings.transferFeePercent / 100);
    final total = amount + fee;
    if (from.balance < total) {
      throw Exception(
          'Yetersiz bakiye (Mevcut: ${money(from.balance)}${fee > 0 ? ', komisyon dahil gerekli: ${money(total)}' : ''}).');
    }

    pushSnapshot('Transfer: ${from.fullName} → ${to.fullName}');
    from.balance -= total;
    to.balance += amount;

    final cleanNote = note.trim().isEmpty
        ? '${from.fullName} → ${to.fullName} para transferi'
        : note.trim();

    addTxn(TxnType.transfer, amount, fromUserId, toUserId, cleanNote);
    if (fee > 0) {
      addTxn(TxnType.expense, fee, fromUserId, 'BANK',
          'Transfer komisyonu (%${settings.transferFeePercent.toStringAsFixed(2)})');
    }
    log('Transfer yapıldı',
        detail: '${from.fullName} → ${to.fullName} • ${money(amount)}',
        level: LogLevel.success);
    _persist();
    _safeNotify();
  }

  /// Şirketten çalışana doğrudan ödeme (avans, ek ödeme, gider).
  void payFromCompany(
      String companyId, String userId, double amount, String reason) {
    if (amount <= 0) throw Exception('Tutar sıfırdan büyük olmalıdır.');
    final company = _company(companyId);
    final u = _user(userId);
    if (company.balance < amount) {
      throw Exception('${company.name} bakiyesi yetersiz.');
    }
    pushSnapshot('${company.name} → ${u.fullName} ödeme');
    company.balance -= amount;
    u.balance += amount;
    addTxn(TxnType.bonus, amount, company.id, u.id,
        reason.trim().isEmpty ? 'Şirket ödemesi' : reason.trim());
    log('Şirket ödemesi',
        detail: '${company.name} → ${u.fullName} • ${money(amount)}');
    _persist();
    _safeNotify();
  }

  // ---------------------------------------------------------------- Ayarlar
  void updateSettings(BankSettings s) {
    if (s.bankName.trim().isEmpty) throw Exception('Banka adı boş olamaz.');
    if (s.currency.trim().isEmpty) throw Exception('Para birimi boş olamaz.');
    if (s.randomDeductionMin < 0 || s.randomDeductionMax < 0) {
      throw Exception('Kesinti tutarları negatif olamaz.');
    }
    if (s.randomDeductionMin > s.randomDeductionMax) {
      throw Exception('Minimum kesinti maksimum kesintiden büyük olamaz.');
    }
    if (s.salaryDay < 1 || s.salaryDay > 31) {
      throw Exception('Maaş günü 1 ile 31 arasında olmalıdır.');
    }
    if (s.salaryMinRatio <= 0 || s.salaryMinRatio > 1) {
      throw Exception('Maaş alt sınır oranı 0 ile 1 arasında olmalıdır.');
    }

    pushSnapshot('Banka ayarları güncellendi');
    settings = s;
    addTxn(TxnType.system, 0, 'BANK', 'BANK', 'Banka ayarları güncellendi');
    log('Banka ayarları güncellendi',
        detail: '${s.bankName} • ${s.currency}', level: LogLevel.success);
    _persist();
    _safeNotify();
  }

  /// Ayarları tek bir alanda güncellemek için pratik yardımcı.
  void patchSettings(
    void Function(BankSettings s) mutate, {
    String? logMessage,
    bool snapshot = false,
    bool notify = true,
  }) {
    if (snapshot) pushSnapshot(logMessage ?? 'Ayar değişikliği');
    mutate(settings);
    if (logMessage != null) log(logMessage);
    _persist();
    if (notify) _safeNotify();
  }

  void setThemeMode(String mode) =>
      patchSettings((s) => s.themeMode = mode, notify: true);

  void setAccent(String accentId) =>
      patchSettings((s) => s.accentId = accentId, notify: true);

  void setDensity(String density) =>
      patchSettings((s) => s.density = density, notify: true);

  void setAnimations(bool enabled) =>
      patchSettings((s) => s.animationsEnabled = enabled, notify: true);

  void setGradientBackground(bool enabled) =>
      patchSettings((s) => s.gradientBackground = enabled, notify: true);

  void toggleModule(String key, bool enabled) => patchSettings(
        (s) => s.modules[key] = enabled,
        logMessage:
            'Modül ${enabled ? 'açıldı' : 'kapatıldı'}: $key',
        notify: true,
      );

  // --------------------------------------------------------------- Sorgular
  List<AppUser> usersOfCompany(String companyId) =>
      _users.where((u) => u.companyId == companyId).toList();

  List<Txn> txnsOfUser(String userId) => _transactions
      .where((t) => t.fromId == userId || t.toId == userId)
      .toList()
      .reversed
      .toList();

  List<Txn> txnsOfCompany(String companyId) => _transactions
      .where((t) => t.fromId == companyId || t.toId == companyId)
      .toList()
      .reversed
      .toList();

  Company? companyById(String? id) {
    if (id == null) return null;
    for (final c in _companies) {
      if (c.id == id) return c;
    }
    return null;
  }

  AppUser? userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Hesap kimliğini okunabilir isme çevirir.
  String accountLabel(String id) {
    if (id == 'BANK' || id.isEmpty) return 'Merkez Banka';
    final user = userById(id);
    if (user != null) return user.fullName;
    final company = companyById(id);
    if (company != null) return company.name;
    return id;
  }

  List<AppUser> searchUsers({
    String query = '',
    String companyQuery = '',
    String titleQuery = '',
    String? companyId,
    UserRole? role,
    bool? activeOnly,
    String sortBy = 'name',
    bool ascending = true,
  }) {
    final q = query.trim().toLowerCase();
    final cq = companyQuery.trim().toLowerCase();
    final tq = titleQuery.trim().toLowerCase();

    var list = _users.where((u) {
      if (activeOnly == true && !u.isActive) return false;
      if (activeOnly == false && u.isActive) return false;
      if (role != null && u.role != role) return false;
      if (companyId != null && u.companyId != companyId) return false;
      if (q.isNotEmpty &&
          !u.fullName.toLowerCase().contains(q) &&
          !u.email.toLowerCase().contains(q) &&
          !u.title.toLowerCase().contains(q) &&
          !u.department.toLowerCase().contains(q)) {
        return false;
      }
      if (cq.isNotEmpty) {
        final cname = companyById(u.companyId)?.name.toLowerCase() ?? '';
        if (!cname.contains(cq)) return false;
      }
      if (tq.isNotEmpty && !u.title.toLowerCase().contains(tq)) return false;
      return true;
    }).toList();

    int compare(AppUser a, AppUser b) {
      switch (sortBy) {
        case 'salary':
          return a.salary.compareTo(b.salary);
        case 'balance':
          return a.balance.compareTo(b.balance);
        case 'title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'company':
          final ca = companyById(a.companyId)?.name.toLowerCase() ?? '';
          final cb = companyById(b.companyId)?.name.toLowerCase() ?? '';
          return ca.compareTo(cb);
        case 'contract':
          return a.contractEnd.compareTo(b.contractEnd);
        default:
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      }
    }

    list.sort((a, b) => ascending ? compare(a, b) : compare(b, a));
    return list;
  }

  List<Txn> filterTxns({
    Set<TxnType>? types,
    DateTime? from,
    DateTime? to,
    double? minAmount,
    double? maxAmount,
    String query = '',
    String? companyId,
    String? userId,
    bool excludeZero = false,
    bool onlyIncome = false,
    bool onlyExpense = false,
  }) {
    final q = query.trim().toLowerCase();
    return _transactions.where((t) {
      if (types != null && types.isNotEmpty && !types.contains(t.type)) {
        return false;
      }
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null && t.date.isAfter(to)) return false;
      if (minAmount != null && t.amount < minAmount) return false;
      if (maxAmount != null && t.amount > maxAmount) return false;
      if (excludeZero && t.amount == 0) return false;
      if (onlyIncome && !t.type.isIncoming) return false;
      if (onlyExpense && !t.type.isOutgoing) return false;
      if (companyId != null &&
          t.fromId != companyId &&
          t.toId != companyId) {
        return false;
      }
      if (userId != null && t.fromId != userId && t.toId != userId) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${t.description} ${t.type.label} ${accountLabel(t.fromId)} ${accountLabel(t.toId)} ${t.reference}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ------------------------------------------------------------ İstatistik
  double get totalCompanyBalance =>
      _companies.fold(0.0, (sum, c) => sum + c.balance);

  double get totalUserBalance =>
      _users.fold(0.0, (sum, u) => sum + u.balance);

  double get totalBankAssets => totalCompanyBalance + totalUserBalance;

  double get totalMonthlySalaries => _users
      .where((u) => u.role != UserRole.superAdmin && u.isActive)
      .fold(0.0, (sum, u) => sum + u.salary);

  double get totalMonthlyBonuses => _users
      .where((u) => u.role != UserRole.superAdmin && u.isActive)
      .fold(0.0, (sum, u) => sum + u.bonus);

  int get activeEmployeeCount =>
      _users.where((u) => u.role == UserRole.employee && u.isActive).length;

  int get passiveUserCount => _users.where((u) => !u.isActive).length;

  double get averageSalary {
    final list =
        _users.where((u) => u.role != UserRole.superAdmin && u.salary > 0).toList();
    if (list.isEmpty) return 0;
    return list.fold(0.0, (sum, u) => sum + u.salary) / list.length;
  }

  double get totalLoanRemaining =>
      _loans.where((l) => l.isActive).fold(0.0, (s, l) => s + l.remaining);

  int get activeLoanCount => _loans.where((l) => l.isActive && !l.isFinished).length;

  List<AppUser> get riskyContracts {
    return riskyContractsList();
  }

  List<AppUser> riskyContractsList() {
    final limit = DateTime.now().add(Duration(days: settings.contractAlertDays));
    return _users
        .where((u) =>
            u.role != UserRole.superAdmin &&
            u.companyId != null &&
            u.contractEnd.isBefore(limit))
        .toList()
      ..sort((a, b) => a.contractEnd.compareTo(b.contractEnd));
  }

  List<AppUser> topEarners({int limit = 5}) {
    final list = _users
        .where((u) => u.role != UserRole.superAdmin)
        .toList()
      ..sort((a, b) => b.salary.compareTo(a.salary));
    return list.take(limit).toList();
  }

  Map<TxnType, double> typeTotals({DateTime? from, DateTime? to}) {
    final map = <TxnType, double>{};
    for (final t in _transactions) {
      if (from != null && t.date.isBefore(from)) continue;
      if (to != null && t.date.isAfter(to)) continue;
      map[t.type] = (map[t.type] ?? 0) + t.amount;
    }
    return map;
  }

  CompanyStats companyStats(String companyId) {
    final employees = usersOfCompany(companyId)
        .where((u) => u.role != UserRole.superAdmin)
        .toList();
    final active = employees.where((u) => u.isActive).toList();
    final monthly = active.fold(0.0, (s, u) => s + u.salary);
    final company = companyById(companyId);
    final limit = company?.salaryLimit ?? 0;
    final avg = active.isEmpty ? 0.0 : monthly / active.length;
    final usage = limit <= 0 ? 0.0 : (avg / limit).clamp(0.0, 1.0);
    return CompanyStats(
      employees: employees.length,
      activeEmployees: active.length,
      monthlySalaries: monthly,
      averageSalary: avg,
      balance: company?.balance ?? 0,
      limitUsage: usage,
    );
  }

  /// Son [months] ayın gelir / gider / maaş serisi (grafikler için).
  List<MonthPoint> monthlySeries({int months = 6}) {
    final now = DateTime.now();
    final points = <MonthPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);
      double income = 0;
      double expense = 0;
      double salaries = 0;
      for (final t in _transactions) {
        if (t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
        if (t.type == TxnType.salary) {
          salaries += t.amount;
          expense += t.amount;
        } else if (t.type.isIncoming) {
          income += t.amount;
        } else if (t.type.isOutgoing) {
          expense += t.amount;
        }
      }
      points.add(MonthPoint(
        month: monthStart,
        income: income,
        expense: expense,
        salaries: salaries,
      ));
    }
    return points;
  }

  double inflowSince(DateTime date) => _transactions
      .where((t) => t.date.isAfter(date) && t.type.isIncoming)
      .fold(0.0, (s, t) => s + t.amount);

  double outflowSince(DateTime date) => _transactions
      .where((t) => t.date.isAfter(date) && t.type.isOutgoing)
      .fold(0.0, (s, t) => s + t.amount);

  int txnsSince(DateTime date) =>
      _transactions.where((t) => t.date.isAfter(date)).length;

  // ------------------------------------------------------------------ Sıfırla
  void resetAll() {
    _users.clear();
    _companies.clear();
    _transactions.clear();
    _loans.clear();
    _audit.clear();
    _notifications.clear();
    _history.clear();
    _historyLabels.clear();
    settings = BankSettings();
    currentUser = null;
    _storage.clearAll();
    _seed();
    _safeNotify();
  }

  /// Tüm veriyi siler, yalnızca varsayılan yönetici hesabını bırakır.
  void clearAllData() {
    pushSnapshot('Tüm veriler silindi');
    _users.clear();
    _companies.clear();
    _transactions.clear();
    _loans.clear();
    _notifications.clear();
    final now = DateTime.now();
    _users.add(AppUser(
      id: 'admin-001',
      fullName: 'Banka Sahibi',
      email: 'admin@bank.com',
      passwordHash: _hash('admin123'),
      role: UserRole.superAdmin,
      title: 'Süper Admin',
      salaryDate: now,
      contractStart: now,
      contractEnd: now.add(const Duration(days: 36500)),
    ));
    log('Tüm veriler silindi',
        detail: 'Varsayılan yönetici hesabı korundu', level: LogLevel.danger);
    _persist();
    _safeNotify();
  }

  void clearTransactions() {
    pushSnapshot('İşlem geçmişi temizlendi');
    _transactions.clear();
    log('İşlem geçmişi temizlendi', level: LogLevel.warning);
    _persist();
    _safeNotify();
  }
}
