enum TxnType {
  salary('Maaş'),
  bonus('Performans Primi'),
  penalty('Ceza'),
  randomDeduction('Rastgele Kredi Kesintisi'),
  promotion('Terfi'),
  transfer('Transfer'),
  credit('Kredi Yükleme'),
  terminationFee('Sözleşme Fesih Ücreti'),
  system('Sistem');

  final String label;
  const TxnType(this.label);
}

class Txn {
  final String id;
  final TxnType type;
  final double amount;
  final String fromId; // company/user id or 'BANK'
  final String toId;
  final String description;
  final DateTime date;

  Txn({
    required this.id,
    required this.type,
    required this.amount,
    required this.fromId,
    required this.toId,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'fromId': fromId,
        'toId': toId,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: json['id']?.toString() ?? 'txn-0',
        type: TxnType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TxnType.system,
        ),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        fromId: json['fromId']?.toString() ?? '',
        toId: json['toId']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
      );
}
