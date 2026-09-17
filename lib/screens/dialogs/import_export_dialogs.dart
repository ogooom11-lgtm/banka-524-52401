import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';

/// TXT (isim listesi) veya CSV (tam veri) içe aktarma diyaloğu.
Future<void> showImportDialog(
  BuildContext context, {
  String? companyId,
  bool startWithCsv = false,
}) async {
  await showAppDialog<void>(
    context,
    title: 'İçe Aktarma Sihirbazı',
    subtitle:
        'TXT: her satırda bir isim. CSV: ad, e-posta, unvan, maaş, şirket kolonları.',
    icon: Icons.upload_file_outlined,
    maxWidth: 760,
    scrollable: false,
    child: _ImportWizard(
      initialCompanyId: companyId,
      startWithCsv: startWithCsv,
    ),
  );
}

class _ImportWizard extends StatefulWidget {
  final String? initialCompanyId;
  final bool startWithCsv;

  const _ImportWizard({this.initialCompanyId, this.startWithCsv = false});

  @override
  State<_ImportWizard> createState() => _ImportWizardState();
}

class _ImportWizardState extends State<_ImportWizard> {
  late bool _csvMode = widget.startWithCsv;
  late String? _companyId = widget.initialCompanyId;
  final _text = TextEditingController();
  bool _busy = false;
  String? _fileName;
  String? _error;
  ImportUsersResult? _result;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankProvider>();
    if (_companyId == null && bank.companies.isNotEmpty) {
      _companyId = bank.companies.first.id;
    }
    final lines = ExportService.txtToLines(_text.text);
    final csvRows = _text.text.trim().isEmpty
        ? 0
        : ExportService.csvDecode(_text.text).length;
    final company = bank.companyById(_companyId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('TXT • İsim listesi'),
                icon: Icon(Icons.list_alt, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text('CSV • Detaylı veri'),
                icon: Icon(Icons.table_chart_outlined, size: 16),
              ),
            ],
            selected: {_csvMode},
            onSelectionChanged: (v) => setState(() {
              _csvMode = v.first;
              _result = null;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          FormRow(
            children: [
              DropdownButtonFormField<String>(
                value: _companyId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _csvMode
                      ? 'Varsayılan şirket (dosyada belirtilmeyenler için)'
                      : 'Eklenecek şirket',
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                items: [
                  for (final c in bank.companies)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} • ${Fmt.money(c.salaryLimit, bank.currency, digits: 0)}'),
                    ),
                ],
                onChanged: (v) => setState(() => _companyId = v),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(_fileName ?? 'Dosyadan Yükle'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            maxLines: 9,
            onChanged: (_) => setState(() {
              _result = null;
              _error = null;
            }),
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: _csvMode
                  ? 'CSV içeriğini yapıştırın'
                  : 'İsimleri her satıra bir kişi gelecek şekilde yapıştırın',
              hintText: _csvMode
                  ? 'Ad Soyad;E-posta;Unvan;Maaş;Şirket\nAyşe Yılmaz;ayse@firma.com;Analist;32000;TechCorp A.Ş.'
                  : 'Ahmet Yılmaz\nZeynep Kaya\nMert Demir',
              prefixIcon: const Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _csvMode
                      ? 'Algılanan satır sayısı: $csvRows. E-posta boşsa otomatik üretilir, maaş boşsa şirket limitine göre dağıtılır.'
                      : 'Algılanan isim sayısı: ${lines.length}. Maaşlar '
                          '${company == null ? '' : '${Fmt.money(company.effectiveSalaryMin, bank.currency, digits: 0)} - ${Fmt.money(company.salaryLimit, bank.currency, digits: 0)} arasında'} '
                          'otomatik dağıtılır ve sözleşmeler '
                          '${bank.settings.defaultContractMonths} ay olarak ayarlanır.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_result!.added} kullanıcı eklendi'
                    '${_result!.totalSalary > 0 ? ' • toplam maaş ${Fmt.money(_result!.totalSalary, bank.currency)}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_result!.skipped.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Atlanan: ${_result!.skipped.take(6).join(', ')}'
                        '${_result!.skipped.length > 6 ? ' ve ${_result!.skipped.length - 6} kayıt daha' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: _busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_done_outlined, size: 18),
                label: Text(_busy ? 'Aktarılıyor...' : 'İçe Aktar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await ExportService.pickText(
      extensions: _csvMode
          ? ExportService.csvExtensions
          : [...ExportService.txtExtensions, ...ExportService.csvExtensions],
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (outcome.ok && outcome.content != null) {
        _text.text = outcome.content!;
        _fileName = outcome.fileName;
        if (outcome.fileName != null &&
            outcome.fileName!.toLowerCase().endsWith('.csv')) {
          _csvMode = true;
        }
      } else if (!outcome.cancelled) {
        _error = outcome.message;
      }
    });
  }

  Future<void> _import() async {
    final bank = context.read<BankProvider>();
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      final content = _text.text;
      if (content.trim().isEmpty) {
        throw Exception('İçerik boş. Metin yapıştırın veya dosya yükleyin.');
      }
      final ImportUsersResult result;
      if (_csvMode) {
        result = bank.importUsersFromCsv(content, fallbackCompanyId: _companyId);
      } else {
        if (_companyId == null) {
          throw Exception('Önce bir şirket seçin.');
        }
        result = bank.importUsersFromNames(
          names: ExportService.txtToLines(content),
          companyId: _companyId!,
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = result;
        _text.clear();
        _fileName = null;
      });
      showSnackBar(context, '${result.added} kullanıcı içe aktarıldı.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}

/// Yedekleme / geri yükleme / dışa aktarma merkezi.
Future<void> showDataManagementDialog(BuildContext context) async {
  await showAppDialog<void>(
    context,
    title: 'Veri Yönetimi',
    subtitle:
        'Yedek alın, geri yükleyin veya verilerinizi CSV olarak dışa aktarın.',
    icon: Icons.storage_outlined,
    maxWidth: 720,
    scrollable: false,
    child: const _DataManagementPanel(),
  );
}

class _DataManagementPanel extends StatefulWidget {
  const _DataManagementPanel();

  @override
  State<_DataManagementPanel> createState() => _DataManagementPanelState();
}

class _DataManagementPanelState extends State<_DataManagementPanel> {
  bool _busy = false;

  Future<void> _save({
    required String fileName,
    required String content,
    required List<String> extensions,
  }) async {
    setState(() => _busy = true);
    final outcome = await ExportService.saveText(
      fileName: fileName,
      content: content,
      extensions: extensions,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.ok) {
      showSnackBar(context, 'Kaydedildi: ${outcome.path ?? fileName}');
    } else if (!outcome.cancelled) {
      showSnackBar(context, outcome.message ?? 'İşlem başarısız.', error: true);
    } else {
      showSnackBar(context, 'İşlem iptal edildi.', error: false, success: false);
    }
  }

  Future<void> _restore({required bool merge}) async {
    final bank = context.read<BankProvider>();
    setState(() => _busy = true);
    final outcome = await ExportService.pickText(
      extensions: ExportService.jsonExtensions,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!outcome.ok) {
      if (!outcome.cancelled) {
        showSnackBar(context, outcome.message ?? 'Dosya okunamadı.', error: true);
      }
      return;
    }
    final error = bank.importBackupJson(outcome.content ?? '', merge: merge);
    if (!mounted) return;
    if (error != null) {
      showSnackBar(context, error, error: true);
    } else {
      showSnackBar(context,
          merge ? 'Yedek mevcut verilerle birleştirildi.' : 'Yedek geri yüklendi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final stamp = DateTime.now();
    final suffix =
        '${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_'
        '${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          DialogSection(
            title: 'Yedekleme',
            icon: Icons.backup_outlined,
            description:
                'JSON yedeği tüm şirketleri, kullanıcıları, hareketleri ve ayarları içerir.',
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _save(
                              fileName: 'arena-bank-yedek-$suffix.json',
                              content: bank.exportBackupJson(),
                              extensions: ExportService.jsonExtensions,
                            ),
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Yedek Al (JSON)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _restore(merge: false),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Yedekten Geri Yükle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _restore(merge: true),
                    icon: const Icon(Icons.merge_type, size: 18),
                    label: const Text('Yedekle Birleştir'),
                  ),
                ],
              ),
            ],
          ),
          DialogSection(
            title: 'Dışa Aktarma (CSV)',
            icon: Icons.table_view_outlined,
            description:
                'CSV dosyaları Excel ile açılabilir (noktalı virgül ayırıcı, Türkçe başlıklar).',
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _save(
                              fileName: 'kullanicilar-$suffix.csv',
                              content: bank.exportUsersCsv(),
                              extensions: ExportService.csvExtensions,
                            ),
                    icon: const Icon(Icons.people_outline, size: 18),
                    label: const Text('Kullanıcılar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _save(
                              fileName: 'islemler-$suffix.csv',
                              content: bank.exportTransactionsCsv(),
                              extensions: ExportService.csvExtensions,
                            ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('İşlemler'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _save(
                              fileName: 'sistem-gunlugu-$suffix.csv',
                              content: bank.exportAuditCsv(),
                              extensions: ExportService.csvExtensions,
                            ),
                    icon: const Icon(Icons.history_outlined, size: 18),
                    label: const Text('Sistem Günlüğü'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _save(
                              fileName: 'kullanici-sablonu.csv',
                              content: bank.exportCsvTemplate(),
                              extensions: ExportService.csvExtensions,
                            ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('CSV Şablonu'),
                  ),
                ],
              ),
            ],
          ),
          DialogSection(
            title: 'Tehlikeli İşlemler',
            icon: Icons.warning_amber_rounded,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showConfirmDialog(
                        context,
                        title: 'İşlem geçmişi temizlensin mi?',
                        message:
                            '${bank.transactions.length} hareket silinecek. Bakiyeler değişmez.',
                        icon: Icons.cleaning_services_outlined,
                        danger: true,
                        confirmText: 'Temizle',
                        onConfirm: () {
                          bank.clearTransactions();
                          showSnackBar(context, 'İşlem geçmişi temizlendi.');
                        },
                      );
                    },
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                    label: const Text('İşlem Geçmişini Temizle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showConfirmDialog(
                        context,
                        title: 'Tüm veriler silinsin mi?',
                        message:
                            'Şirketler, kullanıcılar, hareketler ve krediler silinir. Yalnızca varsayılan yönetici hesabı kalır.',
                        icon: Icons.delete_forever_outlined,
                        danger: true,
                        confirmText: 'Hepsini Sil',
                        onConfirm: () {
                          bank.clearAllData();
                          showSnackBar(context, 'Tüm veriler silindi.');
                        },
                      );
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Tüm Verileri Sil'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showConfirmDialog(
                        context,
                        title: 'Demo verisine dönülsün mü?',
                        message:
                            'Mevcut veriler silinip örnek şirketler ve çalışanlarla yeniden başlatılır.',
                        icon: Icons.restart_alt,
                        danger: true,
                        confirmText: 'Sıfırla',
                        onConfirm: () {
                          bank.resetAll();
                          showSnackBar(context, 'Demo verisi yüklendi.');
                        },
                      );
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Demo Verisine Sıfırla'),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${bank.users.length} kullanıcı • ${bank.companies.length} şirket • ${bank.transactions.length} hareket',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sistem günlüğü (denetim kaydı) görüntüleyici.
Future<void> showAuditLogDialog(BuildContext context) async {
  await showAppDialog<void>(
    context,
    title: 'Sistem Günlüğü',
    subtitle: 'Kim, ne zaman, ne yaptı? Tüm işlemler burada kayıtlıdır.',
    icon: Icons.history_outlined,
    maxWidth: 760,
    scrollable: false,
    child: const _AuditPanel(),
  );
}

class _AuditPanel extends StatefulWidget {
  const _AuditPanel();

  @override
  State<_AuditPanel> createState() => _AuditPanelState();
}

class _AuditPanelState extends State<_AuditPanel> {
  final _search = TextEditingController();
  LogLevel? _level;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final query = _search.text.trim().toLowerCase();
    final entries = bank.auditLog
        .where((e) => _level == null || e.level == _level)
        .where((e) =>
            query.isEmpty ||
            e.action.toLowerCase().contains(query) ||
            e.detail.toLowerCase().contains(query) ||
            e.actorName.toLowerCase().contains(query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: SearchInput(
                  controller: _search,
                  hint: 'Günlükte ara...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<LogLevel?>(
                value: _level,
                hint: const Text('Seviye'),
                items: [
                  const DropdownMenuItem<LogLevel?>(
                      value: null, child: Text('Tümü')),
                  for (final l in LogLevel.values)
                    DropdownMenuItem<LogLevel?>(
                      value: l,
                      child: Row(
                        children: [
                          Icon(l.icon, size: 15, color: l.color),
                          const SizedBox(width: 6),
                          Text(l.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _level = v),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: Icons.history_toggle_off,
                  title: 'Kayıt bulunamadı',
                  message: 'Seçilen filtrelerle eşleşen bir günlük kaydı yok.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: e.level.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: e.level.color.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(e.level.icon, size: 18, color: e.level.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.action,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                if (e.detail.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      e.detail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${e.actorName} • ${Fmt.dateTime(e.date)} • ${Fmt.ago(e.date)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
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
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              Text(
                '${entries.length} kayıt (en fazla ${bank.settings.auditLimit})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showConfirmDialog(
                    context,
                    title: 'Günlük temizlensin mi?',
                    message: 'Tüm sistem günlüğü kayıtları silinecek.',
                    icon: Icons.delete_outline,
                    danger: true,
                    confirmText: 'Temizle',
                    onConfirm: () {
                      bank.clearAudit();
                      showSnackBar(context, 'Sistem günlüğü temizlendi.');
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Temizle'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bildirim merkezi paneli.
Future<void> showNotificationsDialog(BuildContext context) async {
  await showAppDialog<void>(
    context,
    title: 'Bildirimler',
    subtitle: 'Sistem olayları ve uyarılar.',
    icon: Icons.notifications_none,
    maxWidth: 620,
    scrollable: false,
    child: const _NotificationPanel(),
  );
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final items = bank.notifications;
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'Bildirim yok',
                  message:
                      'Maaş, prim, ceza ve sözleşme olaylarında burada bilgilendirilirsiniz.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => bank.markNotificationRead(n.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5)
                              : n.kind.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n.isRead
                                ? Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.5)
                                : n.kind.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: n.kind.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(n.kind.icon,
                                  size: 16, color: n.kind.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  if (n.body.isNotEmpty)
                                    Text(
                                      n.body,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  Text(
                                    Fmt.ago(n.date),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Kaldır',
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => bank.removeNotification(n.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: bank.unreadNotificationCount == 0
                    ? null
                    : bank.markAllNotificationsRead,
                icon: const Icon(Icons.done_all, size: 17),
                label: const Text('Tümünü okundu işaretle'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: items.isEmpty ? null : bank.clearNotifications,
                icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                label: const Text('Tümünü temizle'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
