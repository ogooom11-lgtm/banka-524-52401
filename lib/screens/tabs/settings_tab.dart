import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../dialogs/import_export_dialogs.dart';

/// Ayarlar: banka kimliği, kurallar, görünüm, modüller ve veri yönetimi.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.onNavigate});

  /// Sayfa anahtarı: 'help' vb.
  final void Function(String route)? onNavigate;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _bankName;
  late final TextEditingController _slogan;
  late final TextEditingController _logo;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _address;
  late final TextEditingController _currency;
  late final TextEditingController _defaultSalaryLimit;
  late final TextEditingController _defaultBonus;
  late final TextEditingController _deductionMin;
  late final TextEditingController _deductionMax;
  late final TextEditingController _defaultContractMonths;
  late final TextEditingController _defaultTerminationMultiplier;
  late final TextEditingController _contractAlertDays;
  late final TextEditingController _transferMin;
  late final TextEditingController _transferMax;
  late final TextEditingController _loanMaxAmount;
  late final TextEditingController _loanMaxSalaryMultiplier;
  late final TextEditingController _loanMaxInstallments;
  bool _initializedControllers = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<BankProvider>().settings;
    _bankName = TextEditingController(text: s.bankName);
    _slogan = TextEditingController(text: s.slogan);
    _logo = TextEditingController(text: s.logoEmoji);
    _email = TextEditingController(text: s.contactEmail);
    _phone = TextEditingController(text: s.contactPhone);
    _website = TextEditingController(text: s.website);
    _address = TextEditingController(text: s.address);
    _currency = TextEditingController(text: s.currency);
    _defaultSalaryLimit =
        TextEditingController(text: _num(s.defaultSalaryLimit));
    _defaultBonus = TextEditingController(text: _num(s.defaultBonusAmount));
    _deductionMin = TextEditingController(text: _num(s.randomDeductionMin));
    _deductionMax = TextEditingController(text: _num(s.randomDeductionMax));
    _defaultContractMonths =
        TextEditingController(text: s.defaultContractMonths.toString());
    _defaultTerminationMultiplier =
        TextEditingController(text: _num(s.defaultTerminationMultiplier));
    _contractAlertDays =
        TextEditingController(text: s.contractAlertDays.toString());
    _transferMin = TextEditingController(text: _num(s.transferMinAmount));
    _transferMax = TextEditingController(text: _num(s.transferMaxAmount));
    _loanMaxAmount = TextEditingController(text: _num(s.loanMaxAmount));
    _loanMaxSalaryMultiplier =
        TextEditingController(text: _num(s.loanMaxSalaryMultiplier));
    _loanMaxInstallments =
        TextEditingController(text: s.loanMaxInstallments.toString());
    _initializedControllers = true;
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [
      _bankName,
      _slogan,
      _logo,
      _email,
      _phone,
      _website,
      _address,
      _currency,
      _defaultSalaryLimit,
      _defaultBonus,
      _deductionMin,
      _deductionMax,
      _defaultContractMonths,
      _defaultTerminationMultiplier,
      _contractAlertDays,
      _transferMin,
      _transferMax,
      _loanMaxAmount,
      _loanMaxSalaryMultiplier,
      _loanMaxInstallments,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final s = bank.settings;
    final scheme = Theme.of(context).colorScheme;
    if (!_initializedControllers) return const SizedBox.shrink();

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.settings_outlined,
                        color: scheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ayarlar',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 3),
                        Text(
                          'Tüm değişiklikler anında kaydedilir. Verileriniz bu bilgisayarda saklanır.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDataManagementDialog(context),
                    icon: const Icon(Icons.storage_outlined, size: 18),
                    label: const Text('Veri Yönetimi'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: bank.canUndo
                        ? () {
                            bank.undo();
                            showSnackBar(context, 'Son işlem geri alındı.');
                          }
                        : null,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Geri Al'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          WrapGrid(
            minItemWidth: 470,
            maxColumns: 2,
            children: [
              _identityCard(context, bank, s),
              _currencyCard(context, bank, s),
              _payrollCard(context, bank, s),
              _bonusPenaltyCard(context, bank, s),
              _contractCard(context, bank, s),
              _transferCard(context, bank, s),
              _loanCard(context, bank, s),
              _appearanceCard(context, bank, s),
              _modulesCard(context, bank, s),
              _dataCard(context, bank, s),
            ],
          ),
          const SizedBox(height: 18),
          _aboutCard(context, bank),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Kimlik
  Widget _identityCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Banka Kimliği',
            subtitle: 'Uygulamada görünen ad, logo ve iletişim bilgileri',
            icon: Icons.badge_outlined,
          ),
          TextField(
            controller: _bankName,
            decoration: const InputDecoration(
              labelText: 'Banka adı',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slogan,
            decoration: const InputDecoration(
              labelText: 'Slogan',
              prefixIcon: Icon(Icons.format_quote_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FormRow(
            children: [
              TextField(
                controller: _logo,
                decoration: const InputDecoration(
                  labelText: 'Logo (emoji)',
                  prefixIcon: Icon(Icons.emoji_emotions_outlined),
                ),
              ),
              TextField(
                controller: _website,
                decoration: const InputDecoration(
                  labelText: 'Web sitesi',
                  prefixIcon: Icon(Icons.language_outlined),
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
                  labelText: 'Destek e-postası',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final emoji in ['🏦', '💰', '🏛️', '💳', '📊', '🦅', '🚀'])
                ActionChip(
                  label: Text(emoji),
                  onPressed: () => setState(() => _logo.text = emoji),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                bank.updateSettings(_readSettings(bank));
                showSnackBar(context, 'Banka bilgileri kaydedildi.');
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Kimlik Bilgilerini Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Para
  Widget _currencyCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Para Birimi',
            subtitle: 'Sembol, konum ve ondalık basamak sayısı',
            icon: Icons.currency_exchange,
          ),
          FormRow(
            children: [
              TextField(
                controller: _currency,
                onChanged: (v) => bank.patchSettings((x) => x.currency = v),
                decoration: const InputDecoration(
                  labelText: 'Sembol',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              DropdownButtonFormField<int>(
                value: s.decimalDigits,
                decoration: const InputDecoration(
                  labelText: 'Ondalık basamak',
                  prefixIcon: Icon(Icons.numbers),
                ),
                items: [
                  for (var i = 0; i <= 4; i++)
                    DropdownMenuItem(value: i, child: Text('$i basamak')),
                ],
                onChanged: (v) =>
                    bank.patchSettings((x) => x.decimalDigits = v ?? 2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final cur in ['₺', '\$', '€', '£', '¥', 'CHF', '₺ TL'])
                ChoiceChip(
                  label: Text(cur),
                  selected: s.currency == cur,
                  onSelected: (_) {
                    _currency.text = cur;
                    bank.patchSettings((x) => x.currency = cur);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: s.symbolAfter,
            onChanged: (v) => bank.patchSettings((x) => x.symbolAfter = v),
            title: const Text('Sembol tutardan sonra gelsin'),
            subtitle: Text(
              s.symbolAfter
                  ? bank.money(1234567.5)
                  : Fmt.money(1234567.5, s.currency,
                      digits: s.decimalDigits, symbolAfter: false),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Maaş
  Widget _payrollCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Maaş Kuralları',
            subtitle: 'Maaş günü, otomatik ödeme, vergi ve dağıtım aralığı',
            icon: Icons.payments_outlined,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.salaryDay.toDouble().clamp(1.0, 28.0),
                  min: 1,
                  max: 28,
                  divisions: 27,
                  label: '${s.salaryDay}. gün',
                  onChanged: (v) => bank
                      .patchSettings((x) => x.salaryDay = v.round(), notify: true),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text('${s.salaryDay}. gün',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.salaryMinRatio.clamp(0.3, 1.0),
                  min: 0.3,
                  max: 1.0,
                  divisions: 14,
                  label: Fmt.percent(s.salaryMinRatio * 100, digits: 0),
                  onChanged: (v) => bank.patchSettings(
                      (x) => x.salaryMinRatio = v, notify: true),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Alt sınır ${Fmt.percent(s.salaryMinRatio * 100, digits: 0)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: s.autoPayroll,
            onChanged: (v) => bank.patchSettings(
              (x) => x.autoPayroll = v,
              logMessage: 'Otomatik maaş ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Otomatik maaş ödemesi'),
            subtitle: const Text(
                'Vadesi gelen maaşlar açılışta ve her dakika kontrolünde ödenir'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.taxEnabled,
            onChanged: (v) => bank.patchSettings(
              (x) => x.taxEnabled = v,
              logMessage: 'Vergi kesintisi ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Gelir vergisi kesintisi'),
            subtitle: const Text('Maaş ödemesinde brüt tutardan vergi kesilir'),
            contentPadding: EdgeInsets.zero,
          ),
          if (s.taxEnabled)
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: s.taxPercent.clamp(0.0, 60.0),
                    min: 0,
                    max: 60,
                    divisions: 60,
                    label: '%${s.taxPercent.toStringAsFixed(0)}',
                    onChanged: (v) => bank.patchSettings(
                        (x) => x.taxPercent = v, notify: true),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text('%${s.taxPercent.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          const SizedBox(height: 10),
          FormRow(
            children: [
              NumberField(
                controller: _defaultSalaryLimit,
                label: 'Yeni şirket maaş sınırı',
                icon: Icons.arrow_upward,
                suffix: bank.currency,
                onSubmitted: () => _applyPayroll(bank),
              ),
              NumberField(
                controller: _defaultBonus,
                label: 'Varsayılan prim tutarı',
                icon: Icons.card_giftcard,
                suffix: bank.currency,
                onSubmitted: () => _applyPayroll(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _applyPayroll(bank),
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Sayısal Alanları Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPayroll(BankProvider bank) {
    bank.patchSettings(
      (s) {
        s.defaultSalaryLimit = Fmt.parseAmount(_defaultSalaryLimit.text) ??
            s.defaultSalaryLimit;
        s.defaultBonusAmount =
            Fmt.parseAmount(_defaultBonus.text) ?? s.defaultBonusAmount;
      },
      logMessage: 'Maaş varsayılanları güncellendi',
      snapshot: false,
    );
    showSnackBar(context, 'Maaş varsayılanları kaydedildi.');
  }

  // ------------------------------------------------------- Prim & Ceza
  Widget _bonusPenaltyCard(
      BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Prim & Ceza',
            subtitle: 'Ceza sınırı ve rastgele kesinti aralığı',
            icon: Icons.gavel_outlined,
          ),
          SwitchListTile(
            value: s.penaltyEnabled,
            onChanged: (v) => bank.patchSettings(
              (x) => x.penaltyEnabled = v,
              logMessage: 'Ceza sistemi ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Ceza sistemi aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.penaltyMaxPercent.clamp(1.0, 100.0),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '%${s.penaltyMaxPercent.toStringAsFixed(0)}',
                  onChanged: (v) => bank.patchSettings(
                      (x) => x.penaltyMaxPercent = v, notify: true),
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  'Maks ceza %${s.penaltyMaxPercent.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          SwitchListTile(
            value: s.randomDeductionEnabled,
            onChanged: (v) => bank.patchSettings(
              (x) => x.randomDeductionEnabled = v,
              logMessage: 'Rastgele kesinti ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Rastgele kredi kesintisi aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.randomDeductionPercent,
            onChanged: (v) =>
                bank.patchSettings((x) => x.randomDeductionPercent = v),
            title: const Text('Kesinti maaş yüzdesi olarak hesaplansın'),
            contentPadding: EdgeInsets.zero,
          ),
          FormRow(
            children: [
              NumberField(
                controller: _deductionMin,
                label: s.randomDeductionPercent ? 'Min yüzde' : 'Min tutar',
                icon: Icons.arrow_downward,
                suffix: s.randomDeductionPercent ? '%' : bank.currency,
                onSubmitted: () => _applyDeduction(bank),
              ),
              NumberField(
                controller: _deductionMax,
                label: s.randomDeductionPercent ? 'Maks yüzde' : 'Maks tutar',
                icon: Icons.arrow_upward,
                suffix: s.randomDeductionPercent ? '%' : bank.currency,
                onSubmitted: () => _applyDeduction(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _applyDeduction(bank),
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Kesinti Aralığını Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDeduction(BankProvider bank) {
    final min = Fmt.parseAmount(_deductionMin.text) ?? 0;
    final max = Fmt.parseAmount(_deductionMax.text) ?? 0;
    if (min > max) {
      showSnackBar(context, 'Minimum değer maksimumdan büyük olamaz.',
          error: true);
      return;
    }
    bank.patchSettings((s) {
      s.randomDeductionMin = min;
      s.randomDeductionMax = max;
    }, logMessage: 'Kesinti aralığı güncellendi');
    showSnackBar(context, 'Kesinti aralığı kaydedildi.');
  }

  // ----------------------------------------------------------- Sözleşme
  Widget _contractCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Sözleşme Kuralları',
            subtitle: 'Varsayılan süre, fesih katsayısı ve uyarı eşiği',
            icon: Icons.event_note_outlined,
          ),
          FormRow(
            children: [
              NumberField(
                controller: _defaultContractMonths,
                label: 'Varsayılan süre (ay)',
                icon: Icons.timelapse,
                allowDecimal: false,
                onSubmitted: () => _applyContract(bank),
              ),
              NumberField(
                controller: _contractAlertDays,
                label: 'Uyarı eşiği (gün)',
                icon: Icons.notifications_active_outlined,
                allowDecimal: false,
                onSubmitted: () => _applyContract(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NumberField(
            controller: _defaultTerminationMultiplier,
            label: 'Fesih ücreti = maaşın kaç katı',
            icon: Icons.description_outlined,
            onSubmitted: () => _applyContract(bank),
          ),
          SwitchListTile(
            value: s.autoContractRenewal,
            onChanged: (v) => bank.patchSettings((x) => x.autoContractRenewal = v),
            title: const Text('Süresi dolan sözleşmeleri otomatik uzat'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _applyContract(bank),
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Sözleşme Kurallarını Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyContract(BankProvider bank) {
    bank.patchSettings((s) {
      s.defaultContractMonths =
          (Fmt.parseInt(_defaultContractMonths.text) ?? 12).clamp(1, 120);
      s.contractAlertDays =
          (Fmt.parseInt(_contractAlertDays.text) ?? 30).clamp(1, 365);
      s.defaultTerminationMultiplier =
          Fmt.parseAmount(_defaultTerminationMultiplier.text) ?? 2;
    }, logMessage: 'Sözleşme kuralları güncellendi');
    showSnackBar(context, 'Sözleşme kuralları kaydedildi.');
  }

  // ------------------------------------------------------------ Transfer
  Widget _transferCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Transfer Kuralları',
            subtitle: 'Komisyon, limitler ve kısıtlar',
            icon: Icons.swap_horiz,
          ),
          SwitchListTile(
            value: s.transfersEnabled,
            onChanged: (v) => bank.patchSettings(
              (x) => x.transfersEnabled = v,
              logMessage: 'Transferler ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Para transferleri aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.allowCrossCompanyTransfers,
            onChanged: (v) =>
                bank.patchSettings((x) => x.allowCrossCompanyTransfers = v),
            title: const Text('Şirketler arası transfer izni'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.requireTransferNote,
            onChanged: (v) =>
                bank.patchSettings((x) => x.requireTransferNote = v),
            title: const Text('Açıklama zorunlu'),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.transferFeePercent.clamp(0.0, 10.0),
                  min: 0,
                  max: 10,
                  divisions: 40,
                  label: Fmt.percent(s.transferFeePercent, digits: 2),
                  onChanged: (v) => bank.patchSettings(
                      (x) => x.transferFeePercent = v, notify: true),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'Komisyon ${Fmt.percent(s.transferFeePercent, digits: 2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          FormRow(
            children: [
              NumberField(
                controller: _transferMin,
                label: 'Minimum tutar',
                icon: Icons.arrow_downward,
                suffix: bank.currency,
                onSubmitted: () => _applyTransfer(bank),
              ),
              NumberField(
                controller: _transferMax,
                label: 'Maksimum tutar (0 = sınırsız)',
                icon: Icons.arrow_upward,
                suffix: bank.currency,
                onSubmitted: () => _applyTransfer(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _applyTransfer(bank),
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Transfer Limitlerini Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyTransfer(BankProvider bank) {
    bank.patchSettings((s) {
      s.transferMinAmount = Fmt.parseAmount(_transferMin.text) ?? 0;
      s.transferMaxAmount = Fmt.parseAmount(_transferMax.text) ?? 0;
    }, logMessage: 'Transfer limitleri güncellendi');
    showSnackBar(context, 'Transfer limitleri kaydedildi.');
  }

  // --------------------------------------------------------------- Kredi
  Widget _loanCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Kredi Kuralları',
            subtitle: 'Limitler, taksit sayısı ve faiz',
            icon: Icons.request_quote_outlined,
          ),
          SwitchListTile(
            value: s.loansEnabled,
            onChanged: (v) => bank.patchSettings(
              (x) => x.loansEnabled = v,
              logMessage: 'Kredi sistemi ${v ? 'açıldı' : 'kapatıldı'}',
            ),
            title: const Text('Kredi / avans sistemi aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          FormRow(
            children: [
              NumberField(
                controller: _loanMaxAmount,
                label: 'Maksimum kredi tutarı',
                icon: Icons.speed,
                suffix: bank.currency,
                onSubmitted: () => _applyLoan(bank),
              ),
              NumberField(
                controller: _loanMaxSalaryMultiplier,
                label: 'Maaşın kaç katı',
                icon: Icons.trending_up,
                onSubmitted: () => _applyLoan(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FormRow(
            children: [
              NumberField(
                controller: _loanMaxInstallments,
                label: 'Maksimum taksit sayısı',
                icon: Icons.repeat,
                allowDecimal: false,
                onSubmitted: () => _applyLoan(bank),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faiz oranı: ${Fmt.percent(s.loanInterestPercent)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12.5)),
                  Slider(
                    value: s.loanInterestPercent.clamp(0.0, 50.0),
                    min: 0,
                    max: 50,
                    divisions: 100,
                    label: Fmt.percent(s.loanInterestPercent),
                    onChanged: (v) => bank.patchSettings(
                        (x) => x.loanInterestPercent = v, notify: true),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _applyLoan(bank),
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Kredi Kurallarını Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyLoan(BankProvider bank) {
    bank.patchSettings((s) {
      s.loanMaxAmount = Fmt.parseAmount(_loanMaxAmount.text) ?? s.loanMaxAmount;
      s.loanMaxSalaryMultiplier =
          Fmt.parseAmount(_loanMaxSalaryMultiplier.text) ??
              s.loanMaxSalaryMultiplier;
      s.loanMaxInstallments =
          (Fmt.parseInt(_loanMaxInstallments.text) ?? s.loanMaxInstallments)
              .clamp(1, 120);
    }, logMessage: 'Kredi kuralları güncellendi');
    showSnackBar(context, 'Kredi kuralları kaydedildi.');
  }

  // ------------------------------------------------------------ Görünüm
  Widget _appearanceCard(
      BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Görünüm',
            subtitle: 'Tema, vurgu rengi, yoğunluk ve animasyonlar',
            icon: Icons.palette_outlined,
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'system',
                  label: Text('Sistem'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 15)),
              ButtonSegment(
                  value: 'light',
                  label: Text('Açık'),
                  icon: Icon(Icons.light_mode_outlined, size: 15)),
              ButtonSegment(
                  value: 'dark',
                  label: Text('Koyu'),
                  icon: Icon(Icons.dark_mode_outlined, size: 15)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => bank.setThemeMode(v.first),
          ),
          const SizedBox(height: 16),
          Text('Vurgu rengi', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in kAccentPresets)
                Tooltip(
                  message: preset.label,
                  child: GestureDetector(
                    onTap: () => bank.setAccent(preset.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: preset.gradient),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: s.accentId == preset.id
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: preset.seed.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: s.accentId == preset.id
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 19)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Arayüz yoğunluğu', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              for (final d in UiDensity.values)
                ButtonSegment(value: d.name, label: Text(d.label)),
            ],
            selected: {s.density},
            onSelectionChanged: (v) => bank.setDensity(v.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: s.animationsEnabled,
            onChanged: (v) => bank.setAnimations(v),
            title: const Text('Animasyonlar'),
            subtitle: const Text('Kapatırsanız geçişler anında gerçekleşir'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.gradientBackground,
            onChanged: (v) => bank.setGradientBackground(v),
            title: const Text('Gradyan arka plan'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Modüller
  Widget _modulesCard(BuildContext context, BankProvider bank, BankSettings s) {
    const labels = <String, (String, IconData)>{
      'companies': ('Şirketler', Icons.business_outlined),
      'users': ('Kullanıcılar', Icons.people_outline),
      'payroll': ('Maaş Merkezi', Icons.payments_outlined),
      'transactions': ('İşlemler', Icons.receipt_long_outlined),
      'reports': ('Raporlar', Icons.insights_outlined),
      'loans': ('Krediler', Icons.request_quote_outlined),
      'help': ('Nasıl Çalışır?', Icons.help_outline),
    };
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Modüller',
            subtitle: 'Kullanmadığınız bölümleri gizleyin',
            icon: Icons.widgets_outlined,
          ),
          for (final entry in labels.entries)
            SwitchListTile(
              value: s.moduleEnabled(entry.key),
              onChanged: (v) => bank.toggleModule(entry.key, v),
              title: Text(entry.value.$1),
              secondary: Icon(entry.value.$2, size: 19),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Veri yönetimi
  Widget _dataCard(BuildContext context, BankProvider bank, BankSettings s) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Veri, Bildirim & Günlük',
            subtitle: 'Yedekleme, bildirim tercihleri ve denetim kaydı',
            icon: Icons.storage_outlined,
          ),
          SwitchListTile(
            value: s.notificationsEnabled,
            onChanged: (v) =>
                bank.patchSettings((x) => x.notificationsEnabled = v),
            title: const Text('Uygulama içi bildirimler'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.autoBackupReminder,
            onChanged: (v) =>
                bank.patchSettings((x) => x.autoBackupReminder = v),
            title: const Text('Yedekleme hatırlatıcısı'),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.auditLimit.toDouble().clamp(50.0, 2000.0),
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: '${s.auditLimit} kayıt',
                  onChanged: (v) => bank.patchSettings(
                      (x) => x.auditLimit = v.round(), notify: true),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text('${s.auditLimit} kayıt',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => showDataManagementDialog(context),
                icon: const Icon(Icons.storage_outlined, size: 17),
                label: const Text('Yedek & Dışa Aktarma'),
              ),
              OutlinedButton.icon(
                onPressed: () => showAuditLogDialog(context),
                icon: const Icon(Icons.history_outlined, size: 17),
                label: Text('Sistem Günlüğü (${bank.auditLog.length})'),
              ),
              OutlinedButton.icon(
                onPressed: () => showNotificationsDialog(context),
                icon: const Icon(Icons.notifications_none, size: 17),
                label: Text(
                    'Bildirimler${bank.unreadNotificationCount > 0 ? ' (${bank.unreadNotificationCount} yeni)' : ''}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context, BankProvider bank) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(bank.logoEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${bank.bankName} • Sürüm 2.0',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  'Flutter ile geliştirilmiş, tamamen çevrimdışı çalışan masaüstü banka simülasyonu. '
                  'Veriler bu bilgisayarda saklanır; düzenli yedek almanız önerilir.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate?.call('help'),
            icon: const Icon(Icons.help_outline, size: 17),
            label: const Text('Nasıl Çalışır?'),
          ),
        ],
      ),
    );
  }

  BankSettings _readSettings(BankProvider bank) {
    final s = bank.settings.copy();
    s.bankName = _bankName.text.trim().isEmpty
        ? s.bankName
        : _bankName.text.trim();
    s.slogan = _slogan.text.trim();
    s.logoEmoji = _logo.text.trim().isEmpty ? '🏦' : _logo.text.trim();
    s.contactEmail = _email.text.trim();
    s.contactPhone = _phone.text.trim();
    s.website = _website.text.trim();
    s.address = _address.text.trim();
    s.currency = _currency.text.trim().isEmpty ? s.currency : _currency.text.trim();
    s.defaultSalaryLimit =
        Fmt.parseAmount(_defaultSalaryLimit.text) ?? s.defaultSalaryLimit;
    s.defaultBonusAmount =
        Fmt.parseAmount(_defaultBonus.text) ?? s.defaultBonusAmount;
    s.randomDeductionMin =
        Fmt.parseAmount(_deductionMin.text) ?? s.randomDeductionMin;
    s.randomDeductionMax =
        Fmt.parseAmount(_deductionMax.text) ?? s.randomDeductionMax;
    s.defaultContractMonths =
        (Fmt.parseInt(_defaultContractMonths.text) ?? s.defaultContractMonths)
            .clamp(1, 120);
    s.defaultTerminationMultiplier =
        Fmt.parseAmount(_defaultTerminationMultiplier.text) ??
            s.defaultTerminationMultiplier;
    s.contractAlertDays =
        (Fmt.parseInt(_contractAlertDays.text) ?? s.contractAlertDays)
            .clamp(1, 365);
    s.transferMinAmount =
        Fmt.parseAmount(_transferMin.text) ?? s.transferMinAmount;
    s.transferMaxAmount =
        Fmt.parseAmount(_transferMax.text) ?? s.transferMaxAmount;
    s.loanMaxAmount = Fmt.parseAmount(_loanMaxAmount.text) ?? s.loanMaxAmount;
    s.loanMaxSalaryMultiplier = Fmt.parseAmount(_loanMaxSalaryMultiplier.text) ??
        s.loanMaxSalaryMultiplier;
    s.loanMaxInstallments =
        (Fmt.parseInt(_loanMaxInstallments.text) ?? s.loanMaxInstallments)
            .clamp(1, 120);
    return s;
  }
}
