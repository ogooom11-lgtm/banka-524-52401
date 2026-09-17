import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bank_provider.dart';
import '../../models/transaction.dart';
import '../../widgets/common.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  TxnType? _filter;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final cur = bank.currency;

    var txns = bank.transactions;
    if (_filter != null) {
      txns = txns.where((t) => t.type == _filter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      txns = txns.where((t) {
        return t.description.toLowerCase().contains(q) ||
            t.type.label.toLowerCase().contains(q) ||
            t.amount.toString().contains(q) ||
            money(t.amount, cur).toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'İşlem açıklaması, türü veya tutar ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tümü'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                    ),
                    for (final t in TxnType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            TxnIcon.of(t),
                            size: 16,
                            color: _filter == t
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : TxnIcon.colorOf(t),
                          ),
                          label: Text(t.label),
                          selected: _filter == t,
                          onSelected: (_) => setState(() => _filter = t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: txns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 12),
                      const Text(
                        'Kayıtlı işlem hareketi bulunamadı.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    final isZero = t.amount == 0;
                    final isDeduction = t.type == TxnType.penalty ||
                        t.type == TxnType.randomDeduction ||
                        t.type == TxnType.terminationFee;

                    String sign = '';
                    if (!isZero) {
                      sign = isDeduction ? '-' : '+';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
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
                          '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm:ss').format(t.date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '$sign${money(t.amount, cur)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isZero ? Colors.grey : TxnIcon.colorOf(t.type),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
