import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bank_provider.dart';
import '../../models/app_user.dart';
import '../../models/transaction.dart';
import '../../widgets/common.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final cur = bank.currency;
    final activeEmployees =
        bank.users.where((u) => u.role == UserRole.employee && u.isActive).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel Bakış',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toplam ${bank.companies.length} şirket ve $activeEmployees aktif çalışan kayıtlı.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // İstatistik Kartları
          LayoutBuilder(builder: (context, c) {
            final count = c.maxWidth > 900 ? 4 : (c.maxWidth > 550 ? 2 : 1);
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  title: 'Toplam Şirket Bakiyesi',
                  value: money(bank.totalCompanyBalance, cur),
                  icon: Icons.business_outlined,
                  color: Colors.indigo,
                  subtitle: '${bank.companies.length} şirket hesabı',
                ),
                StatCard(
                  title: 'Toplam Kullanıcı Bakiyesi',
                  value: money(bank.totalUserBalance, cur),
                  icon: Icons.people_alt_outlined,
                  color: Colors.teal,
                  subtitle: '${bank.users.length} kullanıcı hesabı',
                ),
                StatCard(
                  title: 'Aylık Toplam Maaş Yükü',
                  value: money(bank.totalMonthlySalaries, cur),
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                  subtitle: '$activeEmployees aktif çalışan',
                ),
                StatCard(
                  title: 'Toplam İşlem Sayısı',
                  value: bank.transactions.length.toString(),
                  icon: Icons.receipt_long_outlined,
                  color: Colors.orange,
                  subtitle: 'Tüm sistem hareketleri',
                ),
              ],
            );
          }),

          const SizedBox(height: 28),
          Text(
            'Hızlı İşlemler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Vadesi Gelen Maaşları Öde'),
                onPressed: () {
                  final n = bank.processDueSalaries();
                  if (n > 0) {
                    showSnackBar(context, '$n çalışana maaş ödemesi yapıldı.');
                  } else {
                    showSnackBar(context, 'Bugün vadesi gelen veya ödenebilecek maaş bulunmuyor.');
                  }
                },
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Rastgele Kredi Kesintisi Uygula'),
                onPressed: () {
                  final n = bank.applyRandomDeductionsToAll();
                  if (n > 0) {
                    showSnackBar(context, '$n çalışandan rastgele kredi kesintisi yapıldı.');
                  } else {
                    showSnackBar(context, 'Kesinti yapılabilecek bakiyeli aktif çalışan bulunamadı.');
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 28),
          Text(
            'Son İşlem Hareketleri',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: bank.transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Henüz bir işlem kaydedilmedi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bank.transactions.take(10).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = bank.transactions[i];
                      final isZero = t.amount == 0;
                      final isDeduction = t.type == TxnType.penalty ||
                          t.type == TxnType.randomDeduction ||
                          t.type == TxnType.terminationFee;

                      String sign = '';
                      if (!isZero) {
                        sign = isDeduction ? '-' : '+';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              TxnIcon.colorOf(t.type).withAlpha(38),
                          child: Icon(
                            TxnIcon.of(t.type),
                            color: TxnIcon.colorOf(t.type),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          t.type.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '$sign${money(t.amount, cur)}',
                          style: TextStyle(
                            color: isZero ? Colors.grey : TxnIcon.colorOf(t.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
