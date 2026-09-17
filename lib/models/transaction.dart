/// Hareket türleri — etiketler Türkçe (uygulamanın tamamı Türkçedir).
enum TxnType {
  salary('Maaş', 'Maaş ödemesi'),
  bonus('Performans Primi', 'Prim / ödül'),
  promotion('Terfi', 'Unvan / maaş artışı'),
  transfer('Transfer', 'Hesaplar arası para hareketi'),
  credit('Kredi Yükleme', 'Banka tarafından bakiye yükleme'),
  penalty('Ceza', 'Disiplin cezası'),
  randomDeduction('Rastgele Kredi Kesintisi', 'Ayarlanabilir aralıkta kesinti'),
  terminationFee('Sözleşme Fesih Ücreti', 'Erken çıkış tazminatı'),
  loan('Kredi Kullanımı', 'Çalışana kredi verildi'),
  loanRepayment('Kredi Taksidi', 'Kredi geri ödemesi'),
  tax('Vergi', 'Gelir vergisi kesintisi'),
  expense('Gider', 'Şirket / sistem gideri'),
  interest('Faiz', 'Faiz işletmesi'),
  refund('İade', 'İade edilen tutar'),
  system('Sistem', 'Sistem olayı');

  final String label;
  final String description;
  const TxnType(this.label, this.description);

  static TxnType fromName(String? name) {
    for (final t in TxnType.values) {
      if (t.name == name) return t;
    }
    return TxnType.system;
  }

  /// Para girişi mi? (Yeşil gösterim)
  bool get isIncoming =>
      this == salary ||
      this == bonus ||
      this == credit ||
      this == promotion ||
      this == loan ||
      this == refund;

  /// Para çıkışı mı? (Kırmızı gösterim)
  bool get isOutgoing =>
      this == penalty ||
      this == randomDeduction ||
      this == terminationFee ||
      this == loanRepayment ||
      this == tax ||
      this == expense;

  bool get isNeutral => !isIncoming && !isOutgoing;
}

class Txn {
  final String id;
  final TxnType type;
  final double amount;
  final String fromId; // şirket / kullanıcı kimliği veya 'BANK'
  final String toId;
  final String description;
  final DateTime date;
  final String actorId; // işlemi yapan kullanıcı (varsa)
  final String reference; // kısa referans kodu

  Txn({
    required this.id,
    required this.type,
    required this.amount,
    required this.fromId,
    required this.toId,
    required this.description,
    required this.date,
    this.actorId = 'BANK',
    this.reference = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'fromId': fromId,
        'toId': toId,
        'description': description,
        'date': date.toIso8601String(),
        'actorId': actorId,
        'reference': reference,
      };

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: json['id']?.toString() ?? 'txn-0',
        type: TxnType.fromName(json['type']?.toString()),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        fromId: json['fromId']?.toString() ?? '',
        toId: json['toId']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        actorId: json['actorId']?.toString() ?? 'BANK',
        reference: json['reference']?.toString() ?? '',
      );

  /// Belirli bir hesap açısından işaretli etki (+/-/0).
  double effectFor(String accountId) {
    if (amount == 0) return 0;
    if (toId == accountId && fromId != accountId) return amount;
    if (fromId == accountId && toId != accountId) return -amount;
    return 0;
  }
}
