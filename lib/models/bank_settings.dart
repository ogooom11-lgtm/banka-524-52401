class BankSettings {
  double randomDeductionMin;
  double randomDeductionMax;
  int salaryDay; // her ayın kaçında maaş yatacak (1-31)
  String currency;
  String bankName;

  BankSettings({
    this.randomDeductionMin = 50,
    this.randomDeductionMax = 500,
    this.salaryDay = 1,
    this.currency = '₺',
    this.bankName = 'Arena Bank',
  });

  Map<String, dynamic> toJson() => {
        'randomDeductionMin': randomDeductionMin,
        'randomDeductionMax': randomDeductionMax,
        'salaryDay': salaryDay,
        'currency': currency,
        'bankName': bankName,
      };

  factory BankSettings.fromJson(Map<String, dynamic> json) => BankSettings(
        randomDeductionMin:
            (json['randomDeductionMin'] as num?)?.toDouble() ?? 50.0,
        randomDeductionMax:
            (json['randomDeductionMax'] as num?)?.toDouble() ?? 500.0,
        salaryDay: (json['salaryDay'] as num?)?.toInt() ?? 1,
        currency: json['currency']?.toString() ?? '₺',
        bankName: json['bankName']?.toString() ?? 'Arena Bank',
      );
}
