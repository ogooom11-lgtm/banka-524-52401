import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_provider.dart';
import '../../models/bank_settings.dart';
import '../../widgets/common.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _bankName;
  late TextEditingController _adminName;
  late TextEditingController _currency;
  late TextEditingController _dedMin;
  late TextEditingController _dedMax;
  late TextEditingController _salaryDay;

  @override
  void initState() {
    super.initState();
    final bank = context.read<BankProvider>();
    final s = bank.settings;
    _bankName = TextEditingController(text: s.bankName);
    _adminName = TextEditingController(
        text: bank.currentUser?.fullName ?? 'Banka Sahibi');
    _currency = TextEditingController(text: s.currency);
    _dedMin =
        TextEditingController(text: s.randomDeductionMin.toStringAsFixed(0));
    _dedMax =
        TextEditingController(text: s.randomDeductionMax.toStringAsFixed(0));
    _salaryDay = TextEditingController(text: s.salaryDay.toString());
  }

  void _syncControllersWithSettings() {
    final bank = context.read<BankProvider>();
    final s = bank.settings;
    _bankName.text = s.bankName;
    _adminName.text = bank.currentUser?.fullName ?? 'Banka Sahibi';
    _currency.text = s.currency;
    _dedMin.text = s.randomDeductionMin.toStringAsFixed(0);
    _dedMax.text = s.randomDeductionMax.toStringAsFixed(0);
    _salaryDay.text = s.salaryDay.toString();
  }

  @override
  void dispose() {
    _bankName.dispose();
    _adminName.dispose();
    _currency.dispose();
    _dedMin.dispose();
    _dedMax.dispose();
    _salaryDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<BankProvider>().currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Banka ve Sistem Ayarları',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Banka genel kurallarını, para birimini ve kesinti limitlerini yapılandırın.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genel Parametreler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adminName,
                    decoration: const InputDecoration(
                      labelText: 'Yönetici Adı (Süper Admin)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bankName,
                    decoration: const InputDecoration(
                      labelText: 'Banka Adı',
                      prefixIcon: Icon(Icons.account_balance),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi Sembolü (Örn: ₺, \$, €, ر.ق)',
                      prefixIcon: Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _salaryDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Varsayılan Aylık Maaş Günü (1 - 31)',
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rastgele Kredi Kesintisi Aralıkları',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Çalışan hesaplarından otomatik rastgele kesinti yapılacak alt ve üst limitler:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dedMin,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Minimum Kesinti ($cur)',
                            prefixIcon: const Icon(Icons.trending_down),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _dedMax,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Maksimum Kesinti ($cur)',
                            prefixIcon: const Icon(Icons.trending_up),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Ayarları Kaydet'),
              onPressed: () {
                final adminName = _adminName.text.trim();
                final name = _bankName.text.trim();
                final currencySym = _currency.text.trim();
                final sDay = int.tryParse(_salaryDay.text.trim());
                final minD = double.tryParse(
                    _dedMin.text.trim().replaceAll(',', '.'));
                final maxD = double.tryParse(
                    _dedMax.text.trim().replaceAll(',', '.'));

                if (adminName.isEmpty) {
                  showSnackBar(context, 'Yönetici adı boş bırakılamaz.',
                      error: true);
                  return;
                }
                if (name.isEmpty) {
                  showSnackBar(context, 'Banka adı boş bırakılamaz.',
                      error: true);
                  return;
                }
                if (currencySym.isEmpty) {
                  showSnackBar(context, 'Para birimi sembolü boş bırakılamaz.',
                      error: true);
                  return;
                }
                if (sDay == null || sDay < 1 || sDay > 31) {
                  showSnackBar(
                      context, 'Maaş günü 1 ile 31 arasında geçerli bir sayı olmalıdır.',
                      error: true);
                  return;
                }
                if (minD == null || minD < 0 || maxD == null || maxD < 0) {
                  showSnackBar(
                      context, 'Kesinti limitleri sıfırdan küçük olamaz.',
                      error: true);
                  return;
                }
                if (minD > maxD) {
                  showSnackBar(
                      context, 'Minimum kesinti maksimum kesintiden büyük olamaz.',
                      error: true);
                  return;
                }

                try {
                  final bank = context.read<BankProvider>();
                  final s = BankSettings(
                    bankName: name,
                    currency: currencySym,
                    salaryDay: sDay,
                    randomDeductionMin: minD,
                    randomDeductionMax: maxD,
                  );
                  bank.updateSettings(s);
                  final current = bank.currentUser;
                  if (current != null && current.fullName != adminName) {
                    bank.updateUserName(current.id, adminName);
                  }
                  showSnackBar(context, 'Banka ayarları başarıyla kaydedildi.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
            ),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Tehlikeli Bölge',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tüm şirketleri, kullanıcıları, işlemleri ve ayarları varsayılan başlangıç demo durumuna sıfırlar.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore, color: Colors.red),
            label: const Text('Tüm Verileri Sıfırla',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => showConfirmDialog(
              context,
              title: 'Tüm Verileri Sıfırla',
              message:
                  'Tüm şirketler, çalışanlar ve işlem geçmişi kalıcı olarak silinecek ve başlangıç demo verilerine dönülecektir. Bu işlem geri alınamaz!\n\nDevam etmek istiyor musunuz?',
              confirmText: 'Sıfırla',
              confirmColor: Colors.red,
              onConfirm: () {
                context.read<BankProvider>().resetAll();
                _syncControllersWithSettings();
                showSnackBar(
                    context, 'Tüm veriler varsayılan duruma sıfırlandı.');
              },
            ),
          ),
        ],
      ),
    );
  }
}
