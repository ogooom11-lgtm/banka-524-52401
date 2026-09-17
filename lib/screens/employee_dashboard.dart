import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bank_provider.dart';
import '../widgets/common.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final _transferCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _targetUserId;

  @override
  void dispose() {
    _transferCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final u = bank.currentUser;
    if (u == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final company = bank.companyById(u.companyId);
    final txns = bank.txnsOfUser(u.id);
    final cur = bank.currency;
    final now = DateTime.now();
    final daysLeft = u.contractEnd.difference(now).inDays;

    String contractText;
    Color contractColor;
    if (u.contractEnd.isBefore(now)) {
      contractText = 'Süresi Doldu';
      contractColor = Colors.red;
    } else if (daysLeft == 0) {
      contractText = 'Bugün Son Gün';
      contractColor = Colors.orange;
    } else {
      contractText = '$daysLeft gün kaldı';
      contractColor = Colors.blue;
    }

    final availableRecipients =
        bank.users.where((x) => x.id != u.id && x.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet),
            const SizedBox(width: 8),
            Text(bank.bankName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: () => bank.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karşılama Kartı
              Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Merhaba, ${u.fullName}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.white70, size: 20),
                            tooltip: 'İsmi Düzenle',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _editName(context, u),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${u.title} • ${company?.name ?? "Bağımsız / Şirketsiz"}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kullanılabilir Bakiye',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(u.balance, cur),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hızlı Bilgi Kartları
              LayoutBuilder(builder: (context, c) {
                final count = c.maxWidth > 700 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: count == 3 ? 2.0 : 2.6,
                  children: [
                    StatCard(
                      title: 'Aylık Maaş',
                      value: money(u.salary, cur),
                      icon: Icons.payments_outlined,
                      color: Colors.green,
                      subtitle:
                          'Maaş Günü: Her ayın ${u.salaryDate.day}. günü',
                    ),
                    StatCard(
                      title: 'Aylık Prim',
                      value: money(u.bonus, cur),
                      icon: Icons.card_giftcard,
                      color: Colors.purple,
                      subtitle: 'Performansa dayalı prim',
                    ),
                    StatCard(
                      title: 'Sözleşme Durumu',
                      value: contractText,
                      icon: Icons.description_outlined,
                      color: contractColor,
                      subtitle:
                          'Bitiş: ${DateFormat('dd.MM.yyyy').format(u.contractEnd)}',
                    ),
                  ],
                );
              }),

              const SizedBox(height: 28),
              Text(
                'Para Transferi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: availableRecipients
                                .any((r) => r.id == _targetUserId)
                            ? _targetUserId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Alıcı Seçin',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: availableRecipients
                            .map((x) => DropdownMenuItem(
                                  value: x.id,
                                  child: Text('${x.fullName} (${x.email})'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _targetUserId = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _transferCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Tutar ($cur)',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama (opsiyonel)',
                          prefixIcon: Icon(Icons.notes),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Transferi Gerçekleştir'),
                          onPressed: _sendTransfer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Text(
                'İşlem Geçmişi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: txns.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Henüz kayıtlı işlem bulunmuyor.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txns.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = txns[i];
                          final isIn = t.toId == u.id && t.fromId != u.id;
                          final isZero = t.amount == 0;

                          String prefix = '';
                          Color amountColor = Colors.grey;

                          if (!isZero) {
                            if (isIn) {
                              prefix = '+';
                              amountColor = Colors.green;
                            } else {
                              prefix = '-';
                              amountColor = Colors.red;
                            }
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              '$prefix${money(t.amount, cur)}',
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editName(BuildContext context, AppUser u) {
    final nameCtrl = TextEditingController(text: u.fullName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İsmi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                final clean = nameCtrl.text.trim();
                if (clean.isEmpty) {
                  showSnackBar(context, 'Ad Soyad boş bırakılamaz.',
                      error: true);
                  return;
                }
                try {
                  context.read<BankProvider>().updateUserName(u.id, clean);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'İsminiz başarıyla güncellendi.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final clean = nameCtrl.text.trim();
              if (clean.isEmpty) {
                showSnackBar(context, 'Ad Soyad boş bırakılamaz.',
                    error: true);
                return;
              }
              try {
                context.read<BankProvider>().updateUserName(u.id, clean);
                Navigator.pop(ctx);
                showSnackBar(context, 'İsminiz başarıyla güncellendi.');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _sendTransfer() {
    final bank = context.read<BankProvider>();
    final rawText = _transferCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(rawText);

    if (amount == null || amount <= 0) {
      showSnackBar(context, 'Lütfen geçerli ve pozitif bir tutar girin.',
          error: true);
      return;
    }
    if (_targetUserId == null) {
      showSnackBar(context, 'Lütfen parayı göndereceğiniz alıcıyı seçin.',
          error: true);
      return;
    }
    if (bank.currentUser == null) return;

    if (amount > bank.currentUser!.balance) {
      showSnackBar(context,
          'Yetersiz bakiye. Mevcut bakiyeniz: ${money(bank.currentUser!.balance, bank.currency)}',
          error: true);
      return;
    }

    try {
      bank.userTransfer(
        bank.currentUser!.id,
        _targetUserId!,
        amount,
        _noteCtrl.text.isEmpty
            ? 'Hesaplar arası para transferi'
            : _noteCtrl.text.trim(),
      );
      _transferCtrl.clear();
      _noteCtrl.clear();
      setState(() => _targetUserId = null);
      showSnackBar(context, '${money(amount, bank.currency)} başarıyla transfer edildi.');
    } catch (e) {
      showSnackBar(context, e.toString().replaceAll('Exception: ', ''),
          error: true);
    }
  }
}
