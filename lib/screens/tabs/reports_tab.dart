import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../dialogs/import_export_dialogs.dart';

/// Raporlar: grafikler, karşılaştırmalar ve performans göstergeleri.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _rangeDays = 180;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final since = DateTime.now().subtract(Duration(days: _rangeDays));
    final months = _rangeDays <= 30 ? 2 : (_rangeDays <= 90 ? 4 : 6);
    final series = bank.monthlySeries(months: months);
    final totals = bank.typeTotals(from: since);
    final totalVolume = totals.values.fold<double>(0, (a, b) => a + b);
    final income = bank.inflowSince(since);
    final expense = bank.outflowSince(since);
    final topEarners = bank.topEarners(limit: 8);
    final risky = bank.riskyContracts;

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Raporlar & Analiz',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              'Seçilen dönemdeki nakit akışı, işlem dağılımı ve çalışan performansı.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final outcome = await _export(context, bank);
                          if (!context.mounted || outcome == null) return;
                          showSnackBar(context, outcome);
                        },
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Raporu Dışa Aktar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 30, label: Text('30 gün')),
                      ButtonSegment(value: 90, label: Text('90 gün')),
                      ButtonSegment(value: 180, label: Text('6 ay')),
                      ButtonSegment(value: 365, label: Text('1 yıl')),
                    ],
                    selected: {_rangeDays},
                    onSelectionChanged: (v) =>
                        setState(() => _rangeDays = v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          WrapGrid(
            minItemWidth: 240,
            maxColumns: 4,
            children: [
              StatCard(
                title: 'Toplam İşlem Hacmi',
                value: '',
                numericValue: totalVolume,
                icon: Icons.swap_vert,
                subtitle: '${bank.txnsSince(since)} işlem',
              ),
              StatCard(
                title: 'Dönem Girişi',
                value: '',
                numericValue: income,
                icon: Icons.trending_up,
                color: const Color(0xFF22C55E),
              ),
              StatCard(
                title: 'Dönem Çıkışı',
                value: '',
                numericValue: expense,
                icon: Icons.trending_down,
                color: const Color(0xFFEF4444),
              ),
              StatCard(
                title: 'Net Nakit Akışı',
                value: '',
                numericValue: income - expense,
                icon: Icons.account_balance_outlined,
                color: income - expense >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              StatCard(
                title: 'Ortalama Maaş',
                value: '',
                numericValue: bank.averageSalary,
                icon: Icons.people_outline,
                color: const Color(0xFF8B5CF6),
              ),
              StatCard(
                title: 'Aktif Çalışan',
                value: '${bank.activeEmployeeCount}',
                icon: Icons.badge_outlined,
                color: const Color(0xFF06B6D4),
                subtitle: '${bank.passiveUserCount} pasif hesap',
              ),
              StatCard(
                title: 'Kalan Kredi Borcu',
                value: '',
                numericValue: bank.totalLoanRemaining,
                icon: Icons.request_quote_outlined,
                color: const Color(0xFFF59E0B),
                subtitle: '${bank.activeLoanCount} aktif kredi',
              ),
              StatCard(
                title: 'Riskli Sözleşme',
                value: '${risky.length}',
                icon: Icons.gpp_maybe_outlined,
                color: risky.isEmpty
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                subtitle:
                    '${bank.settings.contractAlertDays} gün içinde dolanlar',
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Aylık nakit akışı',
                  subtitle: 'Gelir / gider / maaş karşılaştırması',
                  icon: Icons.stacked_bar_chart,
                ),
                GroupedBarChart(
                  currency: bank.currency,
                  seriesLabels: const ['Gelir', 'Diğer gider', 'Maaş'],
                  bars: [
                    for (final p in series)
                      ChartBar(
                        label: Fmt.monthShort(p.month),
                        values: [p.income, p.expense - p.salaries, p.salaries],
                        colors: const [
                          Color(0xFF22C55E),
                          Color(0xFFF59E0B),
                          Color(0xFF6366F1),
                        ],
                      ),
                  ],
                  height: 250,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AdaptiveRow(
            flex: const [1, 1],
            breakpoint: 1080,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'İşlem türlerine göre hacim',
                      icon: Icons.pie_chart_outline,
                    ),
                    HorizontalBars(
                      formatValue: (v) => bank.money(v, compact: true),
                      items: _sortedSlices(bank, totals),
                    ),
                    if (totals.isEmpty)
                      const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'Veri yok',
                        message: 'Seçilen dönemde işlem bulunmuyor.',
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
                      title: 'Şirket bakiye dağılımı',
                      icon: Icons.donut_small_outlined,
                    ),
                    Center(
                      child: DonutChart(
                        size: 190,
                        centerTitle: 'Toplam',
                        centerValue:
                            bank.money(bank.totalCompanyBalance, compact: true),
                        slices: [
                          for (final c in bank.companies)
                            DonutSlice(
                              label: c.name,
                              value: c.balance,
                              color: c.colorValue == 0
                                  ? scheme.primary
                                  : Color(c.colorValue),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final c in bank.companies)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: c.colorValue == 0
                                    ? scheme.primary
                                    : Color(c.colorValue),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Text(
                              bank.money(c.balance, compact: true),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
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
                const SectionHeader(
                  title: 'Şirket karşılaştırması',
                  subtitle: 'Çalışan sayısı, aylık yük ve maaş sınırı doluluğu',
                  icon: Icons.compare_arrows,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 26,
                    headingRowHeight: 44,
                    dataRowMinHeight: 46,
                    dataRowMaxHeight: 62,
                    columns: const [
                      DataColumn(label: Text('Şirket')),
                      DataColumn(label: Text('Çalışan')),
                      DataColumn(label: Text('Aylık Maaş Yükü')),
                      DataColumn(label: Text('Ort. Maaş')),
                      DataColumn(label: Text('Bakiye')),
                      DataColumn(label: Text('Sınır Doluluğu')),
                    ],
                    rows: [
                      for (final c in bank.companies)
                        DataRow(cells: [
                          DataCell(Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(
                              '${bank.companyStats(c.id).activeEmployees} / ${bank.companyStats(c.id).employees}')),
                          DataCell(Text(bank.money(
                              bank.companyStats(c.id).monthlySalaries))),
                          DataCell(Text(
                              bank.money(bank.companyStats(c.id).averageSalary))),
                          DataCell(Text(bank.money(c.balance))),
                          DataCell(
                            SizedBox(
                              width: 130,
                              child: MiniProgress(
                                value: bank.companyStats(c.id).limitUsage,
                                showLabel: true,
                                label: 'ortalama',
                                color: c.colorValue == 0
                                    ? scheme.primary
                                    : Color(c.colorValue),
                              ),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
                if (bank.companies.isEmpty)
                  const EmptyState(
                    icon: Icons.business_outlined,
                    title: 'Şirket yok',
                    message: 'Karşılaştırma yapabilmek için önce şirket oluşturun.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AdaptiveRow(
            flex: const [1, 1],
            breakpoint: 1080,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'En yüksek maaşlar',
                      icon: Icons.emoji_events_outlined,
                    ),
                    for (final u in topEarners)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            AvatarBubble(
                              name: u.fullName,
                              colorValue: u.avatarColor,
                              radius: 15,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.fullName,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    '${u.title} • ${bank.companyById(u.companyId)?.name ?? 'bağımsız'}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              bank.money(u.salary),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ],
                        ),
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
                      title: 'Kredi performansı',
                      subtitle: 'Taksit ilerlemesi ve kalan borç',
                      icon: Icons.request_quote_outlined,
                    ),
                    if (bank.loans.isEmpty)
                      const EmptyState(
                        icon: Icons.request_quote_outlined,
                        title: 'Kredi kaydı yok',
                        message:
                            'Maaş Merkezi sekmesinden çalışanlara kredi tanımlayabilirsiniz.',
                      )
                    else
                      for (final loan in bank.loans)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              ProgressRing(
                                value: loan.progress,
                                size: 46,
                                thickness: 6,
                                color: loan.isFinished
                                    ? const Color(0xFF22C55E)
                                    : scheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bank.userById(loan.userId)?.fullName ??
                                          'bilinmeyen',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5),
                                    ),
                                    Text(
                                      '${loan.paidInstallments}/${loan.totalInstallments} taksit • '
                                      'kalan ${bank.money(loan.remaining)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PillBadge(
                                label: loan.isFinished ? 'bitti' : 'aktif',
                                color: loan.isFinished
                                    ? const Color(0xFF22C55E)
                                    : scheme.primary,
                                dense: true,
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
                  title: 'Sözleşme risk haritası',
                  subtitle:
                      '${risky.length} sözleşme ${bank.settings.contractAlertDays} gün içinde doluyor',
                  icon: Icons.event_busy_outlined,
                  action: risky.isEmpty
                      ? null
                      : PillBadge(
                          label: '${risky.length} uyarı',
                          color: const Color(0xFFEF4444)),
                ),
                if (risky.isEmpty)
                  const EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Tüm sözleşmeler güvende',
                    message:
                        'Belirlenen uyarı süresi içinde dolacak sözleşme bulunmuyor.',
                  )
                else
                  ResponsiveList(
                    spacing: 8,
                    children: [
                      for (final u in risky.take(12))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (u.isContractExpired
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (u.isContractExpired
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              AvatarBubble(
                                  name: u.fullName,
                                  colorValue: u.avatarColor,
                                  radius: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.fullName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    Text(
                                      '${bank.companyById(u.companyId)?.name ?? 'bağımsız'} • '
                                      '${u.title} • bitiş ${Fmt.date(u.contractEnd)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                u.isContractExpired
                                    ? 'Süresi doldu'
                                    : '${u.contractDaysLeft} gün kaldı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: u.isContractExpired
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
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

  List<DonutSlice> _sortedSlices(BankProvider bank, Map<TxnType, double> totals) {
    final list = totals.entries
        .where((e) => e.value > 0)
        .map((e) => DonutSlice(
              label: e.key.label,
              value: e.value,
              color: TxnIcon.colorOf(e.key),
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Future<String?> _export(BuildContext context, BankProvider bank) async {
    await showDataManagementDialog(context);
    return null;
  }
}
