import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bank/providers/bank_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BankProvider bank;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    bank = BankProvider();
    await bank.init();
  });

  test('yalnızca yönetici giriş yapabilir', () {
    expect(bank.login('admin@bank.com', 'admin123'), isNull);
    expect(bank.currentUser?.role, UserRole.superAdmin);

    bank.logout();
    expect(
      bank.login('ahmet@techcorp.com', '123456'),
      'Bu panele yalnızca yönetici giriş yapabilir.',
    );
    expect(bank.currentUser, isNull);

    expect(bank.login('yok@bank.com', 'x'), 'E-posta veya şifre hatalı.');
  });

  test('kullanıcı e-posta ve şifre olmadan eklenir', () {
    final before = bank.users.length;
    bank.addUser(
      fullName: 'Zeynep Kaya',
      role: UserRole.employee,
      companyId: 'comp-001',
      salary: 30000,
      terminationFee: 60000,
    );
    expect(bank.users.length, before + 1);
    final added = bank.users.last;
    expect(added.fullName, 'Zeynep Kaya');
    expect(added.email.contains('@'), isTrue);
    expect(added.title, 'Çalışan');
  });

  test('maaş şirket sınırını aşamaz', () {
    expect(
      () => bank.addUser(
        fullName: 'Fazla Maaşlı',
        role: UserRole.employee,
        companyId: 'comp-001',
        salary: 999999,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('TXT isimlerinden kullanıcı ekler: maaş sınırı, 1-5 yıl, 2-3x fesih', () {
    final result = bank.importUsersFromNames(
      names: const ['Ali Veli', 'Ayşe Demir', '', 'Ali Veli'],
      companyId: 'comp-001',
    );
    expect(result.added, 2);

    final imported = bank.users
        .where((u) => u.fullName == 'Ali Veli' || u.fullName == 'Ayşe Demir')
        .toList();
    expect(imported.length, 2);

    final company = bank.companyById('comp-001')!;
    final now = DateTime.now();
    for (final u in imported) {
      expect(u.salary, lessThanOrEqualTo(company.salaryLimit));
      expect(u.salary, greaterThan(0));
      final years = u.contractEnd.difference(now).inDays / 365;
      expect(years, inInclusiveRange(0.9, 5.1));
      final ratio = u.terminationFee / u.salary;
      expect(ratio, anyOf(closeTo(2, 0.01), closeTo(3, 0.01)));
    }
  });

  test('şirketin tüm çalışanlarına aynı anda prim dağıtır', () {
    final company = bank.companyById('comp-001')!;
    final employees = bank
        .usersOfCompany(company.id)
        .where((u) => u.isActive && u.role != UserRole.superAdmin)
        .toList();
    expect(employees, isNotEmpty);

    final beforeBalances = {
      for (final u in employees) u.id: u.balance,
    };
    final beforeCompany = company.balance;
    const amount = 1500.0;

    final n = bank.giveBonusToCompany(company.id, amount, 'Toplu prim test');
    expect(n, employees.length);
    expect(company.balance, closeTo(beforeCompany - amount * n, 0.01));
    for (final u in employees) {
      expect(u.balance, closeTo(beforeBalances[u.id]! + amount, 0.01));
    }
  });

  test('şirket maaş sınırı güncellenir', () {
    bank.updateCompany(id: 'comp-001', salaryLimit: 75000);
    expect(bank.companyById('comp-001')!.salaryLimit, 75000);
  });

  test('kullanıcı adı güncellenir', () {
    final emp = bank.users.firstWhere((u) => u.role == UserRole.employee);
    bank.updateUserName(emp.id, 'Mehmet Demir');
    expect(bank.userById(emp.id)?.fullName, 'Mehmet Demir');

    expect(
      () => bank.updateUserName(emp.id, '   '),
      throwsA(isA<Exception>()),
    );
  });
}
