import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../dialogs/user_dialogs.dart';

/// Maaş merkezi: maaş ödemeleri, aylık primler ve krediler.
class PayrollTab extends StatefulWidget {
  /// Sayfa anahtarı: 'settings', 'help' ...
  final void Function(String route)? onNavigate;

  const PayrollTab({super.key, this.onNavigate});

  @override
  State<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<PayrollTab> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final employees = bank.payableEmployees.where((u) => u.isActive).toList();
    final due = employees.where((u) => !u.salaryDate.isAfter(now)).toList();
    final upcoming = employees.where((u) => u.salaryDate.isAfter(now)).toList()
      ..sort((a, b) => a.salaryDate.compareTo(b.salaryDate));
    final monthStart = DateTime(now.year, now.month, 1);
    final paidThisMonth = bank.transactions
        .where((t) =>
            t.type == TxnType.salary && t.date.isAfter(monthStart))
        .fold<double>(0, (a, t) => a + t.amount);
    final taxThisMonth = bank.transactions
        .where((t) => t.type == TxnType.tax && t.date.isAfter(monthStart))
        .fold<double>(0, (a, t) => a + t.amount);
    final dueTotal = due.fold<double>(0, (a, u) => a + u.salary);

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
                            Text('Maaş Merkezi',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              'Maaş günü: her ayın ${bank.settings.salaryDay}. günü • '
                              'otomatik ödeme ${bank.settings.autoPayroll ? 'açık' : 'kapalı'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      PillBadge(
                        label: '${due.length} vadesi gelen',
                        color: due.isEmpty
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: due.isEmpty
                            ? null
                            : () {
                                showConfirmDialog(
                                  context,
                                  title: '${due.length} maaş ödemesi yapılsın mı?',
                                  message:
                                      'Toplam ${bank.money(dueTotal)} şirket bakiyelerinden düşülecek.',
                                  icon: Icons.payments_outlined,
                                  confirmText: 'Öde',
                                  onConfirm: () {
                                    final n = bank.processDueSalaries();
                                    showSnackBar(
                                      context,
                                      n > 0
                                          ? '$n çalışana maaş ödendi.'
                                          : 'Ödeme yapılamadı (bakiye yetersiz olabilir).',
                                      success: n > 0,
                                    );
                                  },
                                );
                              },
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(
                          due.isEmpty
                              ? 'Vadesi gelen maaş yok'
                              : 'Vadesi Gelenleri Öde (${due.length})',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final n = bank.payMonthlyBonuses();
                          showSnackBar(
                            context,
                            n > 0
                                ? '$n çalışana aylık prim ödendi.'
                                : 'Ödenecek prim bulunmuyor.',
                            success: n > 0,
                          );
                        },
                        icon: const Icon(Icons.card_giftcard, size: 18),
                        label: const Text('Aylık Primleri Öde'),
                      ),
                      OutlinedButton.icon(
                        onPressed: bank.settings.loansEnabled
                            ? () => _newLoan(context, bank)
                            : null,
                        icon: const Icon(Icons.request_quote_outlined, size: 18),
                        label: const Text('Kredi Ver'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onNavigate?.call('settings'),
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Maaş Kuralları'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          WrapGrid(
            minItemWidth: 240,
            maxColumns: 4,
            children: [
              StatCard(
                title: 'Aylık Maaş Yükü',
                value: '',
                numericValue: bank.totalMonthlySalaries,
                icon: Icons.payments_outlined,
                subtitle: '${employees.length} ödenebilir hesap',
              ),
              StatCard(
                title: 'Bu Ay Ödenen',
                value: '',
                numericValue: paidThisMonth,
                icon: Icons.check_circle_outline,
                color: const Color(0xFF22C55E),
              ),
              StatCard(
                title: 'Vadesi Gelen',
                value: '',
                numericValue: dueTotal,
                icon: Icons.schedule,
                color: const Color(0xFFF59E0B),
                subtitle: '${due.length} çalışan',
              ),
              StatCard(
                title: 'Bu Ay Vergi',
                value: '',
                numericValue: taxThisMonth,
                icon: Icons.percent,
                color: const Color(0xFF8B5CF6),
                subtitle: bank.settings.taxEnabled
                    ? 'oran %${bank.settings.taxPercent.toStringAsFixed(0)}'
                    : 'vergi kapalı',
              ),
              StatCard(
                title: 'Aylık Prim Yükü',
                value: '',
                numericValue: bank.totalMonthlyBonuses,
                icon: Icons.card_giftcard,
                color: const Color(0xFF06B6D4),
              ),
              StatCard(
                title: 'Aktif Kredi Borcu',
                value: '',
                numericValue: bank.totalLoanRemaining,
                icon: Icons.request_quote_outlined,
                color: const Color(0xFFE11D48),
                subtitle: '${bank.activeLoanCount} kredi',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('Maaş Ödemeleri (${employees.length})'),
                icon: const Icon(Icons.payments_outlined, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Aylık Primler (${employees.where((u) => u.bonus > 0).length})'),
                icon: const Icon(Icons.card_giftcard, size: 16),
              ),
              ButtonSegment(
                value: 2,
                label: Text('Krediler (${bank.loans.length})'),
                icon: const Icon(Icons.request_quote_outlined, size: 16),
              ),
            ],
            selected: {_section},
            onSelectionChanged: (v) => setState(() => _section = v.first),
          ),
          const SizedBox(height: 16),
          if (_section == 0)
            _payrollList(context, bank, due, upcoming)
          else if (_section == 1)
            _bonusList(context, bank, employees)
          else
            _loanList(context, bank),
        ],
      ),
    );
  }

  Widget _payrollList(
    BuildContext context,
    BankProvider bank,
    List<AppUser> due,
    List<AppUser> upcoming,
  ) {
    if (due.isEmpty && upcoming.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'Ödenecek çalışan yok',
          message:
              'Şirketlere aktif çalışan ekleyin. Maaş ödemeleri burada listelenir.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (due.isNotEmpty) ...[
          const SectionHeader(
            title: 'Vadesi gelen ödemeler',
            subtitle: 'Maaş günü gelmiş çalışanlar',
            icon: Icons.schedule,
          ),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final u in due)
                  _payrollRow(context, bank, u, isDue: true),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (upcoming.isNotEmpty) ...[
          const SectionHeader(
            title: 'Planlanan ödemeler',
            subtitle: 'Maaş günü henüz gelmemiş çalışanlar',
            icon: Icons.event_available_outlined,
          ),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final u in upcoming.take(40))
                  _payrollRow(context, bank, u, isDue: false),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _payrollRow(
    BuildContext context,
    BankProvider bank,
    AppUser u, {
    required bool isDue,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final company = bank.companyById(u.companyId);
    final tax = bank.settings.taxEnabled
        ? u.salary * (bank.settings.taxPercent / 100)
        : 0.0;
    final enough = (company?.balance ?? 0) >= u.salary;
    final daysLeft = u.salaryDate.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AvatarBubble(
            name: u.fullName,
            colorValue: u.avatarColor,
            radius: 17,
            showStatus: true,
            isActive: u.isActive,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${company?.name ?? 'bağımsız'} • ${u.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 900)
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(bank.money(u.salary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5)),
                  if (tax > 0)
                    Text('vergi -${bank.money(tax)}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          const SizedBox(width: 10),
          PillBadge(
            label: isDue ? 'vadesi geldi' : '$daysLeft gün sonra',
            color: isDue ? const Color(0xFFF59E0B) : scheme.primary,
            dense: true,
          ),
          const SizedBox(width: 8),
          if (!enough)
            Tooltip(
              message: '${company?.name ?? 'Şirket'} bakiyesi yetersiz',
              child: const Icon(Icons.error_outline,
                  size: 17, color: Color(0xFFEF4444)),
            ),
          IconButton(
            tooltip: 'Maaşı öde',
            icon: const Icon(Icons.payments_outlined, size: 18),
            onPressed: enough ? () => showPaySalaryDialog(context, u) : null,
          ),
          IconButton(
            tooltip: 'Kullanıcıyı düzenle',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => showUserEditor(context, user: u),
          ),
        ],
      ),
    );
  }

  Widget _bonusList(
    BuildContext context,
    BankProvider bank,
    List<AppUser> employees,
  ) {
    final withBonus = employees.where((u) => u.bonus > 0).toList()
      ..sort((a, b) => b.bonus.compareTo(a.bonus));
    final withoutBonus = employees.where((u) => u.bonus <= 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tanımlı aylık primler',
          subtitle:
              'Toplam ${bank.money(bank.totalMonthlyBonuses)} • ödeme yapıldığında çalışan bakiyesine eklenir',
          icon: Icons.card_giftcard,
          action: TextButton.icon(
            onPressed: () => showBulkActionsDialog(context, employees),
            icon: const Icon(Icons.bolt_outlined, size: 17),
            label: const Text('Toplu İşlem'),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: withBonus.isEmpty
              ? const EmptyState(
                  icon: Icons.card_giftcard,
                  title: 'Tanımlı prim yok',
                  message:
                      'Çalışan kartından veya toplu işlemler menüsünden aylık prim tanımlayabilirsiniz.',
                )
              : Column(
                  children: [
                    for (final u in withBonus)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            AvatarBubble(
                                name: u.fullName,
                                colorValue: u.avatarColor,
                                radius: 17),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${bank.companyById(u.companyId)?.name ?? 'bağımsız'} • ${u.title}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(bank.money(u.bonus),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF10B981))),
                            IconButton(
                              tooltip: 'Prim tutarını değiştir',
                              icon: const Icon(Icons.tune, size: 18),
                              onPressed: () async {
                                final value = await showAmountDialog(
                                  context,
                                  title: '${u.fullName} • Aylık Prim',
                                  label: 'Aylık prim tutarı',
                                  currency: bank.currency,
                                  initial: u.bonus,
                                  description:
                                      'Bu tutar "Aylık Primleri Öde" ile otomatik ödenir.',
                                );
                                if (value == null) return;
                                bank.setMonthlyBonus(u.id, value);
                                if (!context.mounted) return;
                                showSnackBar(context, 'Aylık prim güncellendi.');
                              },
                            ),
                            IconButton(
                              tooltip: 'Primi kaldır',
                              icon: const Icon(Icons.close, size: 17),
                              onPressed: () {
                                bank.setMonthlyBonus(u.id, 0);
                                showSnackBar(context, 'Aylık prim kaldırıldı.');
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        if (withoutBonus.isNotEmpty) ...[
          SectionHeader(
            title: 'Prim tanımlanmamış çalışanlar (${withoutBonus.length})',
            subtitle: 'Tek tıkla varsayılan prim tutarını uygulayın',
            icon: Icons.person_add_alt_1,
            action: FilledButton.tonalIcon(
              onPressed: () {
                bank.bulkSetMonthlyBonus(
                  withoutBonus.map((u) => u.id).toList(),
                  bank.settings.defaultBonusAmount,
                );
                showSnackBar(
                  context,
                  '${withoutBonus.length} çalışana ${bank.money(bank.settings.defaultBonusAmount)} aylık prim tanımlandı.',
                );
              },
              icon: const Icon(Icons.flash_on, size: 17),
              label: Text(
                  'Varsayılanı uygula (${bank.money(bank.settings.defaultBonusAmount, compact: true)})'),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in withoutBonus.take(40))
                Chip(
                  avatar: AvatarBubble(
                      name: u.fullName, colorValue: u.avatarColor, radius: 11),
                  label: Text(u.fullName),
                  onDeleted: () {
                    bank.setMonthlyBonus(u.id, bank.settings.defaultBonusAmount);
                    showSnackBar(context,
                        '${u.fullName} için prim tanımlandı.');
                  },
                  deleteIcon: const Icon(Icons.add, size: 15),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _loanList(BuildContext context, BankProvider bank) {
    if (!bank.settings.loansEnabled) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.block,
          title: 'Kredi sistemi kapalı',
          message:
              'Ayarlar > Kredi bölümünden kredi sistemini açabilirsiniz.',
        ),
      );
    }
    if (bank.loans.isEmpty) {
      return AppCard(
        child: EmptyState(
          icon: Icons.request_quote_outlined,
          title: 'Kredi kaydı yok',
          message:
              'Çalışanlara taksitli kredi veya avans verebilirsiniz. Taksitler maaş ödemeleriyle birlikte tahsil edilir.',
          action: FilledButton.icon(
            onPressed: () => _newLoan(context, bank),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Kredi Ver'),
          ),
        ),
      );
    }

    final active = bank.loans.where((l) => !l.isFinished).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final finished = bank.loans.where((l) => l.isFinished).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Kredi portföyü',
          subtitle:
              '${active.length} aktif • toplam kalan ${bank.money(bank.totalLoanRemaining)}',
          icon: Icons.request_quote_outlined,
          action: FilledButton.tonalIcon(
            onPressed: () {
              final n = bank.payDueLoanInstallments();
              showSnackBar(
                context,
                n > 0
                    ? '$n taksit tahsil edildi.'
                    : 'Tahsil edilebilecek taksit bulunamadı.',
                success: n > 0,
              );
            },
            icon: const Icon(Icons.playlist_add_check, size: 17),
            label: const Text('Vadesi Gelen Taksitleri Tahsil Et'),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (final loan in [...active, ...finished])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ProgressRing(
                        value: loan.progress,
                        size: 52,
                        thickness: 6,
                        color: loan.isFinished
                            ? const Color(0xFF22C55E)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.userById(loan.userId)?.fullName ??
                                  'Silinmiş kullanıcı',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bank.money(loan.principal)} kredi • '
                              '${loan.paidInstallments}/${loan.totalInstallments} taksit • '
                              'kalan ${bank.money(loan.remaining)}',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            MiniProgress(
                              value: loan.progress,
                              color: loan.isFinished
                                  ? const Color(0xFF22C55E)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PillBadge(
                            label: loan.isFinished
                                ? 'Tamamlandı'
                                : 'Taksit ${bank.money(loan.installmentAmount, compact: true)}',
                            color: loan.isFinished
                                ? const Color(0xFF22C55E)
                                : Theme.of(context).colorScheme.primary,
                            dense: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loan.isFinished
                                ? 'son ödeme ${Fmt.date(loan.nextDueDate)}'
                                : 'sonraki vade ${Fmt.date(loan.nextDueDate)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Taksit tahsil et',
                        icon: const Icon(Icons.price_check, size: 19),
                        onPressed: loan.isFinished
                            ? null
                            : () {
                                try {
                                  final amount =
                                      bank.payLoanInstallment(loan.id);
                                  showSnackBar(context,
                                      '${bank.money(amount)} tahsil edildi.');
                                } catch (e) {
                                  showError(context, e);
                                }
                              },
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Kredi işlemleri',
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'close') {
                            bank.closeLoan(loan.id);
                            showSnackBar(context, 'Kredi kapatıldı.');
                          } else if (value == 'delete') {
                            showConfirmDialog(
                              context,
                              title: 'Kredi kaydı silinsin mi?',
                              message:
                                  'Kayıt silinir ancak yapılmış taksit ödemeleri işlem geçmişinde kalır.',
                              icon: Icons.delete_outline,
                              danger: true,
                              confirmText: 'Sil',
                              onConfirm: () {
                                bank.deleteLoan(loan.id);
                                showSnackBar(context, 'Kredi kaydı silindi.');
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'close', child: Text('Krediyi kapat')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Kaydı sil')),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _newLoan(BuildContext context, BankProvider bank) async {
    final candidates = bank.users
        .where((u) => u.role != UserRole.superAdmin && u.isActive)
        .toList();
    if (candidates.isEmpty) {
      showSnackBar(context, 'Kredi verilebilecek kullanıcı bulunmuyor.',
          error: true);
      return;
    }
    final user = await showUserPickerDialog(
      context,
      users: candidates,
      title: 'Kredi Verilecek Çalışan',
      subtitle: 'Maaşın en fazla '
          '${bank.settings.loanMaxSalaryMultiplier.toStringAsFixed(0)} katı kadar kredi verilebilir.',
      currency: bank.currency,
    );
    if (user == null || !context.mounted) return;
    await showLoanDialog(context, user);
  }
}
