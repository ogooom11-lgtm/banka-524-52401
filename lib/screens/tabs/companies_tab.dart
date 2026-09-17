import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../dialogs/company_dialogs.dart';
import '../dialogs/user_dialogs.dart';

/// Şirket yönetimi: oluşturma, bakiye, prim, personel ve detaylar.
class CompaniesTab extends StatefulWidget {
  const CompaniesTab({super.key});

  @override
  State<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<CompaniesTab> {
  final _search = TextEditingController();
  bool _onlyActive = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final companies = bank.companies
        .where((c) =>
            query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.sector.toLowerCase().contains(query) ||
            c.taxNumber.contains(query))
        .where((c) => !_onlyActive || c.isActive)
        .toList();

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Şirketler',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${bank.companies.length} şirket • toplam bakiye ${bank.money(bank.totalCompanyBalance)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      SearchInput(
                        controller: _search,
                        width: 260,
                        hint: 'Şirket, sektör veya vergi no ara...',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(width: 10),
                      FilterChip(
                        label: const Text('Sadece aktif'),
                        selected: _onlyActive,
                        onSelected: (v) => setState(() => _onlyActive = v),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () async {
                          final saved = await showCompanyEditor(context);
                          if (saved && context.mounted) {
                            showSnackBar(context, 'Şirket oluşturuldu.');
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Yeni Şirket'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (companies.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.business_outlined,
                title: bank.companies.isEmpty
                    ? 'Henüz şirket yok'
                    : 'Eşleşen şirket bulunamadı',
                message: bank.companies.isEmpty
                    ? 'İlk şirketinizi oluşturun: adı, bakiye ve maaş sınırını belirleyin. Ardından personel ekleyebilirsiniz.'
                    : 'Arama kriterlerini değiştirmeyi deneyin.',
                action: bank.companies.isEmpty
                    ? FilledButton.icon(
                        onPressed: () => showCompanyEditor(context),
                        icon: const Icon(Icons.add_business_outlined, size: 18),
                        label: const Text('Yeni Şirket Oluştur'),
                      )
                    : null,
              ),
            )
          else
            WrapGrid(
              minItemWidth: 400,
              maxColumns: 3,
              children: [
                for (final c in companies) _companyCard(context, bank, c),
              ],
            ),
        ],
      ),
    );
  }

  Widget _companyCard(BuildContext context, BankProvider bank, Company c) {
    final scheme = Theme.of(context).colorScheme;
    final color = c.colorValue == 0 ? scheme.primary : Color(c.colorValue);
    final stats = bank.companyStats(c.id);
    final employees = bank.usersOfCompany(c.id);

    return AppCard(
      padding: const EdgeInsets.all(18),
      blurGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.9),
                      Color.lerp(color, Colors.black, 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      c.sector.isEmpty ? 'Sektör belirtilmemiş' : c.sector,
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PillBadge(
                label: c.isActive ? 'Aktif' : 'Pasif',
                color: c.isActive
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8),
                dense: true,
              ),
              PopupMenuButton<String>(
                tooltip: 'Şirket işlemleri',
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await showCompanyEditor(context, company: c);
                      break;
                    case 'detail':
                      _showCompanyDetail(context, bank, c);
                      break;
                    case 'toggle':
                      bank.setCompanyActive(c.id, !c.isActive);
                      if (!context.mounted) return;
                      showSnackBar(context,
                          c.isActive ? 'Şirket pasife alındı.' : 'Şirket aktifleştirildi.');
                      break;
                    case 'danger':
                      await showCompanyDangerZone(context, c);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'detail', child: Text('Detayları görüntüle')),
                  const PopupMenuItem(
                      value: 'edit', child: Text('Şirketi düzenle')),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(c.isActive ? 'Pasife al' : 'Aktifleştir')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'danger', child: Text('Diğer işlemler...')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Şirket Bakiyesi',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    AnimatedCounter(
                      value: c.balance,
                      digits: bank.decimalDigits,
                      currency: bank.currency,
                      symbolAfter: bank.symbolAfter,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.balance < stats.monthlySalaries
                            ? const Color(0xFFEF4444)
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: c.salaryLimit <= 0
                    ? 0.0
                    : (stats.monthlySalaries / (c.salaryLimit * 1.5))
                        .clamp(0.0, 1.0),
                size: 54,
                thickness: 6,
                color: color,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stats.activeEmployees}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    Text('kişi',
                        style: TextStyle(
                            fontSize: 8.5, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MiniProgress(
            value: stats.limitUsage,
            color: color,
            showLabel: true,
            label: 'Ortalama maaş / sınır doluluğu',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: KeyValueRow(
                  label: 'Aylık yük',
                  value: bank.money(stats.monthlySalaries, compact: true),
                  dense: true,
                  icon: Icons.payments_outlined,
                ),
              ),
              Expanded(
                child: KeyValueRow(
                  label: 'Maaş sınırı',
                  value: bank.money(c.salaryLimit, compact: true),
                  dense: true,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showCompanyBalanceDialog(context, c),
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 16),
                  label: const Text('Bakiye'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBonusDialog(
                    context,
                    targets: const [],
                    companyWide: true,
                    companyId: c.id,
                  ),
                  icon: const Icon(Icons.card_giftcard, size: 16),
                  label: const Text('Prim'),
                ),
              ),
              const SizedBox(width: 8),
              IconAction(
                icon: Icons.person_add_alt_1,
                tooltip: 'Bu şirkete kullanıcı ekle',
                onPressed: () =>
                    showUserEditor(context, initialCompanyId: c.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (employees.isEmpty)
            Text(
              'Bu şirkete henüz çalışan eklenmedi.',
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final u in employees.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        AvatarBubble(
                            name: u.fullName,
                            colorValue: u.avatarColor,
                            radius: 13),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            u.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          bank.money(u.salary, compact: true),
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                if (employees.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: () => _showCompanyDetail(context, bank, c),
                      child: Text(
                        '+${employees.length - 4} çalışan daha → tümünü gör',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCompanyDetail(
      BuildContext context, BankProvider bank, Company company) {
    showAppDialog<void>(
      context,
      title: company.name,
      subtitle:
          '${company.sector.isEmpty ? 'Sektör yok' : company.sector} • kuruluş ${Fmt.date(company.createdAt)}',
      icon: Icons.business_outlined,
      accent: company.colorValue == 0
          ? Theme.of(context).colorScheme.primary
          : Color(company.colorValue),
      maxWidth: 860,
      scrollable: false,
      child: _CompanyDetailBody(company: company, bank: bank),
    );
  }
}

class _CompanyDetailBody extends StatefulWidget {
  final Company company;
  final BankProvider bank;

  const _CompanyDetailBody({required this.company, required this.bank});

  @override
  State<_CompanyDetailBody> createState() => _CompanyDetailBodyState();
}

class _CompanyDetailBodyState extends State<_CompanyDetailBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    final company = widget.company;
    final scheme = Theme.of(context).colorScheme;
    final employees = bank.usersOfCompany(company.id);
    final txns = bank.txnsOfCompany(company.id);
    final stats = bank.companyStats(company.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Genel'),
                  icon: Icon(Icons.info_outline, size: 15)),
              ButtonSegment(
                  value: 1,
                  label: Text('Çalışanlar'),
                  icon: Icon(Icons.people_outline, size: 15)),
              ButtonSegment(
                  value: 2,
                  label: Text('İşlemler'),
                  icon: Icon(Icons.receipt_long_outlined, size: 15)),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
          const SizedBox(height: 18),
          if (_tab == 0) ...[
            Row(
              children: [
                Expanded(
                  child: DonutChart(
                    size: 150,
                    thickness: 18,
                    centerTitle: 'Sınır doluluğu',
                    centerValue: Fmt.percent(stats.limitUsage * 100, digits: 0),
                    slices: [
                      DonutSlice(
                        label: 'ortalama maaş',
                        value: stats.averageSalary,
                        color: scheme.primary,
                      ),
                      DonutSlice(
                        label: 'boşluk',
                        value: (company.salaryLimit - stats.averageSalary)
                            .clamp(0, double.infinity)
                            .toDouble(),
                        color: scheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      KeyValueRow(
                          label: 'Bakiye',
                          value: bank.money(company.balance),
                          icon: Icons.account_balance_wallet_outlined),
                      KeyValueRow(
                          label: 'Vergi numarası',
                          value: company.taxNumber.isEmpty
                              ? '-'
                              : company.taxNumber,
                          icon: Icons.receipt_outlined),
                      KeyValueRow(
                          label: 'İletişim',
                          value: company.contactEmail.isEmpty
                              ? '-'
                              : company.contactEmail,
                          icon: Icons.alternate_email),
                      KeyValueRow(
                          label: 'Telefon',
                          value:
                              company.contactPhone.isEmpty ? '-' : company.contactPhone,
                          icon: Icons.phone_outlined),
                      KeyValueRow(
                          label: 'Adres',
                          value: company.address.isEmpty ? '-' : company.address,
                          icon: Icons.location_on_outlined),
                      KeyValueRow(
                          label: 'Maaş sınırı',
                          value:
                              '${bank.money(company.effectiveSalaryMin)} - ${bank.money(company.salaryLimit)}',
                          icon: Icons.tune),
                      KeyValueRow(
                          label: 'Çalışan',
                          value:
                              '${stats.activeEmployees} aktif / ${stats.employees} toplam',
                          icon: Icons.people_outline),
                    ],
                  ),
                ),
              ],
            ),
            if (company.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(company.notes),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => showCompanyBalanceDialog(context, company),
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 17),
                  label: const Text('Bakiye İşlemi'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showCompanyPaymentDialog(context, company),
                  icon: const Icon(Icons.payments_outlined, size: 17),
                  label: const Text('Çalışana Ödeme'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showBonusDialog(
                    context,
                    targets: const [],
                    companyWide: true,
                    companyId: company.id,
                  ),
                  icon: const Icon(Icons.card_giftcard, size: 17),
                  label: const Text('Toplu Prim'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final result = bank.redistributeSalaries(company.id);
                    showSnackBar(context,
                        '${result.affected} çalışanın maaşı yeniden dağıtıldı.');
                  },
                  icon: const Icon(Icons.shuffle, size: 17),
                  label: const Text('Maaşları Dağıt'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await showCompanyEditor(context, company: company);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Düzenle'),
                ),
              ],
            ),
          ] else if (_tab == 1) ...[
            Row(
              children: [
                Text(
                  '${employees.length} kayıt',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      showUserEditor(context, initialCompanyId: company.id),
                  icon: const Icon(Icons.person_add_alt_1, size: 17),
                  label: const Text('Çalışan Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (employees.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                title: 'Çalışan yok',
                message: 'Bu şirkete henüz çalışan eklenmedi.',
              )
            else
              for (final u in employees)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AvatarBubble(
                    name: u.fullName,
                    colorValue: u.avatarColor,
                    radius: 17,
                    showStatus: true,
                    isActive: u.isActive,
                  ),
                  title: Text(u.fullName),
                  subtitle: Text(
                      '${u.title} • ${u.email} • sözleşme ${Fmt.date(u.contractEnd)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(bank.money(u.salary),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5)),
                          Text(bank.money(u.balance),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Düzenle',
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        onPressed: () => showUserEditor(context, user: u),
                      ),
                    ],
                  ),
                ),
          ] else ...[
            Row(
              children: [
                Text('${txns.length} hareket',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            if (txns.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'İşlem yok',
                message: 'Bu şirket için kayıtlı hareket bulunmuyor.',
              )
            else
              for (final t in txns.take(60))
                TxnListTile(
                  txn: t,
                  currency: bank.currency,
                  digits: bank.decimalDigits,
                  perspectiveId: company.id,
                ),
          ],
        ],
      ),
    );
  }
}
