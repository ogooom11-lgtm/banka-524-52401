import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../dialogs/company_dialogs.dart';
import '../dialogs/import_export_dialogs.dart';
import '../dialogs/user_dialogs.dart';

/// Yönetici panosu: özet istatistikler, grafikler, hızlı işlemler ve riskler.
class OverviewTab extends StatelessWidget {
  /// Sayfa anahtarı: 'users', 'transactions', 'help' ...
  final void Function(String route)? onNavigate;

  const OverviewTab({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final preset = accentById(bank.accentId);
    final since = DateTime.now().subtract(const Duration(days: 30));
    final series = bank.monthlySeries(months: 6);
    final typeTotals = bank.typeTotals(from: since);
    final risky = bank.riskyContracts;
    final recent = bank.transactions.take(8).toList();

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: _header(context, bank, scheme),
          ),
          const SizedBox(height: 18),
          WrapGrid(
            minItemWidth: 250,
            maxColumns: 4,
            children: [
              StatCard(
                title: 'Toplam Banka Varlığı',
                value: '',
                numericValue: bank.totalBankAssets,
                icon: Icons.account_balance_outlined,
                color: preset.seed,
                subtitle: 'Şirket + kullanıcı bakiyeleri',
                trendPercent: _trend(bank),
                trendLabel: 'son 30 gün',
              ),
              StatCard(
                title: 'Şirket Bakiyeleri',
                value: '',
                numericValue: bank.totalCompanyBalance,
                icon: Icons.business_outlined,
                color: const Color(0xFF06B6D4),
                subtitle: '${bank.companies.length} şirket hesabı',
              ),
              StatCard(
                title: 'Kullanıcı Bakiyeleri',
                value: '',
                numericValue: bank.totalUserBalance,
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF8B5CF6),
                subtitle: '${bank.users.length} kullanıcı hesabı',
              ),
              StatCard(
                title: 'Aylık Maaş Yükü',
                value: '',
                numericValue: bank.totalMonthlySalaries,
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
                subtitle: '${bank.activeEmployeeCount} aktif çalışan',
              ),
              StatCard(
                title: 'Aylık Prim Yükü',
                value: '',
                numericValue: bank.totalMonthlyBonuses,
                icon: Icons.card_giftcard,
                color: const Color(0xFFF59E0B),
                subtitle: 'tanımlı aylık primler',
              ),
              StatCard(
                title: 'Aktif Krediler',
                value: '',
                numericValue: bank.totalLoanRemaining,
                icon: Icons.request_quote_outlined,
                color: const Color(0xFFE11D48),
                subtitle: '${bank.activeLoanCount} adet kredi kaydı',
              ),
              StatCard(
                title: 'Son 30 Gün Girişi',
                value: '',
                numericValue: bank.inflowSince(since),
                icon: Icons.south_west,
                color: const Color(0xFF22C55E),
                subtitle: '${bank.txnsSince(since)} işlem',
              ),
              StatCard(
                title: 'Son 30 Gün Çıkışı',
                value: '',
                numericValue: bank.outflowSince(since),
                icon: Icons.north_east,
                color: const Color(0xFFEF4444),
                subtitle: 'maaş, ceza, vergi dahil',
              ),
            ],
          ),
          const SizedBox(height: 22),
          AdaptiveRow(
            flex: const [3, 2],
            breakpoint: 1080,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: '6 aylık nakit akışı',
                      subtitle: 'Gelir, gider ve maaş ödemeleri',
                      icon: Icons.bar_chart_rounded,
                    ),
                    GroupedBarChart(
                      currency: bank.currency,
                      seriesLabels: const ['Gelir', 'Gider', 'Maaş'],
                      bars: [
                        for (final p in series)
                          ChartBar(
                            label: Fmt.monthShort(p.month),
                            values: [
                              p.income,
                              p.expense - p.salaries,
                              p.salaries,
                            ],
                            colors: const [
                              Color(0xFF22C55E),
                              Color(0xFFF59E0B),
                              Color(0xFF6366F1),
                            ],
                          ),
                      ],
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
                      title: 'İşlem türü dağılımı',
                      subtitle: 'Son 30 gün',
                      icon: Icons.donut_large_outlined,
                    ),
                    Center(
                      child: DonutChart(
                        size: 180,
                        centerTitle: 'Toplam hacim',
                        centerValue: bank.money(
                          typeTotals.values.fold<double>(0, (a, b) => a + b),
                          compact: true,
                        ),
                        slices: [
                          for (final entry in _topTypes(typeTotals))
                            DonutSlice(
                              label: entry.$1.label,
                              value: entry.$2,
                              color: _typeColor(entry.$1),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in _topTypes(typeTotals).take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: _typeColor(entry.$1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.$1.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              bank.money(entry.$2, compact: true),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Hızlı işlemler',
                  subtitle: 'Tek tıkla en sık kullanılan işlemler',
                  icon: Icons.bolt_outlined,
                  action: TextButton.icon(
                    onPressed: () => showImportDialog(context),
                    icon: const Icon(Icons.upload_file_outlined, size: 17),
                    label: const Text('İçe Aktar'),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickAction(
                      context,
                      icon: Icons.payments_outlined,
                      label: 'Vadesi Gelen Maaşları Öde',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        final n = bank.processDueSalaries();
                        showSnackBar(
                          context,
                          n > 0
                              ? '$n çalışana maaş ödemesi yapıldı.'
                              : 'Vadesi gelen ödenecek maaş bulunmuyor.',
                          success: n > 0,
                        );
                      },
                    ),
                    _quickAction(
                      context,
                      icon: Icons.event_repeat_outlined,
                      label: 'Tanımlı Aylık Primleri Öde',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        final n = bank.payMonthlyBonuses();
                        showSnackBar(
                          context,
                          n > 0
                              ? '$n çalışana aylık prim ödendi.'
                              : 'Ödenecek prim bulunmuyor.',
                          success: n > 0,
                        );
                      },
                    ),
                    _quickAction(
                      context,
                      icon: Icons.casino_outlined,
                      label: 'Rastgele Kredi Kesintisi',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        try {
                          final n = bank.applyRandomDeductionsToAll();
                          showSnackBar(
                            context,
                            n > 0
                                ? '$n çalışana rastgele kesinti uygulandı.'
                                : 'Kesinti yapılabilecek bakiye bulunamadı.',
                            success: n > 0,
                          );
                        } catch (e) {
                          showError(context, e);
                        }
                      },
                    ),
                    _quickAction(
                      context,
                      icon: Icons.person_add_alt_1,
                      label: 'Yeni Kullanıcı',
                      color: preset.seed,
                      onTap: () => showUserEditor(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.add_business_outlined,
                      label: 'Yeni Şirket',
                      color: const Color(0xFF06B6D4),
                      onTap: () => showCompanyEditor(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.storage_outlined,
                      label: 'Yedek Al / Geri Yükle',
                      color: const Color(0xFF64748B),
                      onTap: () => showDataManagementDialog(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.undo_rounded,
                      label: bank.canUndo
                          ? 'Geri Al: ${bank.lastUndoLabel ?? ''}'
                          : 'Geri Al',
                      color: const Color(0xFFEF4444),
                      enabled: bank.canUndo,
                      onTap: () {
                        bank.undo();
                        showSnackBar(context, 'Son işlem geri alındı.');
                      },
                    ),
                    _quickAction(
                      context,
                      icon: Icons.help_outline,
                      label: 'Nasıl Çalışır?',
                      color: const Color(0xFF3B82F6),
                      onTap: () => onNavigate?.call('help'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AdaptiveRow(
            flex: const [3, 2],
            breakpoint: 1080,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Son hareketler',
                      subtitle: '${bank.transactions.length} kayıt içinden en yeniler',
                      icon: Icons.receipt_long_outlined,
                      action: TextButton(
                        onPressed: () => onNavigate?.call('transactions'),
                        child: const Text('Tümü'),
                      ),
                    ),
                    if (recent.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz işlem yok',
                        message:
                            'Maaş ödediğinizde, prim dağıttığınızda veya transfer yapıldığında hareketler burada listelenir.',
                      )
                    else
                      Column(
                        children: [
                          for (final t in recent)
                            TxnListTile(
                              txn: t,
                              currency: bank.currency,
                              digits: bank.decimalDigits,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Sözleşme riskleri',
                      subtitle:
                          '${bank.settings.contractAlertDays} gün içinde dolan sözleşmeler',
                      icon: Icons.gpp_maybe_outlined,
                      action: risky.isEmpty
                          ? null
                          : PillBadge(
                              label: '${risky.length}',
                              color: const Color(0xFFEF4444),
                            ),
                    ),
                    if (risky.isEmpty)
                      const EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Risk yok',
                        message:
                            'Yakın zamanda süresi dolacak sözleşme bulunmuyor. Harika!',
                      )
                    else
                      Column(
                        children: [
                          for (final u in risky.take(6))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: AvatarBubble(
                                name: u.fullName,
                                colorValue: u.avatarColor,
                                radius: 17,
                              ),
                              title: Text(u.fullName),
                              subtitle: Text(
                                '${bank.companyById(u.companyId)?.name ?? 'bağımsız'} • '
                                'bitiş ${Fmt.date(u.contractEnd)}',
                              ),
                              trailing: PillBadge(
                                label: u.isContractExpired
                                    ? 'süresi doldu'
                                    : '${u.contractDaysLeft} gün',
                                color: u.isContractExpired
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B),
                                dense: true,
                              ),
                              onTap: () => onNavigate?.call('users'),
                            ),
                        ],
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

  /// Son 30 günün net nakit akışı, çıkışa oranlanmış yüzde olarak.
  double? _trend(BankProvider bank) {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final inflow = bank.inflowSince(since);
    final outflow = bank.outflowSince(since);
    if (inflow == 0 && outflow == 0) return null;
    final base = math.max(outflow, 1.0);
    final ratio = (inflow - outflow) / base * 100;
    return ratio.clamp(-100.0, 100.0);
  }

  List<(TxnType, double)> _topTypes(Map<TxnType, double> totals) {
    final list = totals.entries
        .where((e) => e.value > 0)
        .map((e) => (e.key, e.value))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(7).toList();
  }

  static Color _typeColor(TxnType t) => TxnIcon.colorOf(t);

  Widget _header(BuildContext context, BankProvider bank, ColorScheme scheme) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 6
        ? 'İyi geceler'
        : hour < 12
            ? 'Günaydın'
            : hour < 18
                ? 'İyi günler'
                : 'İyi akşamlar';
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${bank.currentUser?.fullName ?? 'Yönetici'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${Fmt.dateLong(now)} • ${bank.companies.length} şirket, '
                  '${bank.activeEmployeeCount} aktif çalışan yönetiliyor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const PulseDot(color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text(
                    'Sistem çalışıyor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Son kayıt: ${bank.transactions.isEmpty ? '-' : Fmt.ago(bank.transactions.first.date)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return HoverLift(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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
