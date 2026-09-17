import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/bank_provider.dart';
import 'screens/employee_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/super_admin_dashboard.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_widgets.dart';

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
      child: Consumer<BankProvider>(
        builder: (context, bank, _) {
          final preset = accentById(bank.accentId);
          final density = UiDensity.fromId(bank.densityId);
          return MaterialApp(
            title: '${bank.bankName} • Dijital Banka ve Maaş Yönetimi',
            debugShowCheckedModeBanner: false,
            themeMode: bank.themeMode,
            theme: AppTheme.build(
              dark: false,
              preset: preset,
              density: density,
            ),
            darkTheme: AppTheme.build(
              dark: true,
              preset: preset,
              density: density,
            ),
            scrollBehavior: const _DesktopScrollBehavior(),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Masaüstünde fare tekerleği + sürükleme ile kaydırma.
class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

/// Oturum durumuna göre doğru ekranı gösteren kapı.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BankProvider>(
      builder: (context, bank, _) {
        if (!bank.initialized) return const SplashScreen();

        Widget child;
        if (bank.currentUser == null) {
          child = const LoginScreen();
        } else if (bank.currentUser!.role == UserRole.superAdmin) {
          child = const SuperAdminDashboard();
        } else {
          child = const EmployeeDashboard();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey<String>(
              bank.currentUser == null
                  ? 'login'
                  : '${bank.currentUser!.role.name}-${bank.currentUser!.id}',
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Açılış ekranı — animasyonlu logo ve yükleme göstergesi.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: GradientBackdrop(
        colors: [
          scheme.surface,
          scheme.primary.withValues(alpha: 0.22),
          scheme.surface,
        ],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.9),
                        scheme.secondary.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Text('🏦', style: TextStyle(fontSize: 46)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dijital Banka',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Veriler yükleniyor...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1600),
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
