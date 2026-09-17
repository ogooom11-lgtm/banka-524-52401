import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bank_provider.dart';
import '../widgets/common.dart';
import 'tabs/companies_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/overview_tab.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _index = 0;

  final _tabs = const [
    OverviewTab(),
    CompaniesTab(),
    UsersTab(),
    TransactionsTab(),
    SettingsTab(),
  ];

  final _titles = const [
    'Genel Bakış',
    'Şirketler',
    'Kullanıcılar',
    'İşlem Geçmişi',
    'Ayarlar',
  ];

  final _icons = const [
    Icons.dashboard_outlined,
    Icons.business_outlined,
    Icons.people_outline,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  void _editAdminName(BuildContext context, AppUser u) {
    final nameCtrl = TextEditingController(text: u.fullName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yönetici İsmini Düzenle'),
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
                  showSnackBar(context, 'Yönetici adı güncellendi.');
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
                showSnackBar(context, 'Yönetici adı güncellendi.');
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

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                bank.bankName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                'SÜPER ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tüm vadesi gelen maaşları öde',
            icon: const Icon(Icons.payments_outlined),
            onPressed: () {
              final n = bank.processDueSalaries();
              if (n > 0) {
                showSnackBar(context, '$n kullanıcıya maaş ödendi.');
              } else {
                showSnackBar(context, 'Ödenecek vadesi gelen maaş bulunamadı.');
              }
            },
          ),
          IconButton(
            tooltip: 'Rastgele kredi kesintilerini uygula',
            icon: const Icon(Icons.casino_outlined),
            onPressed: () {
              final n = bank.applyRandomDeductionsToAll();
              if (n > 0) {
                showSnackBar(context, '$n kullanıcıya kesinti uygulandı.');
              } else {
                showSnackBar(
                    context, 'Kesinti yapılabilecek bakiyeli kullanıcı bulunamadı.');
              }
            },
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final u = bank.currentUser;
              if (u != null) _editAdminName(context, u);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bank.currentUser?.fullName ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: () => bank.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  extended: true,
                  minExtendedWidth: 200,
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_titles[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _tabs[_index]),
              ],
            )
          : Column(
              children: [
                Expanded(child: _tabs[_index]),
                NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationDestination(
                        icon: Icon(_icons[i]),
                        label: _titles[i],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
