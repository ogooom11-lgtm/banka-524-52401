import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

final NumberFormat _currencyFmt = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '',
  decimalDigits: 2,
);

String money(double v, String currency) {
  return '${_currencyFmt.format(v)} $currency';
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.withAlpha(38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: c, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TxnIcon {
  static IconData of(TxnType t) {
    switch (t) {
      case TxnType.salary:
        return Icons.payments_outlined;
      case TxnType.bonus:
        return Icons.card_giftcard;
      case TxnType.penalty:
        return Icons.warning_amber_rounded;
      case TxnType.randomDeduction:
        return Icons.casino_outlined;
      case TxnType.promotion:
        return Icons.trending_up;
      case TxnType.transfer:
        return Icons.swap_horiz;
      case TxnType.credit:
        return Icons.account_balance_wallet;
      case TxnType.terminationFee:
        return Icons.description_outlined;
      case TxnType.system:
        return Icons.settings_outlined;
    }
  }

  static Color colorOf(TxnType t) {
    switch (t) {
      case TxnType.salary:
      case TxnType.bonus:
      case TxnType.promotion:
      case TxnType.credit:
        return Colors.green;
      case TxnType.penalty:
      case TxnType.randomDeduction:
      case TxnType.terminationFee:
        return Colors.red;
      case TxnType.transfer:
        return Colors.blue;
      case TxnType.system:
        return Colors.grey;
    }
  }
}

Future<void> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Onayla',
  Color? confirmColor,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
        FilledButton(
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

void showSnackBar(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.teal.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
