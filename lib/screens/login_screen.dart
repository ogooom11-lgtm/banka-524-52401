import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bank_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/common.dart';
import 'help_screen.dart';

/// Giriş ekranı — yönetici veya çalışan portalı.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@bank.com');
  final _passCtrl = TextEditingController(text: 'admin123');
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _adminMode = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _fillDemo({required bool admin}) {
    setState(() {
      _adminMode = admin;
      _emailCtrl.text = admin ? 'admin@bank.com' : 'ahmet@techcorp.com';
      _passCtrl.text = admin ? 'admin123' : '123456';
      _error = null;
    });
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Lütfen e-posta ve şifrenizi girin.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    // Küçük bir gecikme animasyonun görünmesini sağlar (kullanıcı geri bildirimi).
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    final bank = context.read<BankProvider>();
    final err = _adminMode ? bank.login(email, pass) : bank.loginUser(email, pass);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) {
      showSnackBar(context, 'Hoş geldiniz, ${bank.currentUser?.fullName ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final preset = accentById(bank.accentId);
    final wide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      body: GradientBackdrop(
        animated: bank.animationsEnabled,
        colors: [
          scheme.surface,
          preset.gradient.first.withValues(alpha: 0.18),
          scheme.surface,
        ],
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: 16,
                top: 12,
                child: Row(
                  children: [
                    IconAction(
                      icon: scheme.brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      tooltip: 'Tema değiştir',
                      onPressed: () => bank.setThemeMode(
                        scheme.brightness == Brightness.dark ? 'light' : 'dark',
                      ),
                    ),
                    IconAction(
                      icon: Icons.help_outline,
                      tooltip: 'Uygulama nasıl çalışır?',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(standalone: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(flex: 5, child: _BrandPanel()),
                              const SizedBox(width: 40),
                              Expanded(flex: 4, child: _buildCard(bank)),
                            ],
                          )
                        : Column(
                            children: [
                              const _BrandPanel(compact: true),
                              const SizedBox(height: 26),
                              _buildCard(bank),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BankProvider bank) {
    final scheme = Theme.of(context).colorScheme;
    return FadeSlideIn(
      offsetY: 26,
      child: AppCard(
        padding: const EdgeInsets.all(26),
        radius: 26,
        blurGlow: true,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.login_rounded,
                        color: scheme.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oturum Aç',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          bank.bankName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PillBadge(
                    label: _adminMode
                        ? 'YALNIZCA YÖNETİCİ GİRİŞİ'
                        : 'ÇALIŞAN PORTALI',
                    icon: _adminMode
                        ? Icons.workspace_premium_outlined
                        : Icons.badge_outlined,
                    color: _adminMode ? Colors.amber.shade700 : scheme.secondary,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Yönetici'),
                    icon: Icon(Icons.workspace_premium_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Personel'),
                    icon: Icon(Icons.person_outline, size: 16),
                  ),
                ],
                selected: {_adminMode},
                onSelectionChanged: (v) => setState(() {
                  _adminMode = v.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 18, color: scheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                      color: scheme.onErrorContainer,
                                      fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _login,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded, size: 19),
                  label: Text(_busy ? 'Giriş yapılıyor...' : 'Giriş Yap'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Demo hesaplar:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Yönetici'),
                    avatar: const Icon(Icons.workspace_premium_outlined, size: 14),
                    onPressed: () => _fillDemo(admin: true),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('Personel'),
                    avatar: const Icon(Icons.person_outline, size: 14),
                    onPressed: () => _fillDemo(admin: false),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tüm veriler bu bilgisayarda yerel olarak saklanır. '
                      'Verilerinizi Ayarlar > Veri Yönetimi bölümünden yedekleyebilirsiniz.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.outline,
                            height: 1.45,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nasıl çalışır?',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpScreen(standalone: true),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sol taraftaki tanıtım paneli.
class _BrandPanel extends StatelessWidget {
  final bool compact;

  const _BrandPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final preset = accentById(bank.accentId);

    final features = <(IconData, String, String)>[
      (
        Icons.business_center_outlined,
        'Şirket & personel yönetimi',
        'Şirket oluştur, maaş sınırı belirle, personeli tek tıkla ekle.'
      ),
      (
        Icons.payments_outlined,
        'Otomatik maaş ödemesi',
        'Vadesi gelen maaşlar arka planda kendiliğinden ödenir.'
      ),
      (
        Icons.card_giftcard,
        'Prim, ceza, terfi, kredi',
        'Tüm finansal işlemler tek panelden, detaylı geçmişle birlikte.'
      ),
      (
        Icons.tune,
        'Tam özelleştirme',
        'Banka adı, para birimi, tema, kurallar ve modüller size bağlı.'
      ),
    ];

    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: preset.gradient),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: preset.seed.withValues(alpha: 0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  bank.logoEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (!compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.bankName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                  ),
                  Text(
                    bank.settings.slogan,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Dijital Banka & Maaş Yönetimi',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.8,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Şirketlerin çalışanlarına otomatik maaş ödediği, prim–ceza–terfi ve '
          'sözleşme kurallarının sizin belirlediğiniz şekilde işlediği, '
          'tamamen özelleştirilebilir bir banka simülasyonu.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 22),
        StaggeredColumn(
          spacing: 12,
          children: [
            for (final f in features)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: preset.seed.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.$1, size: 17, color: preset.seed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Text(
                          f.$3,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          children: [
            PillBadge(
              label: '${bank.companies.length} şirket',
              icon: Icons.business_outlined,
            ),
            PillBadge(
              label: '${bank.users.length} kullanıcı',
              icon: Icons.people_outline,
              color: preset.secondary,
            ),
            PillBadge(
              label: '${bank.transactions.length} işlem kaydı',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
      ],
    );
  }
}
