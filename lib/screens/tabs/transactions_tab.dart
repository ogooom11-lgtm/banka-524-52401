import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

/// İşlem geçmişi: gelişmiş filtreler, özet ve dışa aktarma.
class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final _search = TextEditingController();
  final _minAmount = TextEditingController();
  final _maxAmount = TextEditingController();
  final Set<TxnType> _types = {};
  DateTime? _from;
  DateTime? _to;
  String? _companyId;
  String? _userId;
  int _flow = 0; // 0: tümü, 1: giriş, 2: çıkış
  int _visible = 40;
  bool _showFilters = true;
  bool _newestFirst = true;

  @override
  void dispose() {
    _search.dispose();
    _minAmount.dispose();
    _maxAmount.dispose();
    super.dispose();
  }

  List<Txn> _filtered(BankProvider bank) {
    final list = bank.filterTxns(
      types: _types,
      from: _from,
      to: _to == null
          ? null
          : DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59),
      minAmount: Fmt.parseAmount(_minAmount.text),
      maxAmount: Fmt.parseAmount(_maxAmount.text),
      query: _search.text,
      companyId: _companyId,
      userId: _userId,
      onlyIncome: _flow == 1,
      onlyExpense: _flow == 2,
    ).toList();
    return _newestFirst ? list.reversed.toList() : list;
  }

  void _reset() {
    setState(() {
      _search.clear();
      _minAmount.clear();
      _maxAmount.clear();
      _types.clear();
      _from = null;
      _to = null;
      _companyId = null;
      _userId = null;
      _flow = 0;
      _visible = 40;
      _newestFirst = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered(bank);
    final visible = list.take(_visible).toList();
    final income =
        list.where((t) => t.type.isIncoming).fold<double>(0, (a, t) => a + t.amount);
    final expense =
        list.where((t) => t.type.isOutgoing).fold<double>(0, (a, t) => a + t.amount);
    final activeFilters = _types.length +
        (_from != null ? 1 : 0) +
        (_to != null ? 1 : 0) +
        (_companyId != null ? 1 : 0) +
        (_userId != null ? 1 : 0) +
        (_flow != 0 ? 1 : 0) +
        (_minAmount.text.isNotEmpty ? 1 : 0) +
        (_maxAmount.text.isNotEmpty ? 1 : 0);

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('İşlem Geçmişi',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${bank.transactions.length} kayıt • ${list.length} sonuç gösteriliyor',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconAction(
                        icon: _showFilters
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        tooltip: 'Filtreleri göster/gizle',
                        filled: _showFilters,
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                      IconAction(
                        icon: _newestFirst
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        tooltip: _newestFirst
                            ? 'Sıralama: en yeni üstte (tıkla: en eski)'
                            : 'Sıralama: en eski üstte (tıkla: en yeni)',
                        onPressed: () =>
                            setState(() => _newestFirst = !_newestFirst),
                      ),
                      IconAction(
                        icon: Icons.download_outlined,
                        tooltip: 'Sonucu CSV olarak indir',
                        onPressed: list.isEmpty
                            ? null
                            : () async {
                                final outcome = await ExportService.saveText(
                                  fileName:
                                      'islemler-${DateTime.now().millisecondsSinceEpoch}.csv',
                                  content:
                                      bank.exportTransactionsCsv(source: list),
                                  extensions: ExportService.csvExtensions,
                                );
                                if (!context.mounted) return;
                                if (outcome.ok) {
                                  showSnackBar(context,
                                      '${list.length} kayıt dışa aktarıldı.');
                                } else if (!outcome.cancelled) {
                                  showSnackBar(context,
                                      outcome.message ?? 'Kaydedilemedi.',
                                      error: true);
                                }
                              },
                      ),
                      IconAction(
                        icon: Icons.restart_alt,
                        tooltip: 'Filtreleri sıfırla',
                        onPressed: _reset,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SearchInput(
                    controller: _search,
                    hint: 'Açıklama, tutar, referans veya hesap adı ile ara...',
                    onChanged: (_) => setState(() => _visible = 40),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in TxnType.values)
                        FilterChip(
                          label: Text(t.label),
                          selected: _types.contains(t),
                          avatar: Icon(
                            TxnIcon.of(t),
                            size: 15,
                            color: TxnIcon.colorOf(t),
                          ),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _types.add(t);
                            } else {
                              _types.remove(t);
                            }
                            _visible = 40;
                          }),
                        ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                      value: 0,
                                      label: Text('Tümü'),
                                      icon: Icon(Icons.list_alt, size: 15)),
                                  ButtonSegment(
                                      value: 1,
                                      label: Text('Giriş'),
                                      icon: Icon(Icons.south_west, size: 15)),
                                  ButtonSegment(
                                      value: 2,
                                      label: Text('Çıkış'),
                                      icon: Icon(Icons.north_east, size: 15)),
                                ],
                                selected: {_flow},
                                onSelectionChanged: (v) => setState(() {
                                  _flow = v.first;
                                  _visible = 40;
                                }),
                              ),
                              SizedBox(
                                width: 190,
                                child: DropdownButtonFormField<String?>(
                                  value: _companyId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Şirket',
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                        value: null, child: Text('Tüm şirketler')),
                                    for (final c in bank.companies)
                                      DropdownMenuItem<String?>(
                                          value: c.id, child: Text(c.name)),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _companyId = v;
                                    _visible = 40;
                                  }),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String?>(
                                  value: _userId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Kullanıcı',
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Tüm kullanıcılar')),
                                    for (final u in bank.users)
                                      DropdownMenuItem<String?>(
                                          value: u.id,
                                          child: Text(u.fullName)),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _userId = v;
                                    _visible = 40;
                                  }),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: TextField(
                                  controller: _minAmount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) =>
                                      setState(() => _visible = 40),
                                  decoration: const InputDecoration(
                                    labelText: 'Min tutar',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: TextField(
                                  controller: _maxAmount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) =>
                                      setState(() => _visible = 40),
                                  decoration: const InputDecoration(
                                    labelText: 'Maks tutar',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              _dateButton(
                                label: _from == null
                                    ? 'Başlangıç tarihi'
                                    : Fmt.date(_from!),
                                icon: Icons.event_outlined,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _from ??
                                        DateTime.now()
                                            .subtract(const Duration(days: 30)),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _from = picked;
                                      _visible = 40;
                                    });
                                  }
                                },
                                onClear: _from == null
                                    ? null
                                    : () => setState(() => _from = null),
                              ),
                              _dateButton(
                                label: _to == null
                                    ? 'Bitiş tarihi'
                                    : Fmt.date(_to!),
                                icon: Icons.event_available_outlined,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _to ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _to = picked;
                                      _visible = 40;
                                    });
                                  }
                                },
                                onClear: _to == null
                                    ? null
                                    : () => setState(() => _to = null),
                              ),
                              _quickRange('Bugün', 0),
                              _quickRange('7 gün', 7),
                              _quickRange('30 gün', 30),
                              _quickRange('1 yıl', 365),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _showFilters
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 240),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          WrapGrid(
            minItemWidth: 220,
            maxColumns: 4,
            children: [
              StatCard(
                title: 'Sonuç',
                value: '${list.length}',
                icon: Icons.filter_alt_outlined,
                subtitle: activeFilters == 0
                    ? 'filtre yok'
                    : '$activeFilters aktif filtre',
              ),
              StatCard(
                title: 'Giriş',
                value: '',
                numericValue: income,
                icon: Icons.south_west,
                color: const Color(0xFF22C55E),
              ),
              StatCard(
                title: 'Çıkış',
                value: '',
                numericValue: expense,
                icon: Icons.north_east,
                color: const Color(0xFFEF4444),
              ),
              StatCard(
                title: 'Net',
                value: '',
                numericValue: income - expense,
                icon: Icons.balance_outlined,
                color: income - expense >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Kayıt bulunamadı',
                    message:
                        'Filtreleri değiştirerek veya sıfırlayarak tüm işlemleri görebilirsiniz.',
                  )
                : Column(
                    children: [
                      for (final t in visible)
                        TxnListTile(
                          txn: t,
                          currency: bank.currency,
                          digits: bank.decimalDigits,
                          dense: false,
                          onTap: () => _showDetail(context, bank, t),
                        ),
                      if (list.length > visible.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Text(
                                '${visible.length} / ${list.length} kayıt gösteriliyor',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                onPressed: () => setState(
                                    () => _visible = _visible + 60),
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: const Text('Daha fazla göster'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _quickRange(String label, int days) {
    final active = days == 0
        ? _from != null &&
            _from!.difference(DateTime.now()).inDays == 0 &&
            _to != null
        : false;
    return ActionChip(
      avatar: Icon(Icons.schedule, size: 15,
          color: active ? Theme.of(context).colorScheme.primary : null),
      label: Text(label),
      onPressed: () => setState(() {
        final now = DateTime.now();
        _to = now;
        _from = days == 0
            ? DateTime(now.year, now.month, now.day)
            : now.subtract(Duration(days: days));
        _visible = 40;
      }),
    );
  }

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label),
        ),
        if (onClear != null)
          IconButton(
            tooltip: 'Tarihi temizle',
            icon: const Icon(Icons.close, size: 15),
            onPressed: onClear,
          ),
      ],
    );
  }

  void _showDetail(BuildContext context, BankProvider bank, Txn t) {
    showAppDialog<void>(
      context,
      title: t.type.label,
      subtitle: Fmt.dateLong(t.date),
      icon: TxnIcon.of(t.type),
      accent: TxnIcon.colorOf(t.type),
      maxWidth: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TxnIcon.colorOf(t.type).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  bank.money(t.amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TxnIcon.colorOf(t.type),
                      ),
                ),
                Text(
                  t.type.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KeyValueRow(
              label: 'Gönderen',
              value: bank.accountLabel(t.fromId),
              icon: Icons.north_east),
          KeyValueRow(
              label: 'Alıcı',
              value: bank.accountLabel(t.toId),
              icon: Icons.south_west),
          KeyValueRow(
              label: 'Tarih saat',
              value: Fmt.dateTime(t.date),
              icon: Icons.schedule),
          KeyValueRow(
              label: 'İşlemi yapan',
              value: bank.accountLabel(t.actorId),
              icon: Icons.person_outline),
          KeyValueRow(
              label: 'Referans',
              value: t.reference.isEmpty ? '-' : t.reference,
              icon: Icons.tag),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(t.description),
          ),
        ],
      ),
    );
  }
}
