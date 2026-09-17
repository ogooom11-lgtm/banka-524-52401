import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/bank_provider.dart';
import 'screens/login_screen.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/employee_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (_) {}
  runApp(const BankApp());
}

class BankApp extends StatelessWidget {
  const BankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BankProvider()..init(),
      child: MaterialApp(
        title: 'Dijital Banka Simülasyonu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          cardTheme: const CardThemeData(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BankProvider>(
      builder: (context, bank, _) {
        if (!bank.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (bank.currentUser == null) return const LoginScreen();
        switch (bank.currentUser!.role) {
          case UserRole.superAdmin:
            return const SuperAdminDashboard();
          case UserRole.companyAdmin:
          case UserRole.employee:
            return const EmployeeDashboard();
        }
      },
    );
  }
}
