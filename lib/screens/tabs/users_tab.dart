import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/bank_provider.dart';
import '../../widgets/common.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _nameSearch = TextEditingController();
  final _companySearch = TextEditingController();
  final _titleSearch = TextEditingController();

  @override
  void dispose() {
    _nameSearch.dispose();
    _companySearch.dispose();
    _titleSearch.dispose();
    super.dispose();
  }

  List<AppUser> _filtered(BankProvider bank) {
    var employees =
        bank.users.where((u) => u.role != UserRole.superAdmin).toList();

    final nameQ = _nameSearch.text.trim().toLowerCase();
    final companyQ = _companySearch.text.trim().toLowerCase();
    final titleQ = _titleSearch.text.trim().toLowerCase();

    if (nameQ.isNotEmpty) {
      employees = employees
          .where((u) => u.fullName.toLowerCase().contains(nameQ))
          .toList();
    }
    if (companyQ.isNotEmpty) {
      employees = employees.where((u) {
        final company = bank.companyById(u.companyId);
        final cname = (company?.name ?? 'şirketsiz').toLowerCase();
        return cname.contains(companyQ);
      }).toList();
    }
    if (titleQ.isNotEmpty) {
      employees = employees
          .where((u) => u.title.toLowerCase().contains(titleQ))
          .toList();
    }
    return employees;
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final employees = _filtered(bank);
    final totalEmployees =
        bank.users.where((u) => u.role != UserRole.superAdmin).length;
    final cur = bank.currency;
    final hasQuery = _nameSearch.text.trim().isNotEmpty ||
        _companySearch.text.trim().isNotEmpty ||
        _titleSearch.text.trim().isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('TXT ile Kullanıcı Ekle'),
                      onPressed: () => _importFromTxt(context),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Toplu Prim Dağıt'),
                      onPressed: () => _bulkBonus(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, c) {
                  final wide = c.maxWidth >= 780;
                  final fields = [
                    _searchField(
                      controller: _nameSearch,
                      label: 'Ada göre ara',
                      icon: Icons.person_search,
                    ),
                    _searchField(
                      controller: _companySearch,
                      label: 'Şirkete göre ara',
                      icon: Icons.business,
                    ),
                    _searchField(
                      controller: _titleSearch,
                      label: 'Unvana göre ara',
                      icon: Icons.badge_outlined,
                    ),
                  ];
                  if (wide) {
                    return Row(
                      children: [
                        for (int i = 0; i < fields.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: fields[i]),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < fields.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        fields[i],
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  hasQuery
                      ? '$totalEmployees kullanıcıdan ${employees.length} sonuç'
                      : '$totalEmployees kayıtlı kullanıcı',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Text(
                      totalEmployees == 0
                          ? 'Henüz kayıtlı çalışan bulunmuyor.\n"Yeni Kullanıcı" veya "TXT ile Kullanıcı Ekle" ile ekleyebilirsiniz.'
                          : 'Arama kriterlerine uygun kullanıcı bulunamadı.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                    itemCount: employees.length,
                    itemBuilder: (context, i) {
                      final u = employees[i];
                      final company = bank.companyById(u.companyId);
                      final contractDays =
                          u.contractEnd.difference(DateTime.now()).inDays;
                      final isExpired = u.contractEnd.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(
                              side: BorderSide.none),
                          leading: CircleAvatar(
                            backgroundColor: u.isActive
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Colors.grey.withAlpha(77),
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: u.isActive
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'İsmi Düzenle',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _editName(context, u),
                              ),
                              if (!u.isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(51),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.red.shade400),
                                  ),
                                  child: const Text('PASİF',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${u.title} • ${company?.name ?? "Şirketsiz"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            money(u.balance, cur),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Aylık Maaş', money(u.salary, cur)),
                                  _infoRow('Aylık Prim', money(u.bonus, cur)),
                                  _infoRow('Maaş Günü',
                                      'Her ayın ${u.salaryDate.day}. günü'),
                                  _infoRow(
                                      'Sözleşme Bitiş',
                                      DateFormat('dd.MM.yyyy')
                                          .format(u.contractEnd)),
                                  _infoRow('Erken Fesih Tazminatı',
                                      money(u.terminationFee, cur)),
                                  if (isExpired)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                          '⚠️ Sözleşme süresi dolmuş',
                                          style: TextStyle(
                                              color: Colors.orange)),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '⏳ Kalan süre: $contractDays gün',
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12),
                                      ),
                                    ),
                                  const Divider(height: 24),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.tonalIcon(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 18),
                                        label: const Text('İsmi Düzenle'),
                                        onPressed: () => _editName(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(
                                            Icons.payments_outlined,
                                            size: 18),
                                        label: const Text('Maaş Öde'),
                                        onPressed: () => _paySalary(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(Icons.card_giftcard,
                                            size: 18),
                                        label: const Text('Prim Ver'),
                                        onPressed: () => _bonus(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 18,
                                            color: Colors.orange),
                                        label: const Text('Ceza Uygula'),
                                        onPressed: () => _penalty(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(Icons.trending_up,
                                            size: 18, color: Colors.green),
                                        label: const Text('Terfi Ettir'),
                                        onPressed: () => _promote(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(Icons.casino_outlined,
                                            size: 18),
                                        label: const Text('Kesinti Yap'),
                                        onPressed: () {
                                          final d = bank
                                              .applyRandomDeduction(u.id);
                                          if (d > 0) {
                                            showSnackBar(context,
                                                '${money(d, cur)} kesinti yapıldı.');
                                          } else {
                                            showSnackBar(
                                                context,
                                                'Kullanıcı bakiyesi yetersiz olduğu için kesinti yapılamadı.',
                                                error: true);
                                          }
                                        },
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(Icons.swap_horiz,
                                            size: 18),
                                        label: const Text('Şirket Değiştir'),
                                        onPressed: () =>
                                            _transfer(context, u),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(
                                            Icons.description_outlined,
                                            size: 18),
                                        label: const Text('Sözleşme Yenile'),
                                        onPressed: () =>
                                            _renewContract(context, u),
                                      ),
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 18),
                                        label: const Text('İşlem Geçmişi'),
                                        onPressed: () =>
                                            _showHistory(context, u),
                                      ),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.red),
                                        label: const Text('Sil',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () => showConfirmDialog(
                                          context,
                                          title: 'Kullanıcıyı Sil',
                                          message:
                                              '"${u.fullName}" adlı kullanıcıyı sistemden silmek istediğinize emin misiniz?',
                                          confirmText: 'Kullanıcıyı Sil',
                                          confirmColor: Colors.red,
                                          onConfirm: () {
                                            bank.deleteUser(u.id);
                                            showSnackBar(context,
                                                'Kullanıcı silindi.');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Kullanıcı'),
        onPressed: () => _addUser(context),
      ),
    );
  }

  Widget _searchField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
              )
            : null,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
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
                labelText: 'Ad Soyad',
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
                  showSnackBar(
                      context, 'Kullanıcı adı "$clean" olarak güncellendi.');
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
                showSnackBar(
                    context, 'Kullanıcı adı "$clean" olarak güncellendi.');
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

  void _paySalary(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    try {
      bank.paySalary(u.id);
      showSnackBar(context,
          '${u.fullName} adlı çalışana ${money(u.salary, bank.currency)} maaş ödendi.');
    } catch (e) {
      showSnackBar(context, e.toString().replaceAll('Exception: ', ''),
          error: true);
    }
  }

  void _bonus(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Performans Primi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Prim Tutarı ($cur)',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Prim Açıklaması / Not',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
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
              final raw = ctrl.text.trim().replaceAll(',', '.');
              final v = double.tryParse(raw);
              if (v == null || v <= 0) {
                showSnackBar(
                    context, 'Geçerli ve pozitif bir prim tutarı girin.',
                    error: true);
                return;
              }
              try {
                context.read<BankProvider>().giveBonus(
                      u.id,
                      v,
                      noteCtrl.text.isEmpty
                          ? 'Performans primi'
                          : noteCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
                showSnackBar(context,
                    '${u.fullName} adlı çalışana ${money(v, cur)} prim verildi.');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Primi Ver'),
          ),
        ],
      ),
    );
  }

  void _bulkBonus(BuildContext context) {
    final bank = context.read<BankProvider>();
    if (bank.companies.isEmpty) {
      showSnackBar(context, 'Önce bir şirket oluşturmalısınız.', error: true);
      return;
    }

    String? companyId = bank.companies.first.id;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Şirket geneli toplu prim');
    final cur = bank.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final selected = companyId == null
              ? null
              : bank.companyById(companyId);
          final empCount = companyId == null
              ? 0
              : bank
                  .usersOfCompany(companyId!)
                  .where((u) => u.isActive && u.role != UserRole.superAdmin)
                  .length;
          final raw = amountCtrl.text.trim().replaceAll(',', '.');
          final unit = double.tryParse(raw);
          final total = (unit != null && unit > 0) ? unit * empCount : 0.0;

          return AlertDialog(
            title: const Text('Toplu Prim Dağıt'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: companyId,
                    decoration: const InputDecoration(
                      labelText: 'Şirket',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: bank.companies
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => companyId = v),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected == null
                        ? ''
                        : '${selected.name} • $empCount aktif çalışan • Bakiye: ${money(selected.balance, cur)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Çalışan başına prim ($cur)',
                      prefixIcon: const Icon(Icons.card_giftcard),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (empCount > 0 && total > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Toplam maliyet: ${money(total, cur)} ($empCount × ${money(unit!, cur)})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (companyId == null) return;
                  final v = double.tryParse(
                      amountCtrl.text.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    showSnackBar(context, 'Geçerli bir prim tutarı girin.',
                        error: true);
                    return;
                  }
                  try {
                    final n = bank.giveBonusToCompany(
                      companyId!,
                      v,
                      noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    showSnackBar(context,
                        '$n çalışana ${money(v, cur)} prim dağıtıldı.');
                  } catch (e) {
                    showSnackBar(
                        context, e.toString().replaceAll('Exception: ', ''),
                        error: true);
                  }
                },
                child: const Text('Dağıt'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importFromTxt(BuildContext context) async {
    final bank = context.read<BankProvider>();
    if (bank.companies.isEmpty) {
      showSnackBar(context, 'Önce bir şirket oluşturmalısınız.', error: true);
      return;
    }

    String? companyId = bank.companies.first.id;
    String? fileName;
    String rawText = '';
    final pasteCtrl = TextEditingController();
    final cur = bank.currency;

    List<String> parseNames(String content) {
      final names = <String>[];
      final seen = <String>{};
      for (final line in content.split(RegExp(r'[\r\n]+'))) {
        for (final part in line.split(RegExp(r'[,;|]'))) {
          final n = part.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (n.isEmpty) continue;
          if (seen.add(n.toLowerCase())) names.add(n);
        }
      }
      return names;
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final company = companyId == null ? null : bank.companyById(companyId);
          final names = parseNames(
              rawText.isNotEmpty ? rawText : pasteCtrl.text);

          return AlertDialog(
            title: const Text('TXT ile Kullanıcı Ekle'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: companyId,
                      decoration: const InputDecoration(
                        labelText: 'Hedef Şirket',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      items: bank.companies
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => companyId = v),
                    ),
                    const SizedBox(height: 12),
                    if (company != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx)
                              .colorScheme
                              .primaryContainer
                              .withAlpha(90),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Her isim için otomatik uygulanır:\n'
                          '• Maaş: ${company.name} maaş sınırı (${money(company.salaryLimit, cur)}) içinde dağıtılır\n'
                          '• Sözleşme süresi: 1 ile 5 yıl arası\n'
                          '• Fesih cezası: maaşın 2 veya 3 katı',
                          style: const TextStyle(fontSize: 12, height: 1.45),
                        ),
                      ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const ['txt'],
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final file = result.files.single;
                          String content = '';
                          if (file.bytes != null) {
                            content = utf8.decode(file.bytes!,
                                allowMalformed: true);
                          }
                          setS(() {
                            fileName = file.name;
                            rawText = content;
                            pasteCtrl.text = content;
                          });
                        } catch (e) {
                          showSnackBar(
                              context, 'Dosya okunamadı: $e',
                              error: true);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(ctx).colorScheme.outline,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file,
                                size: 36,
                                color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              fileName == null
                                  ? 'TXT dosyası ekleme boşluğu'
                                  : fileName!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileName == null
                                  ? 'Tıklayın ve her satırda bir isim olan .txt dosyasını seçin'
                                  : '${parseNames(rawText).length} isim okundu',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pasteCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'veya isimleri buraya yapıştırın',
                        hintText: 'Ahmet Yılmaz\nAyşe Demir\nMehmet Kaya',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setS(() {}),
                    ),
                    if (names.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Önizleme: ${names.length} kullanıcı eklenecek',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: names.length > 8 ? 8 : names.length,
                          itemBuilder: (_, i) => Text(
                            '• ${names[i]}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      if (names.length > 8)
                        Text(
                          '+${names.length - 8} isim daha…',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (companyId == null) return;
                  final list = parseNames(
                      pasteCtrl.text.isNotEmpty ? pasteCtrl.text : rawText);
                  if (list.isEmpty) {
                    showSnackBar(context,
                        'TXT dosyası seçin veya en az bir isim girin.',
                        error: true);
                    return;
                  }
                  try {
                    final result = bank.importUsersFromNames(
                      names: list,
                      companyId: companyId!,
                    );
                    Navigator.pop(ctx);
                    final extra = result.skipped.isEmpty
                        ? ''
                        : ' ${result.skipped.length} isim atlandı.';
                    showSnackBar(context,
                        '${result.added} kullanıcı eklendi.$extra');
                  } catch (e) {
                    showSnackBar(
                        context, e.toString().replaceAll('Exception: ', ''),
                        error: true);
                  }
                },
                child: const Text('Kullanıcıları Ekle'),
              ),
            ],
          );
        },
      ),
    );
    pasteCtrl.dispose();
  }

  void _penalty(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isPercent = false;
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${u.fullName} - Ceza Uygula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isPercent
                      ? 'Maaş Yüzdesi (%)'
                      : 'Sabit Ceza Tutarı ($cur)',
                  prefixIcon:
                      Icon(isPercent ? Icons.percent : Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maaş üzerinden yüzde olarak kes'),
                value: isPercent,
                onChanged: (v) => setS(() => isPercent = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ceza Nedeni / Açıklama',
                  prefixIcon: Icon(Icons.warning_amber),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                final v = double.tryParse(raw);
                if (v == null || v <= 0) {
                  showSnackBar(
                      context, 'Lütfen geçerli ve pozitif bir değer girin.',
                      error: true);
                  return;
                }
                if (isPercent && v > 100) {
                  showSnackBar(context, 'Yüzde 100\'den fazla olamaz.',
                      error: true);
                  return;
                }

                try {
                  context.read<BankProvider>().applyPenalty(
                        u.id,
                        v,
                        reasonCtrl.text.isEmpty
                            ? 'Disiplin cezası'
                            : reasonCtrl.text.trim(),
                        percentage: isPercent,
                      );
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Ceza başarıyla uygulandı.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Cezayı Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _promote(BuildContext context, AppUser u) {
    final titleCtrl = TextEditingController(text: u.title);
    final salaryCtrl =
        TextEditingController(text: (u.salary * 1.2).toStringAsFixed(0));
    final bonusCtrl = TextEditingController(text: '0');
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Terfi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Yeni Unvan',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Yeni Aylık Maaş ($cur)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bonusCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Terfi Primi (Opsiyonel $cur)',
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = titleCtrl.text.trim();
              final rawSalary = salaryCtrl.text.trim().replaceAll(',', '.');
              final rawBonus = bonusCtrl.text.trim().replaceAll(',', '.');
              final s = double.tryParse(rawSalary);
              final b = double.tryParse(rawBonus) ?? 0;

              if (newTitle.isEmpty) {
                showSnackBar(context, 'Unvan boş bırakılamaz.', error: true);
                return;
              }
              if (s == null || s < 0) {
                showSnackBar(context, 'Geçerli bir yeni maaş girin.',
                    error: true);
                return;
              }
              if (b < 0) {
                showSnackBar(context, 'Terfi primi negatif olamaz.',
                    error: true);
                return;
              }

              try {
                context.read<BankProvider>().promote(u.id, newTitle, s, b);
                Navigator.pop(ctx);
                showSnackBar(
                    context, '${u.fullName} terfi ettirildi ($newTitle).');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Terfi Ettir'),
          ),
        ],
      ),
    );
  }

  void _transfer(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    final cur = bank.currency;
    final otherCompanies =
        bank.companies.where((c) => c.id != u.companyId).toList();

    if (otherCompanies.isEmpty) {
      showSnackBar(
          context, 'Transfer edilebilecek başka bir şirket bulunmuyor.',
          error: true);
      return;
    }

    String? targetId = otherCompanies.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${u.fullName} - Şirket Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (u.contractEnd.isAfter(DateTime.now()) &&
                  u.terminationFee > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sözleşme henüz dolmadı. Çalışandan ${money(u.terminationFee, cur)} fesih tazminatı kesilecektir.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              DropdownButtonFormField<String>(
                value: targetId,
                decoration: const InputDecoration(
                  labelText: 'Hedef Şirket',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: otherCompanies
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setS(() => targetId = v),
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
                if (targetId == null) return;
                try {
                  bank.transferEmployee(u.id, targetId!);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Çalışan başarıyla transfer edildi.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Transfer Et'),
            ),
          ],
        ),
      ),
    );
  }

  void _renewContract(BuildContext context, AppUser u) {
    final monthsCtrl = TextEditingController(text: '12');
    final feeCtrl =
        TextEditingController(text: u.terminationFee.toStringAsFixed(0));
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Sözleşme Yenile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uzatma Süresi (Ay)',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Erken Fesih Ücreti ($cur)',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
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
              final m = int.tryParse(monthsCtrl.text);
              final rawFee = feeCtrl.text.trim().replaceAll(',', '.');
              final f = double.tryParse(rawFee);

              if (m == null || m <= 0) {
                showSnackBar(
                    context, 'Sözleşme süresi en az 1 ay olmalıdır.',
                    error: true);
                return;
              }
              if (f == null || f < 0) {
                showSnackBar(context, 'Fesih ücreti negatif olamaz.',
                    error: true);
                return;
              }

              try {
                context.read<BankProvider>().renewContract(u.id, m, f);
                Navigator.pop(ctx);
                showSnackBar(context, 'Sözleşme $m ay uzatıldı.');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    final txns = bank.txnsOfUser(u.id);
    final cur = bank.currency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${u.fullName} - İşlem Geçmişi',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: txns.isEmpty
                  ? const Center(
                      child: Text(
                        'Bu kullanıcıya ait kayıtlı bir işlem bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final t = txns[i];
                        final isIncoming = t.toId == u.id && t.fromId != u.id;
                        final isZero = t.amount == 0;

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
                            isZero
                                ? money(0, cur)
                                : '${isIncoming ? '+' : '-'}${money(t.amount, cur)}',
                            style: TextStyle(
                              color: isZero
                                  ? Colors.grey
                                  : (isIncoming ? Colors.green : Colors.red),
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
      ),
    );
  }

  void _addUser(BuildContext context) {
    final bank = context.read<BankProvider>();
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController(text: '30000');
    final feeCtrl = TextEditingController(text: '60000');
    final salaryDayCtrl =
        TextEditingController(text: bank.settings.salaryDay.toString());
    final contractMonthsCtrl = TextEditingController(text: '12');

    String? selectedCompanyId =
        bank.companies.isNotEmpty ? bank.companies.first.id : null;
    final cur = bank.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final selected = selectedCompanyId == null
              ? null
              : bank.companyById(selectedCompanyId);
          return AlertDialog(
            title: const Text('Yeni Çalışan Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Bağlı Olacağı Şirket',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Şirketsiz / Bağımsız'),
                      ),
                      ...bank.companies.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (v) {
                      setS(() {
                        selectedCompanyId = v;
                        final c = v == null ? null : bank.companyById(v);
                        if (c != null && c.salaryLimit > 0) {
                          final suggested =
                              (c.salaryLimit * 0.8).round().toString();
                          salaryCtrl.text = suggested;
                          feeCtrl.text =
                              ((c.salaryLimit * 0.8) * 2).round().toString();
                        }
                      });
                    },
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Şirket maaş sınırı: ${money(selected.salaryLimit, cur)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: salaryCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Aylık Maaş ($cur)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: salaryDayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maaş Günü (1-31)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: contractMonthsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sözleşme (Ay)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Fesih Tazminatı ($cur)',
                      prefixIcon: const Icon(Icons.security),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final rawSalary =
                      salaryCtrl.text.trim().replaceAll(',', '.');
                  final rawFee = feeCtrl.text.trim().replaceAll(',', '.');
                  final salary = double.tryParse(rawSalary);
                  final fee = double.tryParse(rawFee);
                  final sDay = int.tryParse(salaryDayCtrl.text) ?? 1;
                  final cMonths = int.tryParse(contractMonthsCtrl.text) ?? 12;

                  if (name.isEmpty) {
                    showSnackBar(context, 'Ad Soyad boş bırakılamaz.',
                        error: true);
                    return;
                  }
                  if (salary == null || salary < 0) {
                    showSnackBar(context, 'Geçerli bir maaş girin.',
                        error: true);
                    return;
                  }
                  if (fee == null || fee < 0) {
                    showSnackBar(context, 'Fesih tazminatı negatif olamaz.',
                        error: true);
                    return;
                  }
                  if (sDay < 1 || sDay > 31) {
                    showSnackBar(
                        context, 'Maaş günü 1 ile 31 arasında olmalıdır.',
                        error: true);
                    return;
                  }
                  if (cMonths < 1) {
                    showSnackBar(
                        context, 'Sözleşme süresi en az 1 ay olmalıdır.',
                        error: true);
                    return;
                  }

                  final now = DateTime.now();
                  try {
                    bank.addUser(
                      fullName: name,
                      role: UserRole.employee,
                      companyId: selectedCompanyId,
                      salary: salary,
                      salaryDate: DateTime(
                          now.year, now.month, sDay.clamp(1, 28)),
                      contractEnd: now.add(Duration(days: cMonths * 30)),
                      terminationFee: fee,
                    );
                    Navigator.pop(ctx);
                    showSnackBar(
                        context, '"$name" adlı çalışan oluşturuldu.');
                  } catch (e) {
                    showSnackBar(
                        context, e.toString().replaceAll('Exception: ', ''),
                        error: true);
                  }
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }
}
