import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/bank_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/common.dart';
import 'dialogs/company_dialogs.dart';
import 'dialogs/import_export_dialogs.dart';
import 'dialogs/user_dialogs.dart';
import 'tabs/companies_tab.dart';
import 'tabs/help_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/payroll_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/users_tab.dart';

/// Yönetici kabuğu: kenar menü, üst araç çubuğu, kısayollar ve durum çubuğu.
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _index = 0;
  bool _sidebarCollapsed = false;
  BankProvider? _bankRef;
  final _usersKey = GlobalKey<UsersTabState>();
  final _userSearchFocus = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _bankRef = context.read<BankProvider>();
    // Zamanlayıcı ilk kareden sonra başlatılır: tick() durum değiştirip
    // notifyListeners() çağırdığı için build sırasında tetiklenmemelidir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bankRef?.startScheduler();
      _bankRef?.checkContractAlerts();
    });
  }

  @override
  void dispose() {
    _bankRef?.stopScheduler();
    _userSearchFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ Sekmeler
  List<_NavItem> _items(BankProvider bank) => [
        _NavItem(
          'overview',
          'Genel Bakış',
          Icons.dashboard_outlined,
          Icons.dashboard,
          OverviewTab(onNavigate: _goTo),
          enabled: true,
        ),
        _NavItem(
          'companies',
          'Şirketler',
          Icons.business_outlined,
          Icons.business,
          const CompaniesTab(),
          enabled: bank.settings.moduleEnabled('companies'),
        ),
        _NavItem(
          'users',
          'Kullanıcılar',
          Icons.people_outline,
          Icons.people,
          UsersTab(key: _usersKey),
          enabled: bank.settings.moduleEnabled('users'),
        ),
        _NavItem(
          'payroll',
          'Maaş Merkezi',
          Icons.payments_outlined,
          Icons.payments,
          PayrollTab(onNavigate: _goTo),
          enabled: bank.settings.moduleEnabled('payroll'),
        ),
        _NavItem(
          'transactions',
          'İşlemler',
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          const TransactionsTab(),
          enabled: bank.settings.moduleEnabled('transactions'),
        ),
        _NavItem(
          'reports',
          'Raporlar',
          Icons.insights_outlined,
          Icons.insights,
          const ReportsTab(),
          enabled: bank.settings.moduleEnabled('reports'),
        ),
        _NavItem(
          'help',
          'Nasıl Çalışır?',
          Icons.help_outline,
          Icons.help,
          const HelpTab(),
          enabled: bank.settings.moduleEnabled('help'),
        ),
        _NavItem(
          'settings',
          'Ayarlar',
          Icons.settings_outlined,
          Icons.settings,
          SettingsTab(onNavigate: _goTo),
          enabled: true,
        ),
      ];

  void _select(int index) {
    final items = _items(context.read<BankProvider>());
    if (index < 0 || index >= items.length) return;
    setState(() => _index = index);
  }

  /// Sayfa anahtarına göre gezinme (sekmeler arası bağlantılar için).
  void _goTo(String route) {
    final items = _items(context.read<BankProvider>());
    final i = items.indexWhere((item) => item.route == route);
    if (i >= 0) _select(i);
  }

  // ----------------------------------------------------------- Kısayollar
  void _openPalette(BankProvider bank) {
    showAppDialog<void>(
      context,
      title: 'Komut Paleti',
      subtitle: 'Ctrl + K ile her yerden açılır. İşlem seçin veya kullanıcı arayın.',
      icon: Icons.terminal,
      maxWidth: 640,
      scrollable: false,
      child: _CommandPalette(
        bank: bank,
        onNavigate: _goTo,
        onRun: (action) => _runCommand(bank, action),
        onOpenUser: (user) => showUserEditor(context, user: user),
      ),
    );
  }

  void _runCommand(BankProvider bank, String action) {
    switch (action) {
      case 'newUser':
        showUserEditor(context);
        break;
      case 'newCompany':
        showCompanyEditor(context);
        break;
      case 'import':
        showImportDialog(context);
        break;
      case 'payroll':
        final n = bank.processDueSalaries();
        showSnackBar(
          context,
          n > 0 ? '$n çalışana maaş ödendi.' : 'Vadesi gelen maaş yok.',
          success: n > 0,
        );
        break;
      case 'bonus':
        final n = bank.payMonthlyBonuses();
        showSnackBar(
          context,
          n > 0 ? '$n çalışana aylık prim ödendi.' : 'Ödenecek prim yok.',
          success: n > 0,
        );
        break;
      case 'backup':
        showDataManagementDialog(context);
        break;
      case 'audit':
        showAuditLogDialog(context);
        break;
      case 'notifications':
        showNotificationsDialog(context);
        break;
      case 'undo':
        if (bank.canUndo) {
          bank.undo();
          showSnackBar(context, 'Son işlem geri alındı.');
        } else {
          showSnackBar(context, 'Geri alınacak işlem yok.', success: false);
        }
        break;
      case 'theme':
        bank.setThemeMode(
          Theme.of(context).brightness == Brightness.dark ? 'light' : 'dark',
        );
        break;
      case 'renewContracts':
        final n = bank.renewExpiredContracts();
        showSnackBar(
          context,
          n > 0 ? '$n sözleşme otomatik uzatıldı.' : 'Süresi dolmuş sözleşme yok.',
          success: n > 0,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final items = _items(bank);
    final safeIndex = _index.clamp(0, items.length - 1);
    final width = MediaQuery.of(context).size.width;
    final showSidebar = width >= 760;

    final body = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _openPalette(bank),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _select(2);
          _usersKey.currentState?.focusSearch();
        },
        const SingleActivator(LogicalKeyboardKey.f1): () => _select(6),
        const SingleActivator(LogicalKeyboardKey.f2): () => _select(3),
        const SingleActivator(LogicalKeyboardKey.f5): () =>
            _runCommand(bank, 'payroll'),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            _runCommand(bank, 'undo'),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _runCommand(bank, 'backup'),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _runCommand(bank, 'newUser'),
        const SingleActivator(LogicalKeyboardKey.keyL,
            control: true, shift: true): () => _runCommand(bank, 'theme'),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: showSidebar ? null : Drawer(child: _sidebar(bank, items, safeIndex, true)),
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showSidebar)
                      _sidebar(bank, items, safeIndex, false),
                    Expanded(
                      child: Column(
                        children: [
                          _topBar(bank, items[safeIndex].label),
                          Expanded(
                            child: AnimatedTabView(
                              index: safeIndex,
                              children: [
                                for (final item in items) item.child,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _statusBar(bank, scheme),
            ],
          ),
        ),
      ),
    );

    return bank.gradientBackground
        ? GradientBackdrop(
            animated: bank.animationsEnabled,
            colors: [
              scheme.surface,
              scheme.primary.withValues(alpha: 0.07),
              scheme.surface,
            ],
            child: body,
          )
        : body;
  }

  // ------------------------------------------------------------- Sidebar
  Widget _sidebar(
    BankProvider bank,
    List<_NavItem> items,
    int safeIndex,
    bool asDrawer,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final collapsed = _sidebarCollapsed && !asDrawer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: asDrawer ? 268 : (collapsed ? 84 : 256),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.030)
            : Colors.white.withValues(alpha: 0.72),
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: accentById(bank.accentId).gradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentById(bank.accentId)
                            .seed
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(bank.logoEmoji,
                      style: const TextStyle(fontSize: 19)),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.bankName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const PillBadge(
                          label: 'SÜPER ADMIN',
                          color: Colors.amber,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
                if (!asDrawer)
                  IconButton(
                    tooltip: collapsed ? 'Menüyü genişlet' : 'Menüyü daralt',
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_double_arrow_right
                          : Icons.keyboard_double_arrow_left,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                for (var i = 0; i < items.length; i++)
                  if (items[i].enabled)
                    _navTile(
                      item: items[i],
                      index: i,
                      selected: i == safeIndex,
                      collapsed: collapsed,
                      onTap: () {
                        if (asDrawer) Navigator.of(context).maybePop();
                        _select(i);
                      },
                    )
                  else if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(
                        '${items[i].label} (kapalı)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.outline,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (!collapsed) ...[
                  Row(
                    children: [
                      AvatarBubble(
                        name: bank.currentUser?.fullName ?? 'Yönetici',
                        colorValue: bank.currentUser?.avatarColor ?? 0,
                        radius: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.currentUser?.fullName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                            Text(
                              bank.currentUser?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10.5, color: scheme.outline),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kendi adınızı düzenle',
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () async {
                          final user = bank.currentUser;
                          if (user == null) return;
                          final name = await showTextPromptDialog(
                            context,
                            title: 'Adınızı Düzenle',
                            label: 'Ad Soyad',
                            initial: user.fullName,
                          );
                          if (name == null || !mounted) return;
                          bank.updateUserName(user.id, name);
                          showSnackBar(context, 'İsminiz güncellendi.');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconAction(
                      icon: Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      tooltip: 'Tema değiştir (Ctrl+Shift+L)',
                      onPressed: () => _runCommand(bank, 'theme'),
                    ),
                    IconAction(
                      icon: Icons.notifications_none,
                      tooltip: 'Bildirimler',
                      badgeCount: bank.unreadNotificationCount,
                      onPressed: () => showNotificationsDialog(context),
                    ),
                    IconAction(
                      icon: Icons.logout,
                      tooltip: 'Çıkış yap',
                      onPressed: () {
                        showConfirmDialog(
                          context,
                          title: 'Oturumu kapat',
                          message:
                              'Çıkış yapmak istediğinize emin misiniz? Verileriniz kaydedildi.',
                          icon: Icons.logout,
                          onConfirm: bank.logout,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile({
    required _NavItem item,
    required int index,
    required bool selected,
    required bool collapsed,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: collapsed ? item.label : '',
        waitDuration: const Duration(milliseconds: 400),
        child: HoverLift(
          scale: 1.0,
          lift: 0,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.22),
                        scheme.secondary.withValues(alpha: 0.10),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 19,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            selected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (item.badge != null && item.badge! > 0)
                    PillBadge(
                        label: '${item.badge}', color: scheme.error, dense: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Top bar
  Widget _topBar(BankProvider bank, String title) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final showSearch = width >= 900;
    final compactBar = width < 760;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (width < 760)
            IconButton(
              tooltip: 'Menü',
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          if (bank.canUndo)
            PillBadge(
              label: 'geri alınabilir: ${bank.lastUndoLabel ?? ''}',
              icon: Icons.undo_rounded,
              color: const Color(0xFFF59E0B),
              dense: true,
              onTap: () => _runCommand(bank, 'undo'),
            ),
          const Spacer(),
          if (showSearch)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openPalette(bank),
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        size: 17, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ara / komut paleti',
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.outline),
                      ),
                    ),
                    Text(
                      'Ctrl+K',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Komut paleti (Ctrl + K)',
            child: compactBar
                ? IconButton.filledTonal(
                    onPressed: () => _openPalette(bank),
                    icon: const Icon(Icons.bolt_outlined, size: 18),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () => _openPalette(bank),
                    icon: const Icon(Icons.bolt_outlined, size: 17),
                    label: const Text('Hızlı İşlem'),
                  ),
          ),
          const SizedBox(width: 8),
          IconAction(
            icon: Icons.payments_outlined,
            tooltip: 'Vadesi gelen maaşları öde (F5)',
            onPressed: () => _runCommand(bank, 'payroll'),
          ),
          IconAction(
            icon: Icons.person_add_alt_1,
            tooltip: 'Yeni kullanıcı (Ctrl + N)',
            onPressed: () => _runCommand(bank, 'newUser'),
          ),
          IconAction(
            icon: Icons.storage_outlined,
            tooltip: 'Yedekleme (Ctrl + B)',
            onPressed: () => _runCommand(bank, 'backup'),
          ),
          IconAction(
            icon: Icons.notifications_none,
            tooltip: 'Bildirimler',
            badgeCount: bank.unreadNotificationCount,
            onPressed: () => showNotificationsDialog(context),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Status bar
  Widget _statusBar(BankProvider bank, ColorScheme scheme) {
    final riskCount = bank.riskyContracts.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          return Row(
            children: [
              const PulseDot(),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${bank.transactions.length} işlem • ${bank.users.length} kullanıcı • '
                  '${bank.companies.length} şirket',
                  overflow: TextOverflow.ellipsis,
                  style: TextView(scheme),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                if (riskCount > 0) ...[
                  const Icon(Icons.gpp_maybe_outlined,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 5),
                  Text('$riskCount sözleşme riski',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFEF4444))),
                ] else ...[
                  const Icon(Icons.verified_outlined,
                      size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 5),
                  Text('riskli sözleşme yok', style: TextView(scheme)),
                ],
              ],
              const Spacer(),
              if (!compact) ...[
                Text(
                  'Vadesi gelen maaş: ${bank.payableEmployees.where((u) => !u.salaryDate.isAfter(DateTime.now())).length}',
                  style: TextView(scheme),
                ),
                const SizedBox(width: 16),
              ],
              Icon(Icons.schedule, size: 13, color: scheme.outline),
              const SizedBox(width: 5),
              Text(Fmt.clock(DateTime.now()), style: TextView(scheme)),
            ],
          );
        },
      ),
    );
  }
}

/// Durum çubuğu metin stili.
TextStyle TextView(ColorScheme scheme) => TextStyle(
      fontSize: 11,
      color: scheme.onSurfaceVariant,
    );

/// Menü öğesi tanımı.
class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget child;
  final bool enabled;
  final int? badge;

  const _NavItem(
    this.route,
    this.label,
    this.icon,
    this.activeIcon,
    this.child, {
    this.enabled = true,
    this.badge,
  });
}

/// Komut paleti içeriği — arama + hızlı işlemler + kullanıcı/kayıt arama.
class _CommandPalette extends StatefulWidget {
  final BankProvider bank;
  final void Function(String route) onNavigate;
  final void Function(String action) onRun;
  final void Function(AppUser user) onOpenUser;

  const _CommandPalette({
    required this.bank,
    required this.onNavigate,
    required this.onRun,
    required this.onOpenUser,
  });

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    final commands = <(String, String, IconData, VoidCallback)>[
      (
        'Yeni kullanıcı ekle',
        'Personel kaydı oluştur',
        Icons.person_add_alt_1,
        () {
          Navigator.pop(context);
          widget.onRun('newUser');
        }
      ),
      (
        'Yeni şirket oluştur',
        'Bakiye ve maaş sınırı ile şirket aç',
        Icons.add_business_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('newCompany');
        }
      ),
      (
        'TXT / CSV içe aktar',
        'Toplu kullanıcı yükleme sihirbazı',
        Icons.upload_file_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('import');
        }
      ),
      (
        'Vadesi gelen maaşları öde',
        'F5 • Tüm hazır maaşları tek seferde öde',
        Icons.payments_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('payroll');
        }
      ),
      (
        'Aylık primleri öde',
        'Tanımlı primleri çalışanlara aktar',
        Icons.card_giftcard,
        () {
          Navigator.pop(context);
          widget.onRun('bonus');
        }
      ),
      (
        'Yedek al / geri yükle',
        'Ctrl + B • JSON yedekleme merkezi',
        Icons.storage_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('backup');
        }
      ),
      (
        'Sistem günlüğü',
        'Kim ne yaptı?',
        Icons.history_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('audit');
        }
      ),
      (
        'Bildirimler',
        'Son olaylar ve uyarılar',
        Icons.notifications_none,
        () {
          Navigator.pop(context);
          widget.onRun('notifications');
        }
      ),
      (
        'Son işlemi geri al',
        'Ctrl + Z',
        Icons.undo_rounded,
        () {
          Navigator.pop(context);
          widget.onRun('undo');
        }
      ),
      (
        'Süresi dolan sözleşmeleri yenile',
        'Otomatik uzatma',
        Icons.event_repeat_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('renewContracts');
        }
      ),
      (
        'Tema değiştir',
        'Ctrl + Shift + L',
        Icons.palette_outlined,
        () {
          Navigator.pop(context);
          widget.onRun('theme');
        }
      ),
    ];

    final filteredCommands = commands
        .where((c) =>
            _query.isEmpty ||
            c.$1.toLowerCase().contains(_query) ||
            c.$2.toLowerCase().contains(_query))
        .toList();

    final users = _query.isEmpty
        ? <AppUser>[]
        : bank.users
            .where((u) =>
                u.fullName.toLowerCase().contains(_query) ||
                u.email.toLowerCase().contains(_query))
            .take(6)
            .toList();

    final companies = _query.isEmpty
        ? <Company>[]
        : bank.companies
            .where((c) => c.name.toLowerCase().contains(_query))
            .take(4)
            .toList();

    final navItems = <(String, IconData, String)>[
      ('Genel Bakış', Icons.dashboard_outlined, 'overview'),
      ('Şirketler', Icons.business_outlined, 'companies'),
      ('Kullanıcılar', Icons.people_outline, 'users'),
      ('Maaş Merkezi', Icons.payments_outlined, 'payroll'),
      ('İşlemler', Icons.receipt_long_outlined, 'transactions'),
      ('Raporlar', Icons.insights_outlined, 'reports'),
      ('Nasıl Çalışır?', Icons.help_outline, 'help'),
      ('Ayarlar', Icons.settings_outlined, 'settings'),
    ]
        .where((n) =>
            _query.isEmpty || n.$1.toLowerCase().contains(_query))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'İşlem, kullanıcı, şirket veya sayfa ara...',
              prefixIcon: Icon(Icons.search, size: 19),
            ),
          ),
          const SizedBox(height: 14),
          if (navItems.isNotEmpty) ...[
            _sectionLabel(context, 'Sayfalar'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in navItems)
                  ActionChip(
                    avatar: Icon(n.$2, size: 15),
                    label: Text(n.$1),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNavigate(n.$3);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (filteredCommands.isNotEmpty) ...[
            _sectionLabel(context, 'İşlemler'),
            for (final c in filteredCommands)
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Icon(c.$3, size: 18),
                title: Text(c.$1),
                subtitle: Text(c.$2),
                onTap: c.$4,
              ),
            const SizedBox(height: 10),
          ],
          if (users.isNotEmpty) ...[
            _sectionLabel(context, 'Kullanıcılar'),
            for (final u in users)
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: AvatarBubble(
                    name: u.fullName, colorValue: u.avatarColor, radius: 14),
                title: Text(u.fullName),
                subtitle: Text('${u.title} • ${u.email}'),
                trailing: Text(bank.money(u.balance),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenUser(u);
                },
              ),
            const SizedBox(height: 10),
          ],
          if (companies.isNotEmpty) ...[
            _sectionLabel(context, 'Şirketler'),
            for (final c in companies)
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.business_outlined, size: 18),
                title: Text(c.name),
                subtitle: Text(bank.money(c.balance)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigate('companies');
                },
              ),
          ],
          if (filteredCommands.isEmpty &&
              users.isEmpty &&
              companies.isEmpty &&
              navItems.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Sonuç yok',
              message: 'Farklı bir kelime deneyin veya Esc ile kapatın.',
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
