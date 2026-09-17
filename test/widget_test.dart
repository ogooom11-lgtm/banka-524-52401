import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bank/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('BankApp renders admin-only login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    expect(find.text('Dijital Banka & Maaş Yönetimi'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('YALNIZCA YÖNETİCİ GİRİŞİ'), findsOneWidget);
    expect(find.text('Çalışan'), findsNothing);
  });

  testWidgets('employee credentials are rejected on login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'ahmet@techcorp.com');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Bu panele yalnızca yönetici giriş yapabilir.'),
        findsOneWidget);
    expect(find.text('SÜPER ADMIN'), findsNothing);
  });

  testWidgets('admin login opens dashboard and users tab has search boxes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('SÜPER ADMIN'), findsOneWidget);

    // NavigationRail (wide) or NavigationBar (narrow) — tap Users.
    final usersNav = find.text('Kullanıcılar');
    expect(usersNav, findsWidgets);
    await tester.tap(usersNav.first);
    await tester.pumpAndSettle();

    expect(find.text('Ada göre ara'), findsOneWidget);
    expect(find.text('Şirkete göre ara'), findsOneWidget);
    expect(find.text('Unvana göre ara'), findsOneWidget);
    expect(find.text('TXT ile Kullanıcı Ekle'), findsOneWidget);
    expect(find.text('Toplu Prim Dağıt'), findsOneWidget);
    expect(find.text('Yeni Kullanıcı'), findsOneWidget);
  });

  testWidgets('admin can edit user name in users tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    final usersNav = find.text('Kullanıcılar');
    await tester.tap(usersNav.first);
    await tester.pumpAndSettle();

    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    final editIcon = find.byTooltip('İsmi Düzenle');
    expect(editIcon, findsWidgets);

    await tester.tap(editIcon.first);
    await tester.pumpAndSettle();

    expect(find.text('İsmi Düzenle'), findsOneWidget);
    final nameField = find.widgetWithText(TextField, 'Ahmet Yılmaz');
    await tester.enterText(nameField, 'Ahmet Demir');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmet Demir'), findsOneWidget);
  });
}
