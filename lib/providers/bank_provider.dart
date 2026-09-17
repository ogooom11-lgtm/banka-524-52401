import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../models/transaction.dart';
import '../models/bank_settings.dart';
import '../services/storage_service.dart';

export '../models/app_user.dart';
export '../models/company.dart';
export '../models/transaction.dart';
export '../models/bank_settings.dart';

class ImportUsersResult {
  final int added;
  final List<String> skipped;

  const ImportUsersResult({required this.added, required this.skipped});
}

/// Güvenli, platformlar arası tutarlı hash (DJB2 32-bit)
String _hash(String s) {
  int hash = 5381;
  for (final c in s.codeUnits) {
    hash = (((hash << 5) + hash) + c) & 0x7FFFFFFF;
  }
  return hash.toRadixString(16);
}

class BankProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Random _rnd = Random();

  List<AppUser> _users = [];
  List<Company> _companies = [];
  List<Txn> _transactions = [];
  BankSettings settings = BankSettings();

  AppUser? currentUser;
  bool initialized = false;

  List<AppUser> get users => List.unmodifiable(_users);
  List<Company> get companies => List.unmodifiable(_companies);
  List<Txn> get transactions => List.unmodifiable(_transactions.reversed);

  String get currency => settings.currency;
  String get bankName => settings.bankName;

  // ---------- Başlatma ----------
  Future<void> init() async {
    try {
      final data = await _storage.loadAll();

      final usersList = data['users'] as List? ?? [];
      _users = usersList
          .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final compList = data['companies'] as List? ?? [];
      _companies = compList
          .map((e) => Company.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final txnsList = data['transactions'] as List? ?? [];
      _transactions = txnsList
          .map((e) => Txn.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final s = data['settings'] as Map? ?? {};
      if (s.isNotEmpty) {
        settings = BankSettings.fromJson(Map<String, dynamic>.from(s));
      }
    } catch (_) {
      _users = [];
      _companies = [];
      _transactions = [];
      settings = BankSettings();
    }

    if (_users.isEmpty) {
      _seed();
    }

    initialized = true;
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();

    // Varsayılan süper admin
    final admin = AppUser(
      id: 'admin-001',
      fullName: 'Banka Sahibi',
      email: 'admin@bank.com',
      passwordHash: _hash('admin123'),
      role: UserRole.superAdmin,
      salaryDate: now,
      contractStart: now,
      contractEnd: now.add(const Duration(days: 36500)),
    );
    _users.add(admin);

    // Örnek şirket
    final c = Company(
      id: 'comp-001',
      name: 'TechCorp A.Ş.',
      balance: 1000000,
      salaryLimit: 50000,
      createdAt: now,
    );
    _companies.add(c);

    // Örnek çalışan
    final emp = AppUser(
      id: 'emp-001',
      fullName: 'Ahmet Yılmaz',
      email: 'ahmet@techcorp.com',
      passwordHash: _hash('123456'),
      role: UserRole.employee,
      companyId: c.id,
      title: 'Yazılım Geliştirici',
      salary: 45000,
      salaryDate: DateTime(now.year, now.month, settings.salaryDay),
      contractStart: now,
      contractEnd: now.add(const Duration(days: 365)),
      terminationFee: 50000,
    );
    _users.add(emp);

    addTxn(TxnType.credit, c.balance, 'BANK', c.id,
        'TechCorp A.Ş. kuruldu ve başlangıç kredisi yüklendi');
    _persist();
  }

  Future<void> _persist() async {
    await _storage.saveAll(
      users: _users.map((e) => e.toJson()).toList(),
      companies: _companies.map((e) => e.toJson()).toList(),
      transactions: _transactions.map((e) => e.toJson()).toList(),
      settings: settings.toJson(),
    );
  }

  // ---------- İşlem kaydı ----------
  void addTxn(TxnType type, double amount, String from, String to, String desc) {
    _transactions.add(Txn(
      id: 'txn-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(9999)}',
      type: type,
      amount: amount.abs(),
      fromId: from,
      toId: to,
      description: desc,
      date: DateTime.now(),
    ));
  }

  // ---------- Auth (yalnızca yönetici) ----------
  /// Başarılıysa `null`, aksi halde kullanıcıya gösterilecek hata metni.
  String? login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final hash = _hash(password);
    AppUser? found;
    for (final u in _users) {
      if (u.email.toLowerCase() == cleanEmail && u.passwordHash == hash) {
        found = u;
        break;
      }
    }
    if (found == null) {
      return 'E-posta veya şifre hatalı.';
    }
    if (!found.isActive) {
      return 'Hesap aktif değil.';
    }
    if (found.role != UserRole.superAdmin) {
      return 'Bu panele yalnızca yönetici giriş yapabilir.';
    }
    currentUser = found;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------- Şirket yönetimi ----------
  void addCompany(String name, double balance, {double salaryLimit = 50000}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Şirket adı boş bırakılamaz.');
    }
    if (balance < 0) {
      throw Exception('Başlangıç bakiyesi negatif olamaz.');
    }
    if (salaryLimit <= 0) {
      throw Exception('Çalışan maaş sınırı sıfırdan büyük olmalıdır.');
    }

    final c = Company(
      id: 'comp-${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      balance: balance,
      salaryLimit: salaryLimit,
      createdAt: DateTime.now(),
    );
    _companies.add(c);
    if (balance > 0) {
      addTxn(TxnType.credit, balance, 'BANK', c.id,
          'Şirket oluşturuldu - başlangıç kredisi');
    }
    _persist();
    notifyListeners();
  }

  void depositToCompany(String companyId, double amount, String reason) {
    if (amount <= 0) {
      throw Exception('Yüklenecek tutar sıfırdan büyük olmalıdır.');
    }
    final c = _companies.firstWhere(
      (x) => x.id == companyId,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
    c.balance += amount;
    addTxn(TxnType.credit, amount, 'BANK', c.id,
        reason.trim().isEmpty ? 'Kredi yükleme' : reason.trim());
    _persist();
    notifyListeners();
  }

  void withdrawFromCompany(String companyId, double amount, String reason) {
    if (amount <= 0) {
      throw Exception('Düşülecek tutar sıfırdan büyük olmalıdır.');
    }
    final c = _companies.firstWhere(
      (x) => x.id == companyId,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
    if (c.balance < amount) {
      throw Exception('Şirket bakiyesi yetersiz.');
    }
    c.balance -= amount;
    addTxn(TxnType.transfer, amount, c.id, 'BANK',
        reason.trim().isEmpty ? 'Bakiye düşümü' : reason.trim());
    _persist();
    notifyListeners();
  }

  void updateCompanyBalance(String companyId, double newBalance, String reason) {
    if (newBalance < 0) {
      throw Exception('Şirket bakiyesi negatif olamaz.');
    }
    final c = _companies.firstWhere(
      (x) => x.id == companyId,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
    final diff = newBalance - c.balance;
    c.balance = newBalance;
    if (diff > 0) {
      addTxn(TxnType.credit, diff, 'BANK', c.id,
          reason.trim().isEmpty ? 'Manuel bakiye artışı' : reason.trim());
    } else if (diff < 0) {
      addTxn(TxnType.transfer, diff.abs(), c.id, 'BANK',
          reason.trim().isEmpty ? 'Manuel bakiye azalışı' : reason.trim());
    }
    _persist();
    notifyListeners();
  }

  void updateCompany({
    required String id,
    String? name,
    double? salaryLimit,
  }) {
    final c = _companies.firstWhere(
      (x) => x.id == id,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
    if (name != null) {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw Exception('Şirket adı boş bırakılamaz.');
      }
      c.name = cleanName;
    }
    if (salaryLimit != null) {
      if (salaryLimit <= 0) {
        throw Exception('Çalışan maaş sınırı sıfırdan büyük olmalıdır.');
      }
      c.salaryLimit = salaryLimit;
    }
    _persist();
    notifyListeners();
  }

  void deleteCompany(String id) {
    _companies.removeWhere((c) => c.id == id);
    for (final u in _users.where((u) => u.companyId == id)) {
      u.companyId = null;
    }
    _persist();
    notifyListeners();
  }

  // ---------- Kullanıcı yönetimi ----------
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

  String _generateEmail(String fullName) {
    final slug = _slugify(fullName);
    var email = '$slug@bank.local';
    var i = 1;
    while (_users.any((u) => u.email.toLowerCase() == email)) {
      email = '$slug$i@bank.local';
      i++;
    }
    return email;
  }

  /// Şirket maaş sınırına göre (sınırın %50–%100 aralığında) maaş dağıtır.
  double distributeSalary(double salaryLimit) {
    if (salaryLimit <= 0) return 0;
    final minS = salaryLimit * 0.5;
    final raw = minS + _rnd.nextDouble() * (salaryLimit - minS);
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
    double terminationFee = 0,
    bool persist = true,
  }) {
    final cleanName = fullName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Ad Soyad boş bırakılamaz.');
    }

    final cleanEmail = (email == null || email.trim().isEmpty)
        ? _generateEmail(cleanName)
        : email.trim().toLowerCase();
    if (!cleanEmail.contains('@')) {
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
    if (salary < 0) {
      throw Exception('Maaş negatif olamaz.');
    }
    if (terminationFee < 0) {
      throw Exception('Fesih ücreti negatif olamaz.');
    }

    if (companyId != null) {
      final company = companyById(companyId);
      if (company == null) {
        throw Exception('Seçilen şirket bulunamadı.');
      }
      if (company.salaryLimit > 0 && salary > company.salaryLimit) {
        throw Exception(
            'Maaş, ${company.name} şirketinin maaş sınırını (${salary.toStringAsFixed(0)} > ${company.salaryLimit.toStringAsFixed(0)} $currency) aşıyor.');
      }
    }

    final now = DateTime.now();
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
      salaryDate: sDate,
      contractStart: now,
      contractEnd: contractEnd ?? now.add(const Duration(days: 365)),
      terminationFee: terminationFee,
    );
    _users.add(u);
    addTxn(TxnType.system, 0, 'BANK', u.id,
        'Kullanıcı hesabı oluşturuldu: $cleanName');
    if (persist) {
      _persist();
      notifyListeners();
    }
  }

  /// TXT içindeki isimleri şirket maaş sınırına göre kullanıcı olarak ekler.
  /// Her kullanıcıya 1–5 yıl sözleşme ve maaşın 2 veya 3 katı fesih cezası atanır.
  ImportUsersResult importUsersFromNames({
    required List<String> names,
    required String companyId,
  }) {
    final company = _companies.firstWhere(
      (x) => x.id == companyId,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
    if (company.salaryLimit <= 0) {
      throw Exception(
          '${company.name} için çalışan maaş sınırı belirlenmemiş.');
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final raw in names) {
      final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) unique.add(name);
    }
    if (unique.isEmpty) {
      throw Exception('Eklenecek geçerli bir isim bulunamadı.');
    }

    int added = 0;
    final skipped = <String>[];
    final now = DateTime.now();

    for (final name in unique) {
      final salary = distributeSalary(company.salaryLimit);
      final years = 1 + _rnd.nextInt(5); // 1–5 yıl
      final multiplier = _rnd.nextBool() ? 2 : 3;
      try {
        addUser(
          fullName: name,
          role: UserRole.employee,
          companyId: companyId,
          salary: salary,
          contractEnd: now.add(Duration(days: years * 365)),
          terminationFee: salary * multiplier,
          persist: false,
        );
        added++;
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
      _persist();
      notifyListeners();
    }
    return ImportUsersResult(added: added, skipped: skipped);
  }

  void updateUser(AppUser updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _users[idx] = updated;
      if (currentUser?.id == updated.id) {
        currentUser = updated;
      }
      _persist();
      notifyListeners();
    }
  }

  void updateUserName(String userId, String newName) {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Ad Soyad boş bırakılamaz.');
    }
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );
    final oldName = u.fullName;
    u.fullName = cleanName;
    if (currentUser?.id == userId) {
      currentUser = u;
    }
    addTxn(
      TxnType.system,
      0,
      'BANK',
      u.id,
      'Kullanıcı adı güncellendi: $oldName → $cleanName',
    );
    _persist();
    notifyListeners();
  }

  void deleteUser(String id) {
    _users.removeWhere((u) => u.id == id);
    if (currentUser?.id == id) {
      currentUser = null;
    }
    _persist();
    notifyListeners();
  }

  // ---------- Maaş ödeme ----------
  void paySalary(String userId) {
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );
    if (u.companyId == null) {
      throw Exception('Kullanıcı herhangi bir şirkete bağlı değil.');
    }
    final c = _companies.firstWhere(
      (x) => x.id == u.companyId,
      orElse: () => throw Exception('Kullanıcının bağlı olduğu şirket bulunamadı.'),
    );
    if (c.balance < u.salary) {
      throw Exception('${c.name} şirketinin bakiyesi yetersiz (${u.salary.toStringAsFixed(0)} $currency gerekli).');
    }

    c.balance -= u.salary;
    u.balance += u.salary;

    addTxn(
      TxnType.salary,
      u.salary,
      c.id,
      u.id,
      '${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now())} maaş ödemesi',
    );
    _persist();
    notifyListeners();
  }

  /// Tüm vadesi gelen maaşları öder ve sonraki aya ilerletir
  int processDueSalaries() {
    final today = DateTime.now();
    int count = 0;
    for (final u in _users.where(
        (u) => u.role == UserRole.employee && u.companyId != null && u.isActive)) {
      if (!u.salaryDate.isAfter(today)) {
        try {
          final compIndex = _companies.indexWhere((x) => x.id == u.companyId);
          if (compIndex != -1 && _companies[compIndex].balance >= u.salary) {
            _companies[compIndex].balance -= u.salary;
            u.balance += u.salary;
            addTxn(
              TxnType.salary,
              u.salary,
              _companies[compIndex].id,
              u.id,
              '${DateFormat('MMMM yyyy', 'tr_TR').format(today)} otomatik maaş ödemesi',
            );

            // Bir sonraki maaş gününü güvenli hesapla
            int nextYear = today.year;
            int nextMonth = today.month + 1;
            if (nextMonth > 12) {
              nextYear++;
              nextMonth = 1;
            }
            final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            final targetDay = settings.salaryDay.clamp(1, daysInNextMonth);
            u.salaryDate = DateTime(nextYear, nextMonth, targetDay);

            count++;
          }
        } catch (_) {}
      }
    }
    if (count > 0) {
      _persist();
      notifyListeners();
    }
    return count;
  }

  // ---------- Prim ----------
  /// Şirketin tüm aktif çalışanlarına aynı anda aynı tutarda prim dağıtır.
  int giveBonusToCompany(String companyId, double amount, [String? note]) {
    if (amount <= 0) {
      throw Exception('Prim tutarı sıfırdan büyük olmalıdır.');
    }
    final company = _companies.firstWhere(
      (x) => x.id == companyId,
      orElse: () => throw Exception('Şirket bulunamadı.'),
    );
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
          'Şirket bakiyesi yetersiz. ${employees.length} çalışana toplam ${total.toStringAsFixed(2)} $currency gerekli.');
    }

    final desc = note != null && note.trim().isNotEmpty
        ? note.trim()
        : 'Şirket geneli toplu prim';

    for (final u in employees) {
      company.balance -= amount;
      u.balance += amount;
      addTxn(TxnType.bonus, amount, company.id, u.id, desc);
    }
    _persist();
    notifyListeners();
    return employees.length;
  }

  void giveBonus(String userId, double amount, [String? note]) {
    if (amount <= 0) {
      throw Exception('Prim tutarı sıfırdan büyük olmalıdır.');
    }
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    String payerId = 'BANK';
    if (u.companyId != null) {
      final compIdx = _companies.indexWhere((x) => x.id == u.companyId);
      if (compIdx != -1) {
        if (_companies[compIdx].balance < amount) {
          throw Exception('Şirket bakiyesi prim ödemesi için yetersiz.');
        }
        _companies[compIdx].balance -= amount;
        payerId = _companies[compIdx].id;
      }
    }

    u.balance += amount;
    addTxn(
      TxnType.bonus,
      amount,
      payerId,
      u.id,
      note != null && note.trim().isNotEmpty
          ? note.trim()
          : 'Performans primi ödendi',
    );
    _persist();
    notifyListeners();
  }

  void setMonthlyBonus(String userId, double amount) {
    if (amount < 0) {
      throw Exception('Aylık prim negatif olamaz.');
    }
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );
    u.bonus = amount;
    _persist();
    notifyListeners();
  }

  // ---------- Ceza ----------
  void applyPenalty(String userId, double amount, String reason,
      {bool percentage = false}) {
    if (amount <= 0) {
      throw Exception('Ceza tutarı sıfırdan büyük olmalıdır.');
    }
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    double penalty = amount;
    if (percentage) {
      if (amount > 100) {
        throw Exception('Maaş kesintisi yüzde 100\'den fazla olamaz.');
      }
      penalty = u.salary * (amount / 100);
    }

    if (penalty <= 0) {
      throw Exception('Hesaplanan ceza tutarı geçersiz.');
    }
    if (u.balance < penalty) {
      throw Exception(
          'Kullanıcı bakiyesi cezayı karşılamıyor (Mevcut: ${u.balance.toStringAsFixed(2)} $currency, Ceza: ${penalty.toStringAsFixed(2)} $currency).');
    }

    u.balance -= penalty;
    String receiverId = 'BANK';
    if (u.companyId != null) {
      final compIdx = _companies.indexWhere((x) => x.id == u.companyId);
      if (compIdx != -1) {
        _companies[compIdx].balance += penalty;
        receiverId = _companies[compIdx].id;
      }
    }

    final reasonStr = reason.trim().isEmpty ? 'Disiplin cezası' : reason.trim();
    addTxn(
      TxnType.penalty,
      penalty,
      u.id,
      receiverId,
      'Ceza: $reasonStr${percentage ? ' (%${amount.toStringAsFixed(0)} maaş kesintisi)' : ''}',
    );
    _persist();
    notifyListeners();
  }

  // ---------- Terfi ----------
  void promote(String userId, String newTitle, double newSalary,
      [double bonus = 0]) {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('Unvan boş bırakılamaz.');
    }
    if (newSalary < 0) {
      throw Exception('Yeni maaş negatif olamaz.');
    }
    if (bonus < 0) {
      throw Exception('Terfi primi negatif olamaz.');
    }

    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    final oldTitle = u.title;
    final oldSalary = u.salary;

    if (bonus > 0 && u.companyId != null) {
      final compIdx = _companies.indexWhere((x) => x.id == u.companyId);
      if (compIdx != -1) {
        if (_companies[compIdx].balance < bonus) {
          throw Exception('Şirket bakiyesi terfi primi için yetersiz.');
        }
        _companies[compIdx].balance -= bonus;
      }
    }

    u.title = cleanTitle;
    u.salary = newSalary;
    if (bonus > 0) {
      u.balance += bonus;
    }

    addTxn(
      TxnType.promotion,
      bonus,
      u.companyId ?? 'BANK',
      u.id,
      'Terfi: $oldTitle → $cleanTitle (Maaş: ${oldSalary.toStringAsFixed(0)} → ${newSalary.toStringAsFixed(0)} $currency)${bonus > 0 ? ' + ${bonus.toStringAsFixed(0)} $currency terfi primi' : ''}',
    );
    _persist();
    notifyListeners();
  }

  // ---------- Rastgele kredi kesintisi ----------
  double applyRandomDeduction(String userId) {
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    if (u.balance <= 0) return 0.0;

    final double minVal = min(settings.randomDeductionMin, settings.randomDeductionMax);
    final double maxVal = max(settings.randomDeductionMin, settings.randomDeductionMax);
    final double rawAmount = minVal == maxVal
        ? minVal
        : minVal + _rnd.nextDouble() * (maxVal - minVal);

    final double deduction = min<num>(rawAmount, u.balance).toDouble();
    if (deduction > 0) {
      u.balance -= deduction;
      addTxn(TxnType.randomDeduction, deduction, u.id, 'BANK',
          'Aylık rastgele kredi kesintisi');
      _persist();
      notifyListeners();
    }
    return deduction;
  }

  int applyRandomDeductionsToAll() {
    int count = 0;
    for (final u in _users.where((u) => u.role == UserRole.employee && u.isActive && u.balance > 0)) {
      final d = applyRandomDeduction(u.id);
      if (d > 0) count++;
    }
    return count;
  }

  // ---------- Sözleşme / Şirket değiştirme ----------
  void transferEmployee(String userId, String newCompanyId) {
    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    if (u.companyId == newCompanyId) {
      throw Exception('Kullanıcı zaten bu şirkette çalışıyor.');
    }

    final targetComp = _companies.firstWhere(
      (x) => x.id == newCompanyId,
      orElse: () => throw Exception('Hedef şirket bulunamadı.'),
    );

    final now = DateTime.now();
    final oldCompanyId = u.companyId;

    if (u.contractEnd.isAfter(now) && u.terminationFee > 0) {
      final fee = u.terminationFee;
      if (u.balance < fee) {
        throw Exception(
            'Erken fesih ücreti (${fee.toStringAsFixed(2)} $currency) için bakiye yetersiz.');
      }
      u.balance -= fee;

      if (oldCompanyId != null) {
        final oldIdx = _companies.indexWhere((x) => x.id == oldCompanyId);
        if (oldIdx != -1) {
          _companies[oldIdx].balance += fee;
        }
      }

      addTxn(TxnType.terminationFee, fee, u.id, oldCompanyId ?? 'BANK',
          'Sözleşme erken fesih tazminatı ödendi');
    }

    u.companyId = newCompanyId;
    u.contractStart = now;
    u.contractEnd = now.add(const Duration(days: 365));
    u.isActive = true;

    addTxn(TxnType.transfer, 0, oldCompanyId ?? 'BANK', targetComp.id,
        '${u.fullName} adlı çalışan ${targetComp.name} şirketine transfer edildi');
    _persist();
    notifyListeners();
  }

  void renewContract(String userId, int months, double newTerminationFee) {
    if (months <= 0) {
      throw Exception('Sözleşme süresi en az 1 ay olmalıdır.');
    }
    if (newTerminationFee < 0) {
      throw Exception('Fesih ücreti negatif olamaz.');
    }

    final u = _users.firstWhere(
      (x) => x.id == userId,
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );

    final baseDate = u.contractEnd.isAfter(DateTime.now())
        ? u.contractEnd
        : DateTime.now();
    u.contractEnd = baseDate.add(Duration(days: months * 30));
    u.terminationFee = newTerminationFee;

    addTxn(
      TxnType.system,
      0,
      'BANK',
      u.id,
      'Sözleşme $months ay uzatıldı (Yeni Bitiş: ${DateFormat('dd.MM.yyyy').format(u.contractEnd)})',
    );
    _persist();
    notifyListeners();
  }

  // ---------- Transfer (kullanıcıdan kullanıcıya) ----------
  void userTransfer(String fromUserId, String toUserId, double amount,
      String note) {
    if (fromUserId == toUserId) {
      throw Exception('Kendi hesabınıza transfer yapamazsınız.');
    }
    if (amount <= 0 || amount.isNaN || amount.isInfinite) {
      throw Exception('Geçerli bir transfer tutarı girin.');
    }

    final from = _users.firstWhere(
      (x) => x.id == fromUserId,
      orElse: () => throw Exception('Gönderen kullanıcı bulunamadı.'),
    );
    final to = _users.firstWhere(
      (x) => x.id == toUserId,
      orElse: () => throw Exception('Alıcı kullanıcı bulunamadı.'),
    );

    if (!from.isActive) {
      throw Exception('Hesabınız aktif değil.');
    }
    if (!to.isActive) {
      throw Exception('Alıcı hesap aktif değil.');
    }
    if (from.balance < amount) {
      throw Exception(
          'Yetersiz bakiye (Mevcut: ${from.balance.toStringAsFixed(2)} $currency).');
    }

    from.balance -= amount;
    to.balance += amount;

    final cleanNote = note.trim().isEmpty
        ? '${from.fullName} → ${to.fullName} para transferi'
        : note.trim();

    addTxn(TxnType.transfer, amount, fromUserId, toUserId, cleanNote);
    _persist();
    notifyListeners();
  }

  // ---------- Ayarlar ----------
  void updateSettings(BankSettings s) {
    if (s.bankName.trim().isEmpty) {
      throw Exception('Banka adı boş olamaz.');
    }
    if (s.currency.trim().isEmpty) {
      throw Exception('Para birimi boş olamaz.');
    }
    if (s.randomDeductionMin < 0 || s.randomDeductionMax < 0) {
      throw Exception('Kesinti tutarları negatif olamaz.');
    }
    if (s.randomDeductionMin > s.randomDeductionMax) {
      throw Exception('Minimum kesinti maksimum kesintiden büyük olamaz.');
    }
    if (s.salaryDay < 1 || s.salaryDay > 31) {
      throw Exception('Maaş günü 1 ile 31 arasında olmalıdır.');
    }

    settings = s;
    addTxn(TxnType.system, 0, 'BANK', 'BANK', 'Banka ayarları güncellendi');
    _persist();
    notifyListeners();
  }

  // ---------- Sorgular ----------
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
    final matches = _companies.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  AppUser? userById(String id) {
    final matches = _users.where((u) => u.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  double get totalCompanyBalance =>
      _companies.fold(0.0, (sum, c) => sum + c.balance);
  double get totalUserBalance =>
      _users.fold(0.0, (sum, u) => sum + u.balance);
  double get totalMonthlySalaries => _users
      .where((u) => u.role == UserRole.employee && u.isActive)
      .fold(0.0, (sum, u) => sum + u.salary);

  void resetAll() {
    _users.clear();
    _companies.clear();
    _transactions.clear();
    settings = BankSettings();
    currentUser = null;
    _storage.clearAll();
    _seed();
    notifyListeners();
  }
}
