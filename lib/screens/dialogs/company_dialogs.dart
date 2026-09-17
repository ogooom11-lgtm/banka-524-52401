import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';
import 'user_dialogs.dart';

/// Şirket oluşturma / düzenleme. Kaydedilirse true döner.
Future<bool> showCompanyEditor(
  BuildContext context, {
  Company? company,
}) async {
  final bank = context.read<BankProvider>();
  final result = await showAppDialog<bool>(
    context,
    title: company == null ? 'Yeni Şirket' : 'Şirketi Düzenle',
    subtitle: company == null
        ? 'Şirket oluşturulduğunda banka tarafından başlangıç kredisi yüklenebilir.'
        : 'Şirket bilgilerini, maaş sınırlarını ve durumunu değiştirebilirsiniz.',
    icon: company == null ? Icons.add_business_outlined : Icons.edit_outlined,
    maxWidth: 700,
    child: _CompanyEditorForm(company: company, bank: bank),
  );
  return result ?? false;
}

class _CompanyEditorForm extends StatefulWidget {
  final Company? company;
  final BankProvider bank;

  const _CompanyEditorForm({required this.company, required this.bank});

  @override
  State<_CompanyEditorForm> createState() => _CompanyEditorFormState();
}

class _CompanyEditorFormState extends State<_CompanyEditorForm> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _limit;
  late final TextEditingController _min;
  late final TextEditingController _sector;
  late final TextEditingController _tax;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  late int _color;
  late bool _isActive;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _name = TextEditingController(text: c?.name ?? '');
    _balance = TextEditingController(
        text: _numText(c?.balance ?? 0));
    _limit = TextEditingController(
        text: _numText(c?.salaryLimit ?? widget.bank.settings.defaultSalaryLimit));
    _min = TextEditingController(text: _numText(c?.salaryMin ?? 0));
    _sector = TextEditingController(text: c?.sector ?? '');
    _tax = TextEditingController(text: c?.taxNumber ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _email = TextEditingController(text: c?.contactEmail ?? '');
    _phone = TextEditingController(text: c?.contactPhone ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _color = c?.colorValue ?? 0xFF4F5BD5;
    _isActive = c?.isActive ?? true;
  }

  static String _numText(double v) =>
      v == 0 ? '' : v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  void dispose() {
    for (final c in [
      _name,
      _balance,
      _limit,
      _min,
      _sector,
      _tax,
      _address,
      _email,
      _phone,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) => Fmt.parseAmount(c.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    final limit = _v(_limit);
    final minSalary = _v(_min);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!),
            ),
          DialogSection(
            title: 'Şirket Bilgileri',
            icon: Icons.business_outlined,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.company == null,
                decoration: const InputDecoration(
                  labelText: 'Şirket adı *',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  TextField(
                    controller: _sector,
                    decoration: const InputDecoration(
                      labelText: 'Sektör',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  TextField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'Vergi numarası',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'İletişim e-postası',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'İletişim telefonu',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
          DialogSection(
            title: 'Finansal Bilgiler',
            icon: Icons.savings_outlined,
            description: widget.company == null
                ? 'Başlangıç bakiyesi girilirse banka bu tutarı şirkete kredi olarak yükler.'
                : 'Bakiye değişikliği için kart üzerindeki "Bakiye İşlemi" düğmesini kullanın.',
            children: [
              if (widget.company == null) ...[
                NumberField(
                  controller: _balance,
                  label: 'Başlangıç bakiyesi',
                  icon: Icons.account_balance_wallet_outlined,
                  suffix: bank.currency,
                ),
                const SizedBox(height: 12),
              ],
              FormRow(
                children: [
                  NumberField(
                    controller: _limit,
                    label: 'Maaş üst sınırı',
                    icon: Icons.arrow_upward,
                    suffix: bank.currency,
                    onChanged: (_) => setState(() {}),
                    errorText: limit <= 0 ? 'Sıfırdan büyük olmalı' : null,
                  ),
                  NumberField(
                    controller: _min,
                    label: 'Maaş alt sınırı (0 = %50)',
                    icon: Icons.arrow_downward,
                    suffix: bank.currency,
                    errorText: minSalary > limit ? 'Üst sınırı aşamaz' : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TXT/CSV içe aktarmada maaşlar '
                        '${Fmt.money(minSalary > 0 ? minSalary : limit * 0.5, bank.currency)} - '
                        '${Fmt.money(limit, bank.currency)} aralığında otomatik dağıtılır.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          DialogSection(
            title: 'Görünüm & Durum',
            icon: Icons.palette_outlined,
            children: [
              ColorChoiceRow(
                selected: _color,
                onChanged: (c) => setState(() => _color = c),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Şirket aktif'),
                subtitle: Text(_isActive
                    ? 'Ödeme ve prim işlemleri açık'
                    : 'Pasif şirkete kredi/prim verilmez'),
                contentPadding: EdgeInsets.zero,
              ),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    final bank = widget.bank;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Şirket adı boş bırakılamaz.');
      return;
    }
    final limit = _v(_limit);
    if (limit <= 0) {
      setState(() => _error = 'Maaş üst sınırı sıfırdan büyük olmalıdır.');
      return;
    }
    if (_v(_min) > limit) {
      setState(() => _error = 'Alt maaş sınırı üst sınırı aşamaz.');
      return;
    }

    try {
      if (widget.company == null) {
        bank.addCompany(
          name,
          _v(_balance),
          salaryLimit: limit,
          salaryMin: _v(_min),
          sector: _sector.text,
          taxNumber: _tax.text,
          address: _address.text,
          contactEmail: _email.text,
          contactPhone: _phone.text,
          colorValue: _color,
          notes: _notes.text,
          isActive: _isActive,
        );
      } else {
        bank.updateCompany(
          id: widget.company!.id,
          name: name,
          salaryLimit: limit,
          salaryMin: _v(_min),
          sector: _sector.text,
          taxNumber: _tax.text,
          address: _address.text,
          contactEmail: _email.text,
          contactPhone: _phone.text,
          colorValue: _color,
          isActive: _isActive,
          notes: _notes.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }
}

/// Şirket bakiyesi işlemi (yükle / düş / belirle).
Future<void> showCompanyBalanceDialog(
    BuildContext context, Company company) async {
  final bank = context.read<BankProvider>();
  final amount = TextEditingController();
  final reason = TextEditingController();
  var mode = 0;
  String? error;

  await showAppDialog<void>(
    context,
    title: '${company.name} • Bakiye İşlemi',
    subtitle: 'Mevcut bakiye: ${bank.money(company.balance)}',
    icon: Icons.account_balance_wallet_outlined,
    maxWidth: 500,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Yükle (+)'),
                  icon: Icon(Icons.add, size: 16)),
              ButtonSegment(
                  value: 1,
                  label: Text('Düş (-)'),
                  icon: Icon(Icons.remove, size: 16)),
              ButtonSegment(
                  value: 2,
                  label: Text('Belirle'),
                  icon: Icon(Icons.tune, size: 16)),
            ],
            selected: {mode},
            onSelectionChanged: (v) => setState(() => mode = v.first),
          ),
          const SizedBox(height: 16),
          NumberField(
            controller: amount,
            label: mode == 0
                ? 'Yüklenecek tutar'
                : mode == 1
                    ? 'Düşülecek tutar'
                    : 'Yeni bakiye',
            icon: Icons.attach_money,
            suffix: bank.currency,
            autofocus: true,
            errorText: error,
            onChanged: (_) => setState(() => error = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'İşlem açıklaması (opsiyonel)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final v in [50000.0, 100000.0, 250000.0, 500000.0])
                ActionChip(
                  label: Text('+${Fmt.number(v, digits: 0)}'),
                  onPressed: () => setState(() {
                    mode = 0;
                    amount.text = v.toStringAsFixed(0);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final value = Fmt.parseAmount(amount.text);
                  if (value == null || value < 0) {
                    setState(() => error = 'Geçerli bir tutar girin.');
                    return;
                  }
                  try {
                    if (mode == 0) {
                      bank.depositToCompany(company.id, value, reason.text);
                    } else if (mode == 1) {
                      bank.withdrawFromCompany(company.id, value, reason.text);
                    } else {
                      bank.updateCompanyBalance(company.id, value, reason.text);
                    }
                    Navigator.pop(ctx);
                    showSnackBar(context, '${company.name} bakiyesi güncellendi.');
                  } catch (e) {
                    setState(
                        () => error = e.toString().replaceAll('Exception: ', ''));
                  }
                },
                child: const Text('Uygula'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Şirket tehlikeli işlemler menüsü.
Future<void> showCompanyDangerZone(
    BuildContext context, Company company) async {
  final bank = context.read<BankProvider>();
  final stats = bank.companyStats(company.id);

  final action = await showAppDialog<String>(
    context,
    title: '${company.name} • İşlemler',
    subtitle: '${stats.employees} çalışan • aylık maaş yükü ${bank.money(stats.monthlySalaries)}',
    icon: Icons.settings_suggest_outlined,
    maxWidth: 560,
    child: Column(
      children: [
        for (final item in [
          (
            'redistribute',
            'Maaşları Yeniden Dağıt',
            'Çalışan maaşlarını limit aralığında rastgele dağıtır',
            Icons.shuffle,
            const Color(0xFF8B5CF6)
          ),
          (
            'bonus',
            'Tüm Çalışanlara Prim',
            'Şirket bakiyesinden herkese eşit prim öde',
            Icons.card_giftcard,
            const Color(0xFF10B981)
          ),
          (
            'deactivate',
            'Şirketi Pasife Al',
            'Pasif şirkete ödeme yapılmaz',
            Icons.pause_circle_outline,
            const Color(0xFFF59E0B)
          ),
          (
            'delete',
            'Şirketi Sil',
            'Şirket kaydı silinir, çalışanlar şirketsiz kalır',
            Icons.delete_outline,
            const Color(0xFFEF4444)
          ),
        ])
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: item.$5.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.$4, color: item.$5, size: 18),
            ),
            title: Text(item.$2),
            subtitle: Text(item.$3),
            onTap: () => Navigator.pop(context, item.$1),
          ),
      ],
    ),
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case 'redistribute':
      final result = bank.redistributeSalaries(company.id);
      showSnackBar(context, '${result.affected} çalışanın maaşı yeniden dağıtıldı.');
      break;
    case 'bonus':
      await showBonusDialog(context, targets: const [], companyWide: true, companyId: company.id);
      break;
    case 'deactivate':
      bank.setCompanyActive(company.id, false);
      showSnackBar(context, '${company.name} pasife alındı.');
      break;
    case 'delete':
      if (!context.mounted) return;
      final purge = await showAppDialog<bool>(
        context,
        title: '${company.name} silinsin mi?',
        subtitle: 'Bu işlem geri alınabilir (Geri Al ile).',
        icon: Icons.delete_forever_outlined,
        accent: const Color(0xFFEF4444),
        maxWidth: 460,
        child: Column(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.link_off),
              title: const Text('Çalışanları koru'),
              subtitle: const Text('Çalışanlar şirketsiz (bağımsız) kalır'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.person_remove_outlined,
                  color: Color(0xFFEF4444)),
              title: const Text('Çalışanları da sil'),
              subtitle: const Text('Şirkete bağlı tüm kullanıcılar silinir'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (purge == null || !context.mounted) return;
      bank.deleteCompany(company.id, purgeUsers: purge);
      showSnackBar(context, '${company.name} silindi.');
      break;
  }
}

/// Ödeme: şirketten seçilen çalışana doğrudan ödeme.
Future<void> showCompanyPaymentDialog(
    BuildContext context, Company company) async {
  final bank = context.read<BankProvider>();
  final employees = bank.usersOfCompany(company.id);
  if (employees.isEmpty) {
    showSnackBar(context, 'Bu şirkette çalışan bulunmuyor.', error: true);
    return;
  }
  final user = await showUserPickerDialog(
    context,
    users: employees,
    title: 'Ödeme Yapılacak Çalışan',
    currency: bank.currency,
  );
  if (user == null || !context.mounted) return;

  final value = await showAmountDialog(
    context,
    title: '${user.fullName} • Ödeme',
    label: 'Ödenecek tutar',
    currency: bank.currency,
    description: '${company.name} bakiyesinden ödenir.',
    icon: Icons.payments_outlined,
  );
  if (value == null || !context.mounted) return;

  try {
    bank.payFromCompany(company.id, user.id, value, 'Şirket ödemesi');
    showSnackBar(context, '${bank.money(value)} ${user.fullName} hesabına aktarıldı.');
  } catch (e) {
    showError(context, e);
  }
}
