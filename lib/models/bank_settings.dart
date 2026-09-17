/// Banka geneli ayarlar — uygulamanın tamamı bu değerlerle özelleştirilebilir.
class BankSettings {
  // ----- Kimlik -----
  String bankName;
  String slogan;
  String logoEmoji;
  String contactEmail;
  String contactPhone;
  String website;
  String address;

  // ----- Para birimi -----
  String currency;
  int decimalDigits;
  bool symbolAfter;

  // ----- Maaş kuralları -----
  int salaryDay; // her ayın kaçında maaş yatacak (1-31)
  bool autoPayroll; // vadesi gelen maaşları açılışta otomatik öde
  double salaryMinRatio; // şirket limitine göre dağıtımda alt sınır oranı (0.3-1.0)
  bool taxEnabled; // maaştan gelir vergisi kesilsin mi
  double taxPercent; // gelir vergisi yüzdesi
  double defaultSalaryLimit; // yeni şirket için varsayılan maaş sınırı

  // ----- Prim / Ceza -----
  double defaultBonusAmount; // tek tıkla önerilen prim tutarı
  bool penaltyEnabled;
  double penaltyMaxPercent; // maaşa göre maksimum ceza yüzdesi
  bool randomDeductionEnabled;
  double randomDeductionMin;
  double randomDeductionMax;
  bool randomDeductionPercent; // kesinti maaş yüzdesi olarak mı

  // ----- Sözleşme -----
  int defaultContractMonths;
  double defaultTerminationMultiplier; // maaşın kaç katı fesih bedeli
  int contractAlertDays; // kaç gün kala uyarı verilsin
  bool autoContractRenewal; // süresi dolan sözleşmeler otomatik uzatılsın mı

  // ----- Transfer -----
  bool transfersEnabled;
  bool allowCrossCompanyTransfers;
  double transferFeePercent; // banka komisyonu
  double transferMinAmount;
  double transferMaxAmount;
  bool requireTransferNote;

  // ----- Kredi -----
  bool loansEnabled;
  double loanMaxAmount;
  double loanMaxSalaryMultiplier; // aylık maaşın kaç katına kadar
  int loanMaxInstallments;
  double loanInterestPercent;

  // ----- Görünüm -----
  String themeMode; // 'system' | 'light' | 'dark'
  String accentId;
  String density; // UiDensity.name
  bool animationsEnabled;
  bool gradientBackground;

  // ----- Veri & Bildirim -----
  bool notificationsEnabled;
  bool autoBackupReminder;
  int auditLimit; // saklanan maksimum günlük kaydı

  // ----- Modüller -----
  Map<String, bool> modules;

  BankSettings({
    this.bankName = 'Arena Bank',
    this.slogan = 'Dijital Banka & Maaş Yönetim Merkezi',
    this.logoEmoji = '🏦',
    this.contactEmail = 'destek@arenabank.local',
    this.contactPhone = '+90 000 000 00 00',
    this.website = 'arenabank.local',
    this.address = 'Dijital Merkez, İstanbul',
    this.currency = '₺',
    this.decimalDigits = 2,
    this.symbolAfter = true,
    this.salaryDay = 1,
    this.autoPayroll = true,
    this.salaryMinRatio = 0.5,
    this.taxEnabled = false,
    this.taxPercent = 15,
    this.defaultSalaryLimit = 50000,
    this.defaultBonusAmount = 2500,
    this.penaltyEnabled = true,
    this.penaltyMaxPercent = 50,
    this.randomDeductionEnabled = true,
    this.randomDeductionMin = 50,
    this.randomDeductionMax = 500,
    this.randomDeductionPercent = false,
    this.defaultContractMonths = 12,
    this.defaultTerminationMultiplier = 2,
    this.contractAlertDays = 30,
    this.autoContractRenewal = false,
    this.transfersEnabled = true,
    this.allowCrossCompanyTransfers = true,
    this.transferFeePercent = 0,
    this.transferMinAmount = 1,
    this.transferMaxAmount = 0, // 0 = sınırsız
    this.requireTransferNote = false,
    this.loansEnabled = true,
    this.loanMaxAmount = 250000,
    this.loanMaxSalaryMultiplier = 6,
    this.loanMaxInstallments = 24,
    this.loanInterestPercent = 0,
    this.themeMode = 'system',
    this.accentId = 'indigo',
    this.density = 'normal',
    this.animationsEnabled = true,
    this.gradientBackground = true,
    this.notificationsEnabled = true,
    this.autoBackupReminder = true,
    this.auditLimit = 300,
    Map<String, bool>? modules,
  }) : modules = modules ?? _defaultModules();

  static Map<String, bool> _defaultModules() => {
        'companies': true,
        'users': true,
        'payroll': true,
        'transactions': true,
        'reports': true,
        'loans': true,
        'help': true,
      };

  bool moduleEnabled(String key) => modules[key] ?? true;

  BankSettings copy() => BankSettings.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'slogan': slogan,
        'logoEmoji': logoEmoji,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'website': website,
        'address': address,
        'currency': currency,
        'decimalDigits': decimalDigits,
        'symbolAfter': symbolAfter,
        'salaryDay': salaryDay,
        'autoPayroll': autoPayroll,
        'salaryMinRatio': salaryMinRatio,
        'taxEnabled': taxEnabled,
        'taxPercent': taxPercent,
        'defaultSalaryLimit': defaultSalaryLimit,
        'defaultBonusAmount': defaultBonusAmount,
        'penaltyEnabled': penaltyEnabled,
        'penaltyMaxPercent': penaltyMaxPercent,
        'randomDeductionEnabled': randomDeductionEnabled,
        'randomDeductionMin': randomDeductionMin,
        'randomDeductionMax': randomDeductionMax,
        'randomDeductionPercent': randomDeductionPercent,
        'defaultContractMonths': defaultContractMonths,
        'defaultTerminationMultiplier': defaultTerminationMultiplier,
        'contractAlertDays': contractAlertDays,
        'autoContractRenewal': autoContractRenewal,
        'transfersEnabled': transfersEnabled,
        'allowCrossCompanyTransfers': allowCrossCompanyTransfers,
        'transferFeePercent': transferFeePercent,
        'transferMinAmount': transferMinAmount,
        'transferMaxAmount': transferMaxAmount,
        'requireTransferNote': requireTransferNote,
        'loansEnabled': loansEnabled,
        'loanMaxAmount': loanMaxAmount,
        'loanMaxSalaryMultiplier': loanMaxSalaryMultiplier,
        'loanMaxInstallments': loanMaxInstallments,
        'loanInterestPercent': loanInterestPercent,
        'themeMode': themeMode,
        'accentId': accentId,
        'density': density,
        'animationsEnabled': animationsEnabled,
        'gradientBackground': gradientBackground,
        'notificationsEnabled': notificationsEnabled,
        'autoBackupReminder': autoBackupReminder,
        'auditLimit': auditLimit,
        'modules': modules,
      };

  factory BankSettings.fromJson(Map<String, dynamic> json) {
    final s = BankSettings();
    final defaults = s.toJson();
    final merged = <String, dynamic>{...defaults, ...json};
    final modulesRaw = merged['modules'];
    final modules = <String, bool>{..._defaultModules()};
    if (modulesRaw is Map) {
      modulesRaw.forEach((key, value) {
        final k = key.toString();
        if (value is bool) modules[k] = value;
      });
    }
    return BankSettings(
      bankName: _str(merged['bankName'], 'Arena Bank'),
      slogan: _str(merged['slogan'], 'Dijital Banka & Maaş Yönetim Merkezi'),
      logoEmoji: _str(merged['logoEmoji'], '🏦'),
      contactEmail: _str(merged['contactEmail'], 'destek@arenabank.local'),
      contactPhone: _str(merged['contactPhone'], '+90 000 000 00 00'),
      website: _str(merged['website'], 'arenabank.local'),
      address: _str(merged['address'], 'Dijital Merkez, İstanbul'),
      currency: _str(merged['currency'], '₺'),
      decimalDigits: (_num(merged['decimalDigits'], 2)).toInt().clamp(0, 4),
      symbolAfter: merged['symbolAfter'] as bool? ?? true,
      salaryDay: (_num(merged['salaryDay'], 1)).toInt().clamp(1, 31),
      autoPayroll: merged['autoPayroll'] as bool? ?? true,
      salaryMinRatio: _num(merged['salaryMinRatio'], 0.5).clamp(0.05, 1.0),
      taxEnabled: merged['taxEnabled'] as bool? ?? false,
      taxPercent: _num(merged['taxPercent'], 15).clamp(0.0, 90.0),
      defaultSalaryLimit: _num(merged['defaultSalaryLimit'], 50000),
      defaultBonusAmount: _num(merged['defaultBonusAmount'], 2500),
      penaltyEnabled: merged['penaltyEnabled'] as bool? ?? true,
      penaltyMaxPercent: _num(merged['penaltyMaxPercent'], 50).clamp(1.0, 100.0),
      randomDeductionEnabled: merged['randomDeductionEnabled'] as bool? ?? true,
      randomDeductionMin: _num(merged['randomDeductionMin'], 50),
      randomDeductionMax: _num(merged['randomDeductionMax'], 500),
      randomDeductionPercent:
          merged['randomDeductionPercent'] as bool? ?? false,
      defaultContractMonths:
          (_num(merged['defaultContractMonths'], 12)).toInt().clamp(1, 120),
      defaultTerminationMultiplier:
          _num(merged['defaultTerminationMultiplier'], 2).clamp(0.0, 24.0),
      contractAlertDays:
          (_num(merged['contractAlertDays'], 30)).toInt().clamp(1, 365),
      autoContractRenewal: merged['autoContractRenewal'] as bool? ?? false,
      transfersEnabled: merged['transfersEnabled'] as bool? ?? true,
      allowCrossCompanyTransfers:
          merged['allowCrossCompanyTransfers'] as bool? ?? true,
      transferFeePercent: _num(merged['transferFeePercent'], 0).clamp(0.0, 25.0),
      transferMinAmount: _num(merged['transferMinAmount'], 1),
      transferMaxAmount: _num(merged['transferMaxAmount'], 0),
      requireTransferNote: merged['requireTransferNote'] as bool? ?? false,
      loansEnabled: merged['loansEnabled'] as bool? ?? true,
      loanMaxAmount: _num(merged['loanMaxAmount'], 250000),
      loanMaxSalaryMultiplier:
          _num(merged['loanMaxSalaryMultiplier'], 6).clamp(0.5, 60.0),
      loanMaxInstallments:
          (_num(merged['loanMaxInstallments'], 24)).toInt().clamp(1, 120),
      loanInterestPercent: _num(merged['loanInterestPercent'], 0).clamp(0.0, 100.0),
      themeMode: _str(merged['themeMode'], 'system'),
      accentId: _str(merged['accentId'], 'indigo'),
      density: _str(merged['density'], 'normal'),
      animationsEnabled: merged['animationsEnabled'] as bool? ?? true,
      gradientBackground: merged['gradientBackground'] as bool? ?? true,
      notificationsEnabled: merged['notificationsEnabled'] as bool? ?? true,
      autoBackupReminder: merged['autoBackupReminder'] as bool? ?? true,
      auditLimit: (_num(merged['auditLimit'], 300)).toInt().clamp(20, 5000),
      modules: modules,
    );
  }

  static String _str(dynamic value, String fallback) {
    final v = value?.toString();
    if (v == null || v.trim().isEmpty) return fallback;
    return v;
  }

  static double _num(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
