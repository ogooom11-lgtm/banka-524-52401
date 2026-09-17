import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/bank_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'tabs/help_tab.dart';

/// Çalışan portalı: bakiye, transfer, işlem geçmişi, krediler ve profil.
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _index = 0;
  bool _sidebarCollapsed = false;

  final _recipientQuery = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _txnQuery = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _recipientId;
  int _flow = 0; // 0 tümü, 1 gelen, 2 giden
  int _visibleTxns = 25;

  @override
  void dispose() {
    _recipientQuery.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _txnQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final user = bank.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = <_PortalSection>[
      _PortalSection('Genel Bakış', Icons.dashboard_outlined, Icons.dashboard,
          _overview(bank, user)),
      _PortalSection('Para Transferi', Icons.swap_horiz_outlined,
          Icons.swap_horiz, _transfer(bank, user)),
      _PortalSection('İşlemlerim', Icons.receipt_long_outlined,
          Icons.receipt_long, _transactions(bank, user)),
      _PortalSection('Kredilerim', Icons.request_quote_outlined,
          Icons.request_quote, _loans(bank, user)),
      _PortalSection(
          'Profil', Icons.person_outline, Icons.person, _profile(bank, user)),
      const _PortalSection('Nasıl Çalışır?', Icons.help_outline, Icons.help,
          HelpTab()),
    ];
    final safeIndex = _index.clamp(0, items.length - 1);
    final showSidebar = MediaQuery.of(context).size.width >= 900;

    final body = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () =>
            setState(() => _index = 5),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            setState(() => _index = 2),
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            setState(() => _index = 1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: showSidebar
              ? null
              : Drawer(child: _sidebar(bank, user, items, safeIndex, true)),
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showSidebar)
                      _sidebar(bank, user, items, safeIndex, false),
                    Expanded(
                      child: Column(
                        children: [
                          _topBar(bank, user, items[safeIndex].label),
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
              _statusBar(bank, user),
            ],
          ),
        ),
      ),
    );

    final scheme = Theme.of(context).colorScheme;
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

  // -------------------------------------------------------------- Sidebar
  Widget _sidebar(
    BankProvider bank,
    AppUser user,
    List<_PortalSection> items,
    int safeIndex,
    bool asDrawer,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final collapsed = _sidebarCollapsed && !asDrawer;
    final company = bank.companyById(user.companyId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: asDrawer ? 268 : (collapsed ? 84 : 250),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.030)
            : Colors.white.withValues(alpha: 0.72),
        border: Border(
          right:
              BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
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
                    gradient:
                        LinearGradient(colors: accentById(bank.accentId).gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Text(bank.logoEmoji, style: const TextStyle(fontSize: 19)),
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
                            label: 'ÇALIŞAN PORTALI',
                            color: Colors.teal,
                            dense: true),
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
                if (!collapsed) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 12),
                    child: Row(
                      children: [
                        AvatarBubble(
                          name: user.fullName,
                          colorValue: user.avatarColor,
                          radius: 19,
                          showStatus: true,
                          isActive: user.isActive,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                              Text(
                                '${user.title} • ${company?.name ?? 'Bağımsız'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10.5, color: scheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: collapsed ? items[i].label : '',
                      child: HoverLift(
                        scale: 1.0,
                        lift: 0,
                        onTap: () {
                          if (asDrawer) Navigator.of(context).maybePop();
                          setState(() => _index = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: collapsed ? 0 : 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: i == safeIndex
                                ? LinearGradient(
                                    colors: [
                                      scheme.primary.withValues(alpha: 0.22),
                                      scheme.secondary.withValues(alpha: 0.10),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: i == safeIndex
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
                                i == safeIndex
                                    ? items[i].activeIcon
                                    : items[i].icon,
                                size: 19,
                                color: i == safeIndex
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              if (!collapsed) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    items[i].label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: i == safeIndex
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: i == safeIndex
                                          ? scheme.primary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconAction(
                  icon: Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: 'Tema değiştir',
                  onPressed: () => bank.setThemeMode(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'light'
                        : 'dark',
                  ),
                ),
                IconAction(
                  icon: Icons.notifications_none,
                  tooltip: 'Bildirimler',
                  badgeCount: bank.notifications
                      .where((n) => n.userId == null || n.userId == user.id)
                      .where((n) => !n.isRead)
                      .length,
                  onPressed: () => _showMyNotifications(context, bank, user),
                ),
                IconAction(
                  icon: Icons.logout,
                  tooltip: 'Çıkış yap',
                  onPressed: () => showConfirmDialog(
                    context,
                    title: 'Oturumu kapat',
                    message: 'Çıkış yapmak istediğinize emin misiniz?',
                    icon: Icons.logout,
                    onConfirm: bank.logout,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Top bar
  Widget _topBar(BankProvider bank, AppUser user, String title) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (width < 900)
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
          PillBadge(
            label: bank.money(user.balance),
            icon: Icons.account_balance_wallet_outlined,
            color: scheme.primary,
          ),
          const Spacer(),
          IconAction(
            icon: Icons.swap_horiz,
            tooltip: 'Para transferi (F2)',
            onPressed: () => setState(() => _index = 1),
          ),
          IconAction(
            icon: Icons.help_outline,
            tooltip: 'Nasıl çalışır? (F1)',
            onPressed: () => setState(() => _index = 5),
          ),
          IconAction(
            icon: Icons.notifications_none,
            tooltip: 'Bildirimler',
            badgeCount: bank.notifications
                .where((n) => n.userId == null || n.userId == user.id)
                .where((n) => !n.isRead)
                .length,
            onPressed: () => _showMyNotifications(context, bank, user),
          ),
          const SizedBox(width: 6),
          IconAction(
            icon: Icons.logout,
            tooltip: 'Çıkış yap',
            onPressed: () => showConfirmDialog(
              context,
              title: 'Oturumu kapat',
              message: 'Çıkış yapmak istediğinize emin misiniz?',
              icon: Icons.logout,
              onConfirm: bank.logout,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- Genel Bakış
  Widget _overview(BankProvider bank, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final company = bank.companyById(user.companyId);
    final txns = bank.txnsOfUser(user.id);
    final loans = bank.loansOfUser(user.id);
    final now = DateTime.now();
    final daysLeft = user.contractEnd.difference(now).inDays;
    final tax = bank.settings.taxEnabled
        ? user.salary * (bank.settings.taxPercent / 100)
        : 0.0;

    // Son 6 ay gelir/gider
    final months = <DateTime>[];
    for (var i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i));
    }
    final bars = <ChartBar>[];
    for (final m in months) {
      double inflow = 0;
      double outflow = 0;
      for (final t in txns) {
        if (t.date.year != m.year || t.date.month != m.month) continue;
        final effect = t.effectFor(user.id);
        if (effect > 0) {
          inflow += effect;
        } else if (effect < 0) {
          outflow += -effect;
        }
      }
      bars.add(ChartBar(
        label: Fmt.monthShort(m),
        values: [inflow, outflow],
        colors: [const Color(0xFF10B981), const Color(0xFFEF4444)],
      ));
    }

    final recent = txns.take(6).toList();

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(child: _hero(bank, user, company)),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: WrapGrid(
              minItemWidth: 235,
              maxColumns: 4,
              children: [
                StatCard(
                  title: 'Aylık Maaş',
                  value: bank.money(user.salary),
                  numericValue: user.salary,
                  digits: bank.decimalDigits,
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF10B981),
                  subtitle: 'Maaş günü: her ayın ${user.salaryDate.day}. günü',
                ),
                StatCard(
                  title: 'Aylık Prim',
                  value: bank.money(user.bonus),
                  numericValue: user.bonus,
                  digits: bank.decimalDigits,
                  icon: Icons.card_giftcard,
                  color: const Color(0xFF8B5CF6),
                  subtitle: 'Performans primi',
                ),
                StatCard(
                  title: 'Net Aylık (vergi sonrası)',
                  value: bank.money(user.salary - tax + user.bonus),
                  numericValue: user.salary - tax + user.bonus,
                  digits: bank.decimalDigits,
                  icon: Icons.savings_outlined,
                  color: scheme.primary,
                  subtitle: tax > 0
                      ? 'Vergi: ${bank.money(tax)}'
                      : 'Vergi kesintisi kapalı',
                ),
                StatCard(
                  title: 'Kalan Kredi',
                  value: bank.money(loans.fold<double>(
                      0, (a, l) => a + (l.isFinished ? 0 : l.remaining))),
                  numericValue: loans.fold<double>(
                      0, (a, l) => a + (l.isFinished ? 0 : l.remaining)),
                  digits: bank.decimalDigits,
                  icon: Icons.request_quote_outlined,
                  color: const Color(0xFFF59E0B),
                  subtitle: loans.isEmpty
                      ? 'Aktif kredi yok'
                      : '${loans.length} kredi kaydı',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdaptiveRow(
            breakpoint: 1000,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Son 6 Ay Gelir / Gider',
                      subtitle: 'Yalnızca size yansıyan hareketler',
                      icon: Icons.bar_chart_outlined,
                    ),
                    if (txns.isEmpty)
                      const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'Grafik için veri yok',
                        message: 'Maaş ödemesi aldığınızda bu alan dolmaya başlar.',
                      )
                    else
                      GroupedBarChart(
                        bars: bars,
                        seriesLabels: const ['Gelen', 'Giden'],
                        currency: bank.currency,
                        digits: bank.decimalDigits,
                        height: 220,
                      ),
                  ],
                ),
              ),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Sözleşme Durumu',
                      subtitle: 'Kalan gün ve özlük bilgileri',
                      icon: Icons.event_note_outlined,
                    ),
                    Center(
                      child: ProgressRing(
                        value: daysLeft <= 0
                            ? 1
                            : (daysLeft / 365).clamp(0.0, 1.0),
                        size: 130,
                        thickness: 11,
                        color: user.isContractExpired
                            ? const Color(0xFFEF4444)
                            : daysLeft < bank.settings.contractAlertDays
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.isContractExpired ? 'Bitti' : '${daysLeft.clamp(0, 9999)}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              user.isContractExpired ? '' : 'gün',
                              style: TextStyle(
                                  fontSize: 11, color: scheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    KeyValueRow(
                        label: 'Başlangıç',
                        value: Fmt.date(user.contractStart),
                        icon: Icons.play_arrow_outlined),
                    KeyValueRow(
                        label: 'Bitiş',
                        value: Fmt.date(user.contractEnd),
                        icon: Icons.flag_outlined,
                        valueColor: user.isContractExpired
                            ? const Color(0xFFEF4444)
                            : null),
                    KeyValueRow(
                        label: 'Fesih ücreti',
                        value: bank.money(user.terminationFee),
                        icon: Icons.description_outlined),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdaptiveRow(
            breakpoint: 1000,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Son Hareketler',
                      subtitle: '${txns.length} kayıt',
                      icon: Icons.receipt_long_outlined,
                      action: TextButton.icon(
                        onPressed: () => setState(() => _index = 2),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Tümünü gör'),
                      ),
                    ),
                    if (recent.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz hareket yok',
                        message: 'Maaş, prim ve transferleriniz burada listelenir.',
                      )
                    else
                      for (final t in recent)
                        TxnListTile(
                          txn: t,
                          currency: bank.currency,
                          digits: bank.decimalDigits,
                          perspectiveId: user.id,
                        ),
                  ],
                ),
              ),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Hızlı İşlemler',
                      subtitle: 'Sık kullanılan kısayollar',
                      icon: Icons.bolt_outlined,
                    ),
                    _quickAction(
                      icon: Icons.swap_horiz,
                      label: 'Para Transferi',
                      hint: bank.settings.transfersEnabled
                          ? 'Komisyon: ${Fmt.percent(bank.settings.transferFeePercent)}'
                          : 'Transferler kapalı',
                      color: scheme.primary,
                      onTap: () => setState(() => _index = 1),
                    ),
                    _quickAction(
                      icon: Icons.request_quote_outlined,
                      label: 'Kredilerim',
                      hint: '${loans.length} kayıt • taksit öde',
                      color: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _index = 3),
                    ),
                    _quickAction(
                      icon: Icons.person_outline,
                      label: 'Profil Bilgilerim',
                      hint: 'Bilgileri görüntüle',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => setState(() => _index = 4),
                    ),
                    _quickAction(
                      icon: Icons.help_outline,
                      label: 'Nasıl Çalışır?',
                      hint: 'Kurallar ve SSS',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => setState(() => _index = 5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required String hint,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return HoverLift(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(hint,
                      style:
                          TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _hero(BankProvider bank, AppUser user, Company? company) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBubble(
                  name: user.fullName,
                  colorValue: user.avatarColor,
                  radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Merhaba, ${user.fullName}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.white70, size: 18),
                          tooltip: 'İsmi Düzenle',
                          onPressed: () => _editName(context, bank, user),
                        ),
                      ],
                    ),
                    Text(
                      '${user.title} • ${company?.name ?? 'Bağımsız / Şirketsiz'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PillBadge(
                    label: user.isActive ? 'Aktif' : 'Pasif',
                    color: user.isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 6),
                  PillBadge(
                    label: user.isContractExpired
                        ? 'Sözleşme bitti'
                        : '${user.contractDaysLeft} gün kaldı',
                    color: user.isContractExpired
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Kullanılabilir Bakiye',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: user.balance,
            digits: bank.decimalDigits,
            currency: bank.currency,
            symbolAfter: bank.symbolAfter,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Transfer
  Widget _transfer(BankProvider bank, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final s = bank.settings;
    final fee = (Fmt.parseAmount(_amountCtrl.text) ?? 0) * (s.transferFeePercent / 100);
    final amount = Fmt.parseAmount(_amountCtrl.text) ?? 0;

    final recipients = bank.users
        .where((x) => x.id != user.id && x.isActive)
        .where((x) =>
            s.allowCrossCompanyTransfers || x.companyId == user.companyId)
        .where((x) =>
            _recipientQuery.text.trim().isEmpty ||
            x.fullName
                .toLowerCase()
                .contains(_recipientQuery.text.trim().toLowerCase()) ||
            x.email
                .toLowerCase()
                .contains(_recipientQuery.text.trim().toLowerCase()))
        .toList();

    final transfers =
        bank.txnsOfUser(user.id).where((t) => t.type == TxnType.transfer).take(6);

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Para Transferi',
                    subtitle: 'Bakiyeden başka bir hesaba anında gönderim',
                    icon: Icons.swap_horiz,
                  ),
                  if (!s.transfersEnabled)
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      color: scheme.errorContainer.withValues(alpha: 0.4),
                      child: Row(
                        children: [
                          Icon(Icons.block, color: scheme.error, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                                'Para transferleri yönetici tarafından kapatılmış.'),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillBadge(
                          label: 'Komisyon ${Fmt.percent(s.transferFeePercent)}',
                          icon: Icons.percent,
                          color: scheme.primary,
                        ),
                        if (s.transferMinAmount > 0)
                          PillBadge(
                            label: 'Min ${bank.money(s.transferMinAmount)}',
                            icon: Icons.arrow_downward,
                            color: const Color(0xFF0EA5E9),
                          ),
                        if (s.transferMaxAmount > 0)
                          PillBadge(
                            label: 'Maks ${bank.money(s.transferMaxAmount)}',
                            icon: Icons.arrow_upward,
                            color: const Color(0xFFF59E0B),
                          ),
                        PillBadge(
                          label: s.requireTransferNote
                              ? 'Açıklama zorunlu'
                              : 'Açıklama opsiyonel',
                          icon: Icons.notes,
                          color: s.requireTransferNote
                              ? const Color(0xFFEF4444)
                              : scheme.outline,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  SearchInput(
                    controller: _recipientQuery,
                    hint: 'Alıcı ara (ad veya e-posta)',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: recipients.any((r) => r.id == _recipientId)
                        ? _recipientId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Alıcı Seçin',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      for (final r in recipients)
                        DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            '${r.fullName} (${r.email}) • ${bank.money(r.balance)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _recipientId = v),
                  ),
                  const SizedBox(height: 12),
                  FormRow(
                    children: [
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Tutar (${bank.currency})',
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                      ),
                      TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama (opsiyonel)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final preset in [100.0, 500.0, 1000.0, 5000.0])
                        ActionChip(
                          label: Text(bank.money(preset, compact: true)),
                          onPressed: () {
                            _amountCtrl.text = preset.toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                      ActionChip(
                        label: const Text('Tüm bakiye'),
                        onPressed: () {
                          _amountCtrl.text =
                              user.balance.toStringAsFixed(bank.decimalDigits);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              KeyValueRow(
                                  label: 'Gönderilecek',
                                  value: bank.money(amount),
                                  icon: Icons.arrow_upward,
                                  dense: true),
                              KeyValueRow(
                                  label: 'Komisyon',
                                  value: bank.money(fee),
                                  icon: Icons.percent,
                                  dense: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Toplam',
                                style: TextStyle(
                                    fontSize: 11, color: scheme.outline)),
                            Text(
                              bank.money(amount + fee),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            Text(
                              'Bakiye: ${bank.money(user.balance)}',
                              style: TextStyle(
                                  fontSize: 11, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _sendTransfer(bank, user),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Transferi Gerçekleştir'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (transfers.isNotEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Son Transferlerim',
                      icon: Icons.history_outlined,
                    ),
                    for (final t in transfers)
                      TxnListTile(
                        txn: t,
                        currency: bank.currency,
                        digits: bank.decimalDigits,
                        perspectiveId: user.id,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sendTransfer(BankProvider bank, AppUser user) {
    final amount = Fmt.parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      showSnackBar(context, 'Lütfen geçerli ve pozitif bir tutar girin.',
          error: true);
      return;
    }
    if (_recipientId == null) {
      showSnackBar(context, 'Lütfen parayı göndereceğiniz alıcıyı seçin.',
          error: true);
      return;
    }
    try {
      bank.userTransfer(
        user.id,
        _recipientId!,
        amount,
        _noteCtrl.text.trim().isEmpty
            ? 'Hesaplar arası para transferi'
            : _noteCtrl.text.trim(),
      );
      _amountCtrl.clear();
      _noteCtrl.clear();
      setState(() => _recipientId = null);
      showSnackBar(context, '${bank.money(amount)} başarıyla transfer edildi.');
    } catch (e) {
      showError(context, e);
    }
  }

  // ---------------------------------------------------------- İşlemlerim
  Widget _transactions(BankProvider bank, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final all = bank.txnsOfUser(user.id);
    final query = _txnQuery.text.trim().toLowerCase();
    final filtered = all.where((t) {
      if (_flow == 1 && t.effectFor(user.id) <= 0) return false;
      if (_flow == 2 && t.effectFor(user.id) >= 0) return false;
      if (query.isEmpty) return true;
      return t.description.toLowerCase().contains(query) ||
          t.type.label.toLowerCase().contains(query);
    }).toList();

    double inflow = 0;
    double outflow = 0;
    for (final t in filtered) {
      final e = t.effectFor(user.id);
      if (e > 0) {
        inflow += e;
      } else if (e < 0) {
        outflow += -e;
      }
    }
    final visible = filtered.take(_visibleTxns).toList();

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'İşlemlerim',
                    subtitle: '${filtered.length} kayıt • tümü: ${all.length}',
                    icon: Icons.receipt_long_outlined,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SearchInput(
                          controller: _txnQuery,
                          hint: 'Açıklama veya tür ara',
                          onChanged: (_) =>
                              setState(() => _visibleTxns = 25),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Tümü')),
                          ButtonSegment(value: 1, label: Text('Gelen')),
                          ButtonSegment(value: 2, label: Text('Giden')),
                        ],
                        selected: {_flow},
                        onSelectionChanged: (v) =>
                            setState(() => _flow = v.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          WrapGrid(
            minItemWidth: 230,
            maxColumns: 3,
            children: [
              StatCard(
                title: 'Toplam Gelen',
                value: bank.money(inflow),
                numericValue: inflow,
                digits: bank.decimalDigits,
                icon: Icons.south_west,
                color: const Color(0xFF10B981),
              ),
              StatCard(
                title: 'Toplam Giden',
                value: bank.money(outflow),
                numericValue: outflow,
                digits: bank.decimalDigits,
                icon: Icons.north_east,
                color: const Color(0xFFEF4444),
              ),
              StatCard(
                title: 'Net',
                value: bank.money(inflow - outflow),
                numericValue: inflow - outflow,
                digits: bank.decimalDigits,
                icon: Icons.balance_outlined,
                color: scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Kayıt bulunamadı',
                message: 'Arama koşullarını değiştirmeyi deneyin.',
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  for (final t in visible)
                    TxnListTile(
                      txn: t,
                      currency: bank.currency,
                      digits: bank.decimalDigits,
                      perspectiveId: user.id,
                    ),
                ],
              ),
            ),
          if (filtered.length > visible.length)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: () => setState(() => _visibleTxns += 50),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                      'Daha fazla göster (${filtered.length - visible.length} kayıt daha)'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Krediler
  Widget _loans(BankProvider bank, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final loans = bank.loansOfUser(user.id);

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Kredilerim',
                    subtitle: bank.settings.loansEnabled
                        ? 'Kalan borç: ${bank.money(loans.fold<double>(0, (a, l) => a + (l.isFinished ? 0 : l.remaining)))}'
                        : 'Kredi sistemi kapatılmış',
                    icon: Icons.request_quote_outlined,
                  ),
                  const Text(
                    'Maaş ödemeniz sırasında taksitler otomatik tahsil edilir. '
                    'Buradan elle taksit ödeyerek borcunuzu kapatabilirsiniz.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (loans.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.request_quote_outlined,
                title: 'Kredi kaydınız yok',
                message:
                    'Avans veya kredi talebiniz için yöneticinizle iletişime geçin.',
              ),
            )
          else
            WrapGrid(
              minItemWidth: 380,
              maxColumns: 3,
              children: [
                for (final loan in loans)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProgressRing(
                              value: loan.progress,
                              size: 64,
                              thickness: 6,
                              color: loan.isFinished
                                  ? const Color(0xFF10B981)
                                  : scheme.primary,
                              child: Text(
                                '${(loan.progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.money(loan.principal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    loan.isFinished ? 'Tamamlandı' : 'Aktif kredi',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: loan.isFinished
                                          ? const Color(0xFF10B981)
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PillBadge(
                              label:
                                  '${loan.paidInstallments}/${loan.totalInstallments} taksit',
                              color: scheme.secondary,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        KeyValueRow(
                            label: 'Taksit tutarı',
                            value: bank.money(loan.installmentAmount),
                            icon: Icons.repeat,
                            dense: true),
                        KeyValueRow(
                            label: 'Kalan borç',
                            value: bank.money(loan.remaining),
                            icon: Icons.trending_down,
                            dense: true),
                        KeyValueRow(
                            label: 'Toplam geri ödeme',
                            value: bank.money(loan.totalPayable),
                            icon: Icons.summarize_outlined,
                            dense: true),
                        KeyValueRow(
                            label: 'Sonraki vade',
                            value: Fmt.date(loan.nextDueDate),
                            icon: Icons.event_available_outlined,
                            dense: true),
                        const SizedBox(height: 10),
                        if (!loan.isFinished)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                final amount =
                                    (loan.installmentAmount < loan.remaining
                                        ? loan.installmentAmount
                                        : loan.remaining);
                                showConfirmDialog(
                                  context,
                                  title: 'Taksit ödemesi',
                                  message:
                                      '${bank.money(amount)} taksit ödemesi bakiyenizden düşülecek. Onaylıyor musunuz?',
                                  icon: Icons.repeat,
                                  confirmText: 'Öde',
                                  onConfirm: () {
                                    try {
                                      bank.payLoanInstallment(loan.id);
                                      showSnackBar(context,
                                          '${bank.money(amount)} taksit ödendi.');
                                    } catch (e) {
                                      showError(context, e);
                                    }
                                  },
                                );
                              },
                              icon: const Icon(Icons.payments_outlined, size: 17),
                              label: const Text('Taksit Öde'),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                bank.deleteLoan(loan.id);
                                showSnackBar(context,
                                    'Tamamlanan kredi kaydı silindi.');
                              },
                              icon: const Icon(Icons.delete_outline, size: 17),
                              label: const Text('Kaydı Kaldır'),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Profil
  Widget _profile(BankProvider bank, AppUser user) {
    final company = bank.companyById(user.companyId);
    final tax = bank.settings.taxEnabled
        ? user.salary * (bank.settings.taxPercent / 100)
        : 0.0;
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AvatarBubble(
                    name: user.fullName,
                    colorValue: user.avatarColor,
                    radius: 30,
                    showStatus: true,
                    isActive: user.isActive,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'İsmi Düzenle',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editName(context, bank, user),
                            ),
                          ],
                        ),
                        Text('${user.roleLabel} • ${company?.name ?? 'Bağımsız'}',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(bank.money(user.balance),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('kullanılabilir bakiye',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AdaptiveRow(
            breakpoint: 1000,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        title: 'İletişim & Hesap Bilgileri',
                        icon: Icons.badge_outlined),
                    KeyValueRow(
                        label: 'E-posta',
                        value: user.email,
                        icon: Icons.alternate_email),
                    KeyValueRow(
                        label: 'Telefon',
                        value: user.phone.isEmpty ? '-' : user.phone,
                        icon: Icons.phone_outlined),
                    KeyValueRow(
                        label: 'IBAN',
                        value: user.iban.isEmpty ? '-' : user.iban,
                        icon: Icons.account_balance_outlined),
                    KeyValueRow(
                        label: 'Departman',
                        value: user.department.isEmpty ? '-' : user.department,
                        icon: Icons.grid_view_outlined),
                    KeyValueRow(
                        label: 'İşe giriş',
                        value: Fmt.date(user.hireDate),
                        icon: Icons.event_outlined),
                    KeyValueRow(
                        label: 'Son giriş',
                        value: user.lastLogin == null
                            ? '-'
                            : Fmt.dateTime(user.lastLogin!),
                        icon: Icons.login_outlined),
                  ],
                ),
              ),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        title: 'Ücret & Sözleşme',
                        icon: Icons.payments_outlined),
                    KeyValueRow(
                        label: 'Brüt maaş',
                        value: bank.money(user.salary),
                        icon: Icons.payments_outlined),
                    KeyValueRow(
                        label: 'Aylık prim',
                        value: bank.money(user.bonus),
                        icon: Icons.card_giftcard),
                    if (tax > 0)
                      KeyValueRow(
                          label: 'Gelir vergisi (%${bank.settings.taxPercent.toStringAsFixed(0)})',
                          value: '-${bank.money(tax)}',
                          icon: Icons.percent,
                          valueColor: const Color(0xFFEF4444)),
                    KeyValueRow(
                        label: 'Net aylık',
                        value: bank.money(user.salary - tax + user.bonus),
                        icon: Icons.savings_outlined,
                        valueColor: const Color(0xFF10B981)),
                    KeyValueRow(
                        label: 'Maaş günü',
                        value: 'Her ayın ${user.salaryDate.day}. günü',
                        icon: Icons.event_repeat_outlined),
                    KeyValueRow(
                        label: 'Sözleşme',
                        value:
                            '${Fmt.date(user.contractStart)} → ${Fmt.date(user.contractEnd)}',
                        icon: Icons.event_note_outlined),
                    if (!user.isContractExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: MiniProgress(
                          value: (user.contractDaysLeft / 365).clamp(0.0, 1.0),
                          showLabel: true,
                          label: '${user.contractDaysLeft} gün kaldı',
                          color: user.isContractExpiringSoon
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                    title: 'Görünüm Tercihleri',
                    subtitle: 'Bu ayarlar yalnızca uygulamayı etkiler',
                    icon: Icons.palette_outlined),
                SwitchListTile(
                  value: bank.animationsEnabled,
                  onChanged: bank.setAnimations,
                  title: const Text('Animasyonlar'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: bank.settings.gradientBackground,
                  onChanged: bank.setGradientBackground,
                  title: const Text('Gradyan arka plan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Durum çubuğu
  Widget _statusBar(BankProvider bank, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const PulseDot(),
          const SizedBox(width: 8),
          Text('${bank.bankName} • ${dark ? 'Koyu tema' : 'Açık tema'}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const Spacer(),
          Text('Bakiye: ${bank.money(user.balance)}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Text(user.isContractExpired
              ? 'Sözleşme: süresi doldu'
              : 'Sözleşme: ${user.contractDaysLeft} gün',
              style: TextStyle(
                fontSize: 11,
                color: user.isContractExpired
                    ? const Color(0xFFEF4444)
                    : scheme.onSurfaceVariant,
              )),
          const SizedBox(width: 16),
          Icon(Icons.schedule, size: 13, color: scheme.outline),
          const SizedBox(width: 5),
          Text(Fmt.clock(DateTime.now()),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Yardımcı
  Future<void> _editName(
      BuildContext context, BankProvider bank, AppUser user) async {
    final controller = TextEditingController(text: user.fullName);
    String? error;
    await showAppDialog<void>(
      context,
      title: 'İsmi Düzenle',
      subtitle: user.email,
      icon: Icons.drive_file_rename_outline,
      maxWidth: 440,
      child: StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Yeni Ad Soyad',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: error,
              ),
              onSubmitted: (_) {
                final clean = controller.text.trim();
                if (clean.isEmpty) {
                  setState(() => error = 'Ad Soyad boş bırakılamaz.');
                  return;
                }
                try {
                  bank.updateUserName(user.id, clean);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'İsminiz başarıyla güncellendi.');
                } catch (e) {
                  setState(() => error = e.toString().replaceAll('Exception: ', ''));
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('İptal')),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final clean = controller.text.trim();
                    if (clean.isEmpty) {
                      setState(() => error = 'Ad Soyad boş bırakılamaz.');
                      return;
                    }
                    try {
                      bank.updateUserName(user.id, clean);
                      Navigator.pop(ctx);
                      showSnackBar(context, 'İsminiz başarıyla güncellendi.');
                    } catch (e) {
                      setState(
                          () => error = e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

/// Portal bölümü tanımı.
class _PortalSection {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget child;

  const _PortalSection(this.label, this.icon, this.activeIcon, this.child);
}

/// Çalışan bildirim paneli.
Future<void> _showMyNotifications(
  BuildContext context,
  BankProvider bank,
  AppUser user,
) async {
  final items = bank.notifications
      .where((n) => n.userId == null || n.userId == user.id)
      .toList();
  await showAppDialog<void>(
    context,
    title: 'Bildirimler',
    subtitle: '${items.where((n) => !n.isRead).length} okunmamış',
    icon: Icons.notifications_none,
    maxWidth: 560,
    child: items.isEmpty
        ? const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Bildirim yok',
            message: 'Maaş, prim ve kesinti hareketlerinde burada bilgilendirilirsiniz.',
          )
        : Column(
            children: [
              for (final n in items.take(40))
                ListTile(
                  dense: true,
                  title: Text(n.title,
                      style: TextStyle(
                        fontWeight:
                            n.isRead ? FontWeight.w500 : FontWeight.w800,
                      )),
                  subtitle: Text(
                      '${n.body}\n${Fmt.dateTime(n.date)}'),
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: n.kind.color.withValues(alpha: 0.16),
                    child: Icon(n.kind.icon, size: 17, color: n.kind.color),
                  ),
                  onTap: n.isRead ? null : () => bank.markNotificationRead(n.id),
                ),
            ],
          ),
  );
}
