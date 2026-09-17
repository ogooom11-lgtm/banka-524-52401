import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';

/// Kullanıcı oluşturma / tam düzenleme diyaloğu. Kaydedilirse true döner.
Future<bool> showUserEditor(
  BuildContext context, {
  AppUser? user,
  String? initialCompanyId,
}) async {
  final bank = context.read<BankProvider>();
  final result = await showAppDialog<bool>(
    context,
    title: user == null ? 'Yeni Kullanıcı' : 'Kullanıcıyı Düzenle',
    subtitle: user == null
        ? 'E-posta ve şifre boş bırakılırsa otomatik oluşturulur (varsayılan şifre: 123456).'
        : 'Tüm alanları değiştirebilirsiniz. Değişiklikler anında kaydedilir.',
    icon: user == null ? Icons.person_add_alt_1 : Icons.manage_accounts_outlined,
    maxWidth: 720,
    scrollable: false,
    child: _UserEditorForm(
      user: user,
      initialCompanyId: initialCompanyId,
      bank: bank,
    ),
  );
  return result ?? false;
}

class _UserEditorForm extends StatefulWidget {
  final AppUser? user;
  final String? initialCompanyId;
  final BankProvider bank;

  const _UserEditorForm({
    required this.user,
    required this.initialCompanyId,
    required this.bank,
  });

  @override
  State<_UserEditorForm> createState() => _UserEditorFormState();
}

class _UserEditorFormState extends State<_UserEditorForm> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _title;
  late final TextEditingController _department;
  late final TextEditingController _phone;
  late final TextEditingController _iban;
  late final TextEditingController _salary;
  late final TextEditingController _bonus;
  late final TextEditingController _balance;
  late final TextEditingController _termination;
  late final TextEditingController _notes;

  late UserRole _role;
  String? _companyId;
  late bool _isActive;
  late int _avatarColor;
  late DateTime _contractStart;
  late DateTime _contractEnd;
  late int _salaryDay;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _password = TextEditingController();
    _title = TextEditingController(text: u?.title ?? 'Çalışan');
    _department = TextEditingController(text: u?.department ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _iban = TextEditingController(text: u?.iban ?? '');
    _salary = TextEditingController(text: _numText(u?.salary ?? 0));
    _bonus = TextEditingController(text: _numText(u?.bonus ?? 0));
    _balance = TextEditingController(text: _numText(u?.balance ?? 0));
    _termination = TextEditingController(text: _numText(u?.terminationFee ?? 0));
    _notes = TextEditingController(text: u?.notes ?? '');
    _role = u?.role ?? UserRole.employee;
    _companyId = u?.companyId ?? widget.initialCompanyId;
    _isActive = u?.isActive ?? true;
    _avatarColor = u?.avatarColor ?? 0xFF4F5BD5;
    final now = DateTime.now();
    _contractStart = u?.contractStart ?? now;
    _contractEnd = u?.contractEnd ??
        now.add(Duration(days: widget.bank.settings.defaultContractMonths * 30));
    _salaryDay = u?.salaryDate.day ?? widget.bank.settings.salaryDay;
  }

  static String _numText(double v) =>
      v == 0 ? '' : v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _password,
      _title,
      _department,
      _phone,
      _iban,
      _salary,
      _bonus,
      _balance,
      _termination,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController c) => Fmt.parseAmount(c.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    final companies = bank.companies;
    final company = bank.companyById(_companyId);
    final limit = company?.salaryLimit ?? double.infinity;
    final salaryValue = _value(_salary);

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
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 17, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!)),
                ],
              ),
            ),
          DialogSection(
            title: 'Kimlik Bilgileri',
            icon: Icons.badge_outlined,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.user == null,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: widget.user == null ? 'otomatik üretilir' : null,
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                  ),
                  TextField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: widget.user == null
                          ? 'varsayılan: 123456'
                          : 'boş = değişmez',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  TextField(
                    controller: _iban,
                    decoration: const InputDecoration(
                      labelText: 'IBAN / Hesap No',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Rol', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.employee,
                    label: Text('Çalışan'),
                    icon: Icon(Icons.person_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: UserRole.companyAdmin,
                    label: Text('Şirket Yön.'),
                    icon: Icon(Icons.supervisor_account_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: UserRole.superAdmin,
                    label: Text('Süper Admin'),
                    icon: Icon(Icons.workspace_premium_outlined, size: 16),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (v) => setState(() => _role = v.first),
              ),
            ],
          ),
          DialogSection(
            title: 'İş Bilgileri',
            icon: Icons.work_outline,
            children: [
              FormRow(
                children: [
                  DropdownButtonFormField<String?>(
                    value: _companyId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Şirket',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Şirketsiz / Bağımsız'),
                      ),
                      for (final c in companies)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _companyId = v),
                  ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Unvan',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  TextField(
                    controller: _department,
                    decoration: const InputDecoration(
                      labelText: 'Departman',
                      prefixIcon: Icon(Icons.grid_view_outlined),
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    value: _salaryDay,
                    decoration: const InputDecoration(
                      labelText: 'Maaş günü (ayın günü)',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text('$d. gün')),
                    ],
                    onChanged: (v) => setState(() => _salaryDay = v ?? 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Hesap aktif'),
                subtitle: Text(
                  _isActive
                      ? 'Maaş ve prim ödemeleri yapılabilir'
                      : 'Pasif hesaplara ödeme yapılmaz',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          DialogSection(
            title: 'Ücret Bilgileri',
            icon: Icons.payments_outlined,
            description: company == null
                ? 'Şirket seçilmediği için maaş sınırı uygulanmaz.'
                : '${company.name} maaş sınırı: ${Fmt.money(company.salaryLimit, bank.currency, digits: bank.decimalDigits)}',
            children: [
              FormRow(
                children: [
                  NumberField(
                    controller: _salary,
                    label: 'Maaş',
                    icon: Icons.payments_outlined,
                    suffix: bank.currency,
                    onChanged: (_) => setState(() {}),
                    errorText: salaryValue > limit
                        ? 'Şirket maaş sınırı aşılıyor'
                        : null,
                  ),
                  NumberField(
                    controller: _bonus,
                    label: 'Aylık Prim',
                    icon: Icons.card_giftcard,
                    suffix: bank.currency,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FormRow(
                children: [
                  NumberField(
                    controller: _balance,
                    label: 'Bakiye',
                    icon: Icons.account_balance_wallet_outlined,
                    suffix: bank.currency,
                  ),
                  NumberField(
                    controller: _termination,
                    label: 'Fesih Ücreti',
                    icon: Icons.description_outlined,
                    suffix: bank.currency,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [1, 2, 3, 4])
                    ActionChip(
                      label: Text('Fesih = ${m}x maaş'),
                      onPressed: () => setState(() {
                        _termination.text = _numText(salaryValue * m);
                      }),
                    ),
                ],
              ),
            ],
          ),
          DialogSection(
            title: 'Sözleşme',
            icon: Icons.event_note_outlined,
            children: [
              FormRow(
                children: [
                  _DateField(
                    label: 'Başlangıç',
                    value: _contractStart,
                    onPick: (d) => setState(() => _contractStart = d),
                  ),
                  _DateField(
                    label: 'Bitiş',
                    value: _contractEnd,
                    onPick: (d) => setState(() => _contractEnd = d),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final months in [3, 6, 12, 24, 36])
                    ActionChip(
                      label: Text('+$months ay'),
                      onPressed: () => setState(() {
                        final base = _contractEnd.isAfter(DateTime.now())
                            ? _contractEnd
                            : DateTime.now();
                        _contractEnd =
                            base.add(Duration(days: months * 30));
                      }),
                    ),
                ],
              ),
            ],
          ),
          DialogSection(
            title: 'Görünüm & Notlar',
            icon: Icons.palette_outlined,
            children: [
              ColorChoiceRow(
                selected: _avatarColor,
                onChanged: (c) => setState(() => _avatarColor = c),
              ),
              const SizedBox(height: 14),
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
      setState(() => _error = 'Ad Soyad boş bırakılamaz.');
      return;
    }
    final salary = _value(_salary);
    final company = bank.companyById(_companyId);
    if (company != null && salary > company.salaryLimit) {
      setState(() => _error =
          '${company.name} maaş sınırı: ${Fmt.money(company.salaryLimit, bank.currency)}. Daha düşük bir maaş girin.');
      return;
    }
    if (_contractEnd.isBefore(_contractStart)) {
      setState(() => _error = 'Sözleşme bitiş tarihi başlangıçtan önce olamaz.');
      return;
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final salaryDate =
        DateTime(now.year, now.month, _salaryDay.clamp(1, daysInMonth));

    try {
      if (widget.user == null) {
        bank.addUser(
          fullName: name,
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
          role: _role,
          companyId: _companyId,
          title: _title.text.trim(),
          department: _department.text,
          phone: _phone.text,
          iban: _iban.text,
          salary: salary,
          bonus: _value(_bonus),
          balance: _value(_balance),
          salaryDate: salaryDate,
          contractStart: _contractStart,
          contractEnd: _contractEnd,
          terminationFee: _value(_termination),
          notes: _notes.text,
          avatarColor: _avatarColor,
          isActive: _isActive,
        );
      } else {
        bank.updateUserFields(
          widget.user!.id,
          fullName: name,
          email: _email.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
          role: _role,
          companyId: _companyId,
          title: _title.text.trim(),
          department: _department.text,
          phone: _phone.text,
          iban: _iban.text,
          salary: salary,
          bonus: _value(_bonus),
          balance: _value(_balance),
          salaryDate: salaryDate,
          contractStart: _contractStart,
          contractEnd: _contractEnd,
          terminationFee: _value(_termination),
          notes: _notes.text,
          avatarColor: _avatarColor,
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: label,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(Fmt.date(value)),
      ),
    );
  }
}

/// Maaş ödeme onayı.
Future<void> showPaySalaryDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  final company = bank.companyById(user.companyId);
  final tax = bank.settings.taxEnabled
      ? user.salary * (bank.settings.taxPercent / 100)
      : 0.0;

  await showAppDialog<void>(
    context,
    title: 'Maaş Ödemesi',
    subtitle: '${user.fullName} • ${company?.name ?? 'bağımsız'}',
    icon: Icons.payments_outlined,
    maxWidth: 460,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyValueRow(label: 'Brüt maaş', value: bank.money(user.salary)),
        if (tax > 0)
          KeyValueRow(
            label: 'Gelir vergisi (%${bank.settings.taxPercent.toStringAsFixed(0)})',
            value: '-${bank.money(tax)}',
            valueColor: const Color(0xFFEF4444),
          ),
        KeyValueRow(
          label: 'Çalışana geçecek',
          value: bank.money(user.salary - tax),
          valueColor: const Color(0xFF10B981),
        ),
        const Divider(height: 22),
        KeyValueRow(
          label: 'Şirket bakiyesi',
          value: bank.money(company?.balance ?? 0),
        ),
        const SizedBox(height: 8),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      FilledButton.icon(
        onPressed: () {
          try {
            bank.paySalary(user.id);
            Navigator.pop(context);
            showSnackBar(context, '${user.fullName} maaşı ödendi.');
          } catch (e) {
            showError(context, e);
          }
        },
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Öde'),
      ),
    ],
  );
}

/// Prim dağıtımı (tek veya toplu).
Future<bool> showBonusDialog(
  BuildContext context, {
  required List<AppUser> targets,
  bool companyWide = false,
  String? companyId,
}) async {
  if (targets.isEmpty && !companyWide) return false;
  final bank = context.read<BankProvider>();
  final controller = TextEditingController(
    text: bank.settings.defaultBonusAmount.toStringAsFixed(0),
  );
  final note = TextEditingController();
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: companyWide
        ? 'Toplu Prim Dağıt'
        : targets.length == 1
            ? 'Prim Öde'
            : '${targets.length} Kişiye Prim',
    subtitle: companyWide
        ? 'Şirketin tüm aktif çalışanlarına eşit tutarda prim dağıtılır.'
        : 'Seçilen çalışanlara aynı tutarda prim ödenir.',
    icon: Icons.card_giftcard,
    maxWidth: 480,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberField(
            controller: controller,
            label: 'Kişi başı prim',
            icon: Icons.attach_money,
            suffix: bank.currency,
            autofocus: true,
            errorText: error,
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Açıklama (opsiyonel)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final v in [1000.0, 2500.0, 5000.0, 10000.0])
                ActionChip(
                  label: Text(Fmt.number(v, digits: 0)),
                  onPressed: () => setState(
                      () => controller.text = v.toStringAsFixed(0)),
                ),
            ],
          ),
          if (targets.length > 1 && !companyWide)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Toplam: ${Fmt.money((Fmt.parseAmount(controller.text) ?? 0) * targets.length, bank.currency)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final amount = Fmt.parseAmount(controller.text);
                  if (amount == null || amount <= 0) {
                    setState(() => error = 'Geçerli bir tutar girin.');
                    return;
                  }
                  try {
                    if (companyWide && companyId != null) {
                      final n = bank.giveBonusToCompany(
                          companyId, amount, note.text);
                      Navigator.pop(ctx, true);
                      showSnackBar(
                          context, '$n çalışana prim dağıtıldı.');
                    } else if (targets.length == 1) {
                      bank.giveBonus(targets.first.id, amount, note.text);
                      Navigator.pop(ctx, true);
                      showSnackBar(context,
                          '${targets.first.fullName} kişisine prim ödendi.');
                    } else {
                      final result = bank.bulkBonus(
                        targets.map((u) => u.id).toList(),
                        amount,
                        note.text,
                      );
                      Navigator.pop(ctx, true);
                      showSnackBar(context, result.summary);
                    }
                  } catch (e) {
                    setState(
                        () => error = e.toString().replaceAll('Exception: ', ''));
                  }
                },
                child: const Text('Dağıt'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

/// Ceza uygulama (sabit tutar veya maaş yüzdesi).
Future<bool> showPenaltyDialog(
  BuildContext context, {
  required List<AppUser> targets,
}) async {
  if (targets.isEmpty) return false;
  final bank = context.read<BankProvider>();
  final controller = TextEditingController(text: '500');
  final reason = TextEditingController();
  bool percentage = false;
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: targets.length == 1
        ? '${targets.first.fullName} • Ceza'
        : '${targets.length} Kişiye Ceza',
    subtitle: 'Ceza tutarı çalışan bakiyesinden düşülür ve şirkete aktarılır.',
    icon: Icons.gavel_outlined,
    accent: const Color(0xFFEF4444),
    maxWidth: 480,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Sabit tutar'),
                icon: Icon(Icons.payments_outlined, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text('Maaş yüzdesi'),
                icon: Icon(Icons.percent, size: 16),
              ),
            ],
            selected: {percentage},
            onSelectionChanged: (v) => setState(() {
              percentage = v.first;
              controller.text = percentage ? '5' : '500';
            }),
          ),
          const SizedBox(height: 14),
          NumberField(
            controller: controller,
            label: percentage ? 'Maaş yüzdesi (%)' : 'Ceza tutarı',
            icon: percentage ? Icons.percent : Icons.attach_money,
            suffix: percentage ? '%' : bank.currency,
            autofocus: true,
            allowDecimal: !percentage,
            errorText: error,
            helper: percentage
                ? 'Üst sınır: %${bank.settings.penaltyMaxPercent.toStringAsFixed(0)}'
                : null,
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Ceza gerekçesi',
              prefixIcon: Icon(Icons.report_outlined),
            ),
          ),
          if (targets.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Toplam ${targets.length} çalışana uygulanacak.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final amount = Fmt.parseAmount(controller.text);
                  if (amount == null || amount <= 0) {
                    setState(() => error = 'Geçerli bir değer girin.');
                    return;
                  }
                  try {
                    if (targets.length == 1) {
                      bank.applyPenalty(targets.first.id, amount, reason.text,
                          percentage: percentage);
                      Navigator.pop(ctx, true);
                      showSnackBar(context, 'Ceza uygulandı.');
                    } else {
                      final result = bank.bulkPenalty(
                        targets.map((u) => u.id).toList(),
                        amount,
                        reason.text,
                        percentage: percentage,
                      );
                      Navigator.pop(ctx, true);
                      showSnackBar(context, result.summary);
                    }
                  } catch (e) {
                    setState(
                        () => error = e.toString().replaceAll('Exception: ', ''));
                  }
                },
                child: const Text('Cezayı Uygula'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

/// Terfi / zam işlemi.
Future<bool> showPromoteDialog(
  BuildContext context, {
  required List<AppUser> targets,
}) async {
  if (targets.isEmpty) return false;
  final bank = context.read<BankProvider>();
  final single = targets.length == 1;
  final user = targets.first;
  final title = TextEditingController(text: single ? user.title : '');
  final salary = TextEditingController(
    text: single ? user.salary.toStringAsFixed(0) : '10',
  );
  final bonus = TextEditingController(text: '0');
  bool percentMode = !single;
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: single ? 'Terfi / Zam' : '${targets.length} Kişiye Terfi',
    subtitle: single
        ? '${user.fullName} • mevcut maaş ${bank.money(user.salary)}'
        : 'Tüm seçili çalışanlara aynı oranda zam uygulanır.',
    icon: Icons.trending_up,
    accent: const Color(0xFF10B981),
    maxWidth: 500,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: title,
            decoration: InputDecoration(
              labelText: single ? 'Yeni unvan' : 'Yeni unvan (boş = korunur)',
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
          if (single)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Yeni maaş'),
                    icon: Icon(Icons.payments_outlined, size: 16)),
                ButtonSegment(
                    value: true,
                    label: Text('Zam oranı %'),
                    icon: Icon(Icons.percent, size: 16)),
              ],
              selected: {percentMode},
              onSelectionChanged: (v) =>
                  setState(() => percentMode = v.first),
            ),
          if (single) const SizedBox(height: 14),
          NumberField(
            controller: salary,
            label: percentMode ? 'Zam oranı (%)' : 'Yeni maaş',
            icon: percentMode ? Icons.percent : Icons.attach_money,
            suffix: percentMode ? '%' : bank.currency,
            errorText: error,
            helper: percentMode && single
                ? 'Yeni maaş: ${bank.money(user.salary * (1 + (Fmt.parseAmount(salary.text) ?? 0) / 100))}'
                : null,
            onChanged: (_) => setState(() => error = null),
          ),
          const SizedBox(height: 12),
          NumberField(
            controller: bonus,
            label: 'Terfi primi (opsiyonel)',
            icon: Icons.card_giftcard,
            suffix: bank.currency,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final value = Fmt.parseAmount(salary.text) ?? 0;
                  final bonusValue = Fmt.parseAmount(bonus.text) ?? 0;
                  try {
                    if (single) {
                      final newSalary =
                          percentMode ? user.salary * (1 + value / 100) : value;
                      bank.promote(user.id, title.text, newSalary, bonusValue);
                      Navigator.pop(ctx, true);
                      showSnackBar(context,
                          '${user.fullName} terfi ettirildi → ${bank.money(newSalary)}');
                    } else {
                      final result = bank.bulkPromote(
                        targets.map((u) => u.id).toList(),
                        title.text,
                        value,
                        bonusValue,
                      );
                      Navigator.pop(ctx, true);
                      showSnackBar(context, result.summary);
                    }
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
  return saved ?? false;
}

/// Sözleşme yenileme.
Future<bool> showContractDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  final months = TextEditingController(
      text: bank.settings.defaultContractMonths.toString());
  final fee = TextEditingController(
      text: (user.salary * bank.settings.defaultTerminationMultiplier)
          .toStringAsFixed(0));
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: 'Sözleşme İşlemleri',
    subtitle: '${user.fullName} • bitiş: ${Fmt.date(user.contractEnd)}',
    icon: Icons.event_note_outlined,
    maxWidth: 500,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyValueRow(
            label: 'Kalan süre',
            value: user.isContractExpired
                ? 'Süresi dolmuş'
                : Fmt.duration(user.contractDaysLeft),
            valueColor: user.isContractExpired
                ? const Color(0xFFEF4444)
                : null,
          ),
          KeyValueRow(
            label: 'Mevcut fesih ücreti',
            value: bank.money(user.terminationFee),
          ),
          const Divider(height: 22),
          FormRow(
            children: [
              NumberField(
                controller: months,
                label: 'Uzatılacak süre (ay)',
                icon: Icons.timelapse,
                allowDecimal: false,
                errorText: error,
              ),
              NumberField(
                controller: fee,
                label: 'Yeni fesih ücreti',
                icon: Icons.description_outlined,
                suffix: bank.currency,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final m in [1, 2, 3])
                ActionChip(
                  label: Text('Fesih = ${m}x maaş'),
                  onPressed: () => setState(() =>
                      fee.text = (user.salary * m).toStringAsFixed(0)),
                ),
              ActionChip(
                label: const Text('12 ay uzat'),
                onPressed: () => setState(() {
                  months.text = '12';
                  fee.text = (user.salary *
                          bank.settings.defaultTerminationMultiplier)
                      .toStringAsFixed(0);
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final m = Fmt.parseInt(months.text) ?? 0;
                  if (m <= 0) {
                    setState(() => error = 'En az 1 ay olmalıdır.');
                    return;
                  }
                  try {
                    bank.renewContract(
                        user.id, m, Fmt.parseAmount(fee.text) ?? 0);
                    Navigator.pop(ctx, true);
                    showSnackBar(context, 'Sözleşme güncellendi.');
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
  return saved ?? false;
}

/// Şirket transferi.
Future<bool> showTransferDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  String? targetId;
  bool chargeFee = true;
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: 'Şirket Transferi',
    subtitle: '${user.fullName} • şu an: ${bank.companyById(user.companyId)?.name ?? 'bağımsız'}',
    icon: Icons.swap_horiz,
    maxWidth: 520,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: targetId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Hedef şirket',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: [
              for (final c in bank.companies.where((c) => c.id != user.companyId))
                DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name} '
                      '(sınır ${Fmt.money(c.salaryLimit, bank.currency)})'),
                ),
            ],
            onChanged: (v) => setState(() => targetId = v),
          ),
          const SizedBox(height: 12),
          if (user.contractEnd.isAfter(DateTime.now()) && user.terminationFee > 0)
            SwitchListTile(
              value: chargeFee,
              onChanged: (v) => setState(() => chargeFee = v),
              title: const Text('Erken fesih ücretini uygula'),
              subtitle: Text(
                chargeFee
                    ? '${bank.money(user.terminationFee)} çalışan bakiyesinden kesilir'
                    : 'Ücret alınmaz',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          if (error != null)
            Text(error!,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  if (targetId == null) {
                    setState(() => error = 'Hedef şirket seçin.');
                    return;
                  }
                  try {
                    final target = bank.companyById(targetId);
                    if (target != null && user.salary > target.salaryLimit) {
                      setState(() => error =
                          'Maaş (${bank.money(user.salary)}) hedef şirketin sınırını aşıyor.');
                      return;
                    }
                    bank.transferEmployee(user.id, targetId!,
                        chargeTerminationFee: chargeFee);
                    Navigator.pop(ctx, true);
                    showSnackBar(context,
                        '${user.fullName} → ${target?.name ?? ''} transfer edildi.');
                  } catch (e) {
                    setState(
                        () => error = e.toString().replaceAll('Exception: ', ''));
                  }
                },
                child: const Text('Transfer Et'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

/// Kredi verme.
Future<bool> showLoanDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  final maxLoan = bank.maxLoanFor(user);
  final amount = TextEditingController(text: (maxLoan / 2).toStringAsFixed(0));
  final installments = TextEditingController(
      text: math.min(bank.settings.loanMaxInstallments, 12).toString());
  final note = TextEditingController();
  String? error;

  final saved = await showAppDialog<bool>(
    context,
    title: 'Kredi / Avans Ver',
    subtitle: '${user.fullName} • maaş ${bank.money(user.salary)}',
    icon: Icons.request_quote_outlined,
    maxWidth: 520,
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final amountValue = Fmt.parseAmount(amount.text) ?? 0;
        final installmentValue = Fmt.parseInt(installments.text) ?? 1;
        final total = amountValue * (1 + bank.settings.loanInterestPercent / 100);
        final monthly = installmentValue <= 0 ? 0.0 : total / installmentValue;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormRow(
              children: [
                NumberField(
                  controller: amount,
                  label: 'Kredi tutarı',
                  icon: Icons.attach_money,
                  suffix: bank.currency,
                  autofocus: true,
                  errorText: error,
                  helper: 'Üst sınır: ${bank.money(maxLoan)}',
                  onChanged: (_) => setState(() => error = null),
                ),
                NumberField(
                  controller: installments,
                  label: 'Taksit sayısı',
                  icon: Icons.repeat,
                  allowDecimal: false,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final n in [3, 6, 12, 18, 24])
                  if (n <= bank.settings.loanMaxInstallments)
                    ActionChip(
                      label: Text('$n taksit'),
                      onPressed: () => setState(() {
                        installments.text = '$n';
                        amount.text =
                            (maxLoan * (n / bank.settings.loanMaxInstallments))
                                .toStringAsFixed(0);
                      }),
                    ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  KeyValueRow(
                      label: 'Faiz', value: Fmt.percent(bank.settings.loanInterestPercent), dense: true),
                  KeyValueRow(
                      label: 'Geri ödenecek',
                      value: bank.money(total),
                      dense: true),
                  KeyValueRow(
                      label: 'Aylık taksit',
                      value: bank.money(monthly),
                      dense: true,
                      valueColor: Theme.of(ctx).colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final value = Fmt.parseAmount(amount.text) ?? 0;
                    final count = Fmt.parseInt(installments.text) ?? 0;
                    try {
                      bank.giveLoan(user.id, value, count, note: note.text);
                      Navigator.pop(ctx, true);
                      showSnackBar(context,
                          '${bank.money(value)} kredi ${user.fullName} hesabına aktarıldı.');
                    } catch (e) {
                      setState(
                          () => error = e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                  child: const Text('Krediyi Ver'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  return saved ?? false;
}

/// İşten çıkarma.
Future<bool> showDismissDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  final reason = TextEditingController();
  bool payFee = true;
  final company = bank.companyById(user.companyId);
  final canPay = company != null && company.balance >= user.terminationFee;

  final confirmed = await showAppDialog<bool>(
    context,
    title: 'İşten Çıkar',
    subtitle: '${user.fullName} pasife alınacak ve aktif kredileri kapatılacak.',
    icon: Icons.person_remove_outlined,
    accent: const Color(0xFFEF4444),
    maxWidth: 500,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Gerekçe',
              prefixIcon: Icon(Icons.report_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: payFee && canPay,
            onChanged: canPay ? (v) => setState(() => payFee = v) : null,
            title: const Text('Tazminat öde'),
            subtitle: Text(
              canPay
                  ? '${bank.money(user.terminationFee)} şirketten çalışana aktarılır'
                  : 'Şirket bakiyesi yetersiz (${company?.name ?? '-'})',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  bank.dismissEmployee(user.id, reason.text,
                      payTerminationFee: payFee && canPay);
                  Navigator.pop(ctx, true);
                  showSnackBar(context, '${user.fullName} işten çıkarıldı.');
                },
                child: const Text('Onayla'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

/// Şifre değiştirme.
Future<bool> showPasswordDialog(BuildContext context, AppUser user) async {
  final bank = context.read<BankProvider>();
  final pass = TextEditingController();
  final repeat = TextEditingController();
  String? error;
  bool obscure = true;

  final saved = await showAppDialog<bool>(
    context,
    title: 'Şifre Değiştir',
    subtitle: user.fullName,
    icon: Icons.lock_reset,
    maxWidth: 460,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: pass,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Yeni şifre',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => obscure = !obscure),
              ),
              errorText: error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: repeat,
            obscureText: obscure,
            decoration: const InputDecoration(
              labelText: 'Yeni şifre (tekrar)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  if (pass.text.length < 4) {
                    setState(() => error = 'En az 4 karakter olmalıdır.');
                    return;
                  }
                  if (pass.text != repeat.text) {
                    setState(() => error = 'Şifreler eşleşmiyor.');
                    return;
                  }
                  bank.changePassword(user.id, pass.text);
                  Navigator.pop(ctx, true);
                  showSnackBar(context, 'Şifre güncellendi.');
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

/// Seçili kullanıcılar için toplu işlem menüsü.
Future<void> showBulkActionsDialog(
  BuildContext context,
  List<AppUser> selected,
) async {
  final bank = context.read<BankProvider>();
  final action = await showAppDialog<String>(
    context,
    title: '${selected.length} Kayıt Seçildi',
    subtitle: 'Uygulanacak toplu işlemi seçin.',
    icon: Icons.bolt_outlined,
    maxWidth: 560,
    child: Column(
      children: [
        for (final item in [
          (
            'bonus',
            'Toplu Prim',
            'Seçili çalışanlara eşit tutarda prim öde',
            Icons.card_giftcard,
            const Color(0xFF8B5CF6)
          ),
          (
            'penalty',
            'Toplu Ceza',
            'Sabit tutar veya maaş yüzdesi olarak ceza uygula',
            Icons.gavel_outlined,
            const Color(0xFFEF4444)
          ),
          (
            'promote',
            'Toplu Terfi / Zam',
            'Unvan ve maaş artışını birlikte uygula',
            Icons.trending_up,
            const Color(0xFF10B981)
          ),
          (
            'monthlyBonus',
            'Aylık Prim Tanımla',
            'Her ay otomatik ödenecek prim tutarını belirle',
            Icons.event_repeat_outlined,
            const Color(0xFF3B82F6)
          ),
          (
            'move',
            'Şirket Değiştir',
            'Seçili çalışanları başka bir şirkete taşı',
            Icons.business_outlined,
            const Color(0xFF06B6D4)
          ),
          (
            'activate',
            'Aktifleştir',
            'Hesapları aktif hale getir',
            Icons.check_circle_outline,
            const Color(0xFF22C55E)
          ),
          (
            'deactivate',
            'Pasife Al',
            'Hesapları pasif hale getir',
            Icons.pause_circle_outline,
            const Color(0xFFF59E0B)
          ),
          (
            'delete',
            'Sil',
            'Seçili kayıtları kalıcı olarak sil',
            Icons.delete_outline,
            const Color(0xFFEF4444)
          ),
        ])
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
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
            trailing: const Icon(Icons.chevron_right, size: 19),
            onTap: () => Navigator.pop(context, item.$1),
          ),
      ],
    ),
  );

  if (action == null || !context.mounted) return;
  final ids = selected.map((u) => u.id).toList();

  switch (action) {
    case 'bonus':
      await showBonusDialog(context, targets: selected);
      break;
    case 'penalty':
      await showPenaltyDialog(context, targets: selected);
      break;
    case 'promote':
      await showPromoteDialog(context, targets: selected);
      break;
    case 'monthlyBonus':
      final value = await showAmountDialog(
        context,
        title: 'Aylık Prim Tanımla',
        label: 'Kişi başı aylık prim',
        currency: bank.currency,
        initial: bank.settings.defaultBonusAmount,
        description: 'Bu tutar, prim ödemesi çalıştırıldığında otomatik ödenir.',
      );
      if (value == null || !context.mounted) return;
      final result = bank.bulkSetMonthlyBonus(ids, value);
      showSnackBar(context, result.summary);
      break;
    case 'move':
      final company = await showCompanyPickerDialog(
        context,
        companies: bank.companies,
        title: 'Hedef Şirket',
      );
      if (company == null || !context.mounted) return;
      final result = bank.bulkMoveToCompany(ids, company.id);
      showSnackBar(context,
          '${result.summary}${result.failures.isEmpty ? '' : ' ${result.failures.take(2).join(', ')}'}');
      break;
    case 'activate':
      showSnackBar(context, bank.bulkSetActive(ids, true).summary);
      break;
    case 'deactivate':
      showSnackBar(context, bank.bulkSetActive(ids, false).summary);
      break;
    case 'delete':
      if (!context.mounted) return;
      await showConfirmDialog(
        context,
        title: '${selected.length} kayıt silinsin mi?',
        message:
            'Bu işlem geri alınabilir (Ayarlar > Veri Yönetimi > Geri Al). Kredi kayıtları da silinir.',
        icon: Icons.delete_forever_outlined,
        danger: true,
        confirmText: 'Sil',
        onConfirm: () {
          final result = bank.bulkDelete(ids);
          showSnackBar(context, result.summary);
        },
      );
      break;
  }
}
