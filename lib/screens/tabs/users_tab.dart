import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bank_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/common.dart';
import '../dialogs/import_export_dialogs.dart';
import '../dialogs/user_dialogs.dart';

/// Kullanıcı yönetimi: arama, filtreleme, toplu işlemler ve tam düzenleme.
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => UsersTabState();
}

class UsersTabState extends State<UsersTab> {
  final _nameQuery = TextEditingController();
  final _companyQuery = TextEditingController();
  final _titleQuery = TextEditingController();

  final Set<String> _selected = <String>{};
  String _sortBy = 'name';
  bool _ascending = true;
  UserRole? _roleFilter;
  int _statusFilter = 0; // 0 tümü, 1 aktif, 2 pasif
  String? _companyFilter;
  int _visible = 60;

  final FocusNode _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameQuery.dispose();
    _companyQuery.dispose();
    _titleQuery.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// Komut paletinden veya kısayoldan aramaya odaklanmak için.
  void focusSearch() => _nameFocus.requestFocus();

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final results = bank.searchUsers(
      query: _nameQuery.text,
      companyQuery: _companyQuery.text,
      titleQuery: _titleQuery.text,
      role: _roleFilter,
      activeOnly: _statusFilter == 0 ? null : _statusFilter == 1,
      sortBy: _sortBy,
      ascending: _ascending,
    ).where((u) => _companyFilter == null || u.companyId == _companyFilter).toList();

    final visible = results.take(_visible).toList();
    final selectedUsers =
        bank.users.where((u) => _selected.contains(u.id)).toList();

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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 820;
                      final title = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kullanıcılar',
                              style:
                                  Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${bank.users.length} kayıt • ${results.length} sonuç • '
                            '${bank.activeEmployeeCount} aktif çalışan',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      );
                      final actions = <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => showImportDialog(context),
                          icon: const Icon(Icons.text_snippet_outlined,
                              size: 18),
                          label: const Text('TXT ile Kullanıcı Ekle'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showBonusDialog(
                            context,
                            targets: const [],
                            companyWide: true,
                            companyId: _companyFilter ??
                                (bank.companies.isEmpty
                                    ? null
                                    : bank.companies.first.id),
                          ),
                          icon: const Icon(Icons.card_giftcard, size: 18),
                          label: const Text('Toplu Prim Dağıt'),
                        ),
                        FilledButton.icon(
                          onPressed: () => showUserEditor(context),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Yeni Kullanıcı'),
                        ),
                      ];
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: actions,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: title),
                          for (final a in actions) ...[
                            a,
                            const SizedBox(width: 10),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _nameQuery,
                          focusNode: _nameFocus,
                          onChanged: (_) => setState(() => _visible = 60),
                          decoration: const InputDecoration(
                            labelText: 'Ada göre ara',
                            prefixIcon: Icon(Icons.search, size: 19),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _companyQuery,
                          onChanged: (_) => setState(() => _visible = 60),
                          decoration: const InputDecoration(
                            labelText: 'Şirkete göre ara',
                            prefixIcon: Icon(Icons.business_outlined, size: 19),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _titleQuery,
                          onChanged: (_) => setState(() => _visible = 60),
                          decoration: const InputDecoration(
                            labelText: 'Unvana göre ara',
                            prefixIcon: Icon(Icons.badge_outlined, size: 19),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<UserRole?>(
                          value: _roleFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<UserRole?>(
                                value: null, child: Text('Tüm roller')),
                            for (final r in UserRole.values)
                              DropdownMenuItem<UserRole?>(
                                  value: r, child: Text(r.label)),
                          ],
                          onChanged: (v) => setState(() => _roleFilter = v),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String?>(
                          value: _companyFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Şirket filtresi',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('Tüm şirketler')),
                            for (final c in bank.companies)
                              DropdownMenuItem<String?>(
                                  value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) => setState(() => _companyFilter = v),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Sıralama',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'name', child: Text('Ada göre')),
                            DropdownMenuItem(
                                value: 'salary', child: Text('Maaşa göre')),
                            DropdownMenuItem(
                                value: 'balance', child: Text('Bakiyeye göre')),
                            DropdownMenuItem(
                                value: 'company', child: Text('Şirkete göre')),
                            DropdownMenuItem(
                                value: 'title', child: Text('Unvana göre')),
                            DropdownMenuItem(
                                value: 'contract',
                                child: Text('Sözleşme bitişine göre')),
                          ],
                          onChanged: (v) =>
                              setState(() => _sortBy = v ?? 'name'),
                        ),
                      ),
                      IconButton(
                        tooltip: _ascending
                            ? 'Artan sıralama (tıkla: azalan)'
                            : 'Azalan sıralama (tıkla: artan)',
                        icon: Icon(_ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward),
                        onPressed: () =>
                            setState(() => _ascending = !_ascending),
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Tümü')),
                          ButtonSegment(value: 1, label: Text('Aktif')),
                          ButtonSegment(value: 2, label: Text('Pasif')),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (v) =>
                            setState(() => _statusFilter = v.first),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _nameQuery.clear();
                          _companyQuery.clear();
                          _titleQuery.clear();
                          _roleFilter = null;
                          _companyFilter = null;
                          _statusFilter = 0;
                          _sortBy = 'name';
                          _ascending = true;
                          _visible = 60;
                        }),
                        icon: const Icon(Icons.restart_alt, size: 17),
                        label: const Text('Sıfırla'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: _selected.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                      borderColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18),
                          Text(
                            '${_selected.length} kayıt seçildi',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                showBulkActionsDialog(context, selectedUsers),
                            icon: const Icon(Icons.bolt_outlined, size: 17),
                            label: const Text('Toplu İşlem'),
                          ),
                          TextButton(
                            onPressed: () => setState(_selected.clear),
                            child: const Text('Seçimi temizle'),
                          ),
                          Text(
                            'Toplam bakiye: ${bank.money(selectedUsers.fold<double>(0, (a, u) => a + u.balance))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (visible.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _allVisibleSelected(visible),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.addAll(visible.map((u) => u.id));
                      } else {
                        _selected.removeAll(visible.map((u) => u.id));
                      }
                    }),
                  ),
                  Text(
                    _allVisibleSelected(visible)
                        ? 'Görünenlerin tümü seçili'
                        : 'Görünen tümünü seç',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${visible.length} / ${results.length} kayıt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (results.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.person_search_outlined,
                title: 'Sonuç bulunamadı',
                message:
                    'Arama kutularını veya filtreleri değiştirin. Yeni kullanıcı eklemek için "Yeni Kullanıcı" düğmesini kullanın.',
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  for (final u in visible) _userRow(context, bank, u),
                ],
              ),
            ),
          if (results.length > visible.length)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: () => setState(() => _visible += 60),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                      'Daha fazla göster (${results.length - visible.length} kayıt daha)'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _allVisibleSelected(List<AppUser> visible) =>
      visible.isNotEmpty && visible.every((u) => _selected.contains(u.id));

  Widget _userRow(BuildContext context, BankProvider bank, AppUser u) {
    final scheme = Theme.of(context).colorScheme;
    final company = bank.companyById(u.companyId);
    final selected = _selected.contains(u.id);
    final windowWidth = MediaQuery.of(context).size.width;
    final isWide = windowWidth >= 1180;
    final showRoleBadge = windowWidth >= 1000;

    return HoverLift(
      scale: 1.004,
      onTap: () => _showUserDetail(context, bank, u),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(u.id);
                } else {
                  _selected.remove(u.id);
                }
              }),
            ),
            AvatarBubble(
              name: u.fullName,
              colorValue: u.avatarColor,
              radius: 18,
              showStatus: true,
              isActive: u.isActive,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  Text(
                    '${u.title}${u.department.isEmpty ? '' : ' • ${u.department}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company?.name ?? 'Bağımsız',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bank.money(u.salary, compact: true),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    Text('maaş',
                        style:
                            TextStyle(fontSize: 10, color: scheme.outline)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bank.money(u.balance, compact: true),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    Text('bakiye',
                        style:
                            TextStyle(fontSize: 10, color: scheme.outline)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            if (u.isContractExpired)
              const PillBadge(
                label: 'sözleşme bitti',
                color: Color(0xFFEF4444),
                dense: true,
              )
            else if (u.isContractExpiringSoon)
              PillBadge(
                label: '${u.contractDaysLeft} gün',
                color: const Color(0xFFF59E0B),
                dense: true,
              ),
            if (showRoleBadge && u.role != UserRole.employee)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: PillBadge(
                  label: u.role.label,
                  color: scheme.secondary,
                  dense: true,
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'İsmi Düzenle',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.drive_file_rename_outline, size: 18),
              onPressed: () => _renameUser(context, bank, u),
            ),
            IconButton(
              tooltip: 'Kullanıcı kartı',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => _showUserDetail(context, bank, u),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tüm işlemler',
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) => _handleAction(context, bank, u, value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined, size: 18),
                      title: Text('Tam düzenle'),
                    )),
                PopupMenuItem(
                    value: 'salary',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.payments_outlined, size: 18),
                      title: Text('Maaş öde'),
                    )),
                PopupMenuItem(
                    value: 'bonus',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.card_giftcard, size: 18),
                      title: Text('Prim öde'),
                    )),
                PopupMenuItem(
                    value: 'penalty',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.gavel_outlined, size: 18),
                      title: Text('Ceza uygula'),
                    )),
                PopupMenuItem(
                    value: 'promote',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.trending_up, size: 18),
                      title: Text('Terfi / zam'),
                    )),
                PopupMenuItem(
                    value: 'contract',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_note_outlined, size: 18),
                      title: Text('Sözleşme işlemleri'),
                    )),
                PopupMenuItem(
                    value: 'transfer',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.swap_horiz, size: 18),
                      title: Text('Şirket değiştir'),
                    )),
                PopupMenuItem(
                    value: 'loan',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.request_quote_outlined, size: 18),
                      title: Text('Kredi ver'),
                    )),
                PopupMenuItem(
                    value: 'password',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_reset, size: 18),
                      title: Text('Şifre değiştir'),
                    )),
                PopupMenuDivider(),
                PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.power_settings_new, size: 18),
                      title: Text('Aktif / pasif'),
                    )),
                PopupMenuItem(
                    value: 'dismiss',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_remove_outlined, size: 18),
                      title: Text('İşten çıkar'),
                    )),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                      title: Text('Sil',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    BankProvider bank,
    AppUser u,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await showUserEditor(context, user: u);
        break;
      case 'salary':
        await showPaySalaryDialog(context, u);
        break;
      case 'bonus':
        await showBonusDialog(context, targets: [u]);
        break;
      case 'penalty':
        await showPenaltyDialog(context, targets: [u]);
        break;
      case 'promote':
        await showPromoteDialog(context, targets: [u]);
        break;
      case 'contract':
        await showContractDialog(context, u);
        break;
      case 'transfer':
        await showTransferDialog(context, u);
        break;
      case 'loan':
        if (!bank.settings.loansEnabled) {
          showSnackBar(context, 'Kredi sistemi ayarlardan kapatılmış.',
              error: true);
          return;
        }
        await showLoanDialog(context, u);
        break;
      case 'password':
        await showPasswordDialog(context, u);
        break;
      case 'toggle':
        bank.setUserActive(u.id, !u.isActive);
        showSnackBar(context,
            u.isActive ? '${u.fullName} pasife alındı.' : '${u.fullName} aktifleştirildi.');
        break;
      case 'dismiss':
        await showDismissDialog(context, u);
        break;
      case 'delete':
        if (!context.mounted) return;
        await showConfirmDialog(
          context,
          title: '${u.fullName} silinsin mi?',
          message:
              'Kullanıcı ve kredi kayıtları silinir. İşlem geçmişi korunur. Bu işlemi Geri Al ile geri alabilirsiniz.',
          icon: Icons.delete_outline,
          danger: true,
          confirmText: 'Sil',
          onConfirm: () {
            try {
              bank.deleteUser(u.id);
              showSnackBar(context, '${u.fullName} silindi.');
            } catch (e) {
              showError(context, e);
            }
          },
        );
        break;
    }
  }

  Future<void> _renameUser(
      BuildContext context, BankProvider bank, AppUser u) async {
    final controller = TextEditingController(text: u.fullName);
    String? error;
    await showAppDialog<void>(
      context,
      title: 'İsmi Düzenle',
      subtitle: '${u.email} • ${u.title}',
      icon: Icons.drive_file_rename_outline,
      maxWidth: 460,
      child: StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Yeni Ad Soyad',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: error,
              ),
              onSubmitted: (_) {
                final clean = controller.text.trim();
                if (clean.isEmpty) {
                  setState(() => error = 'Ad Soyad boş bırakılamaz.');
                  return;
                }
                bank.updateUserName(u.id, clean);
                Navigator.pop(ctx);
                showSnackBar(context, 'İsim güncellendi.');
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final clean = controller.text.trim();
                    if (clean.isEmpty) {
                      setState(() => error = 'Ad Soyad boş bırakılamaz.');
                      return;
                    }
                    bank.updateUserName(u.id, clean);
                    Navigator.pop(ctx);
                    showSnackBar(context, 'İsim güncellendi.');
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _showUserDetail(BuildContext context, BankProvider bank, AppUser u) {
    showAppDialog<void>(
      context,
      title: u.fullName,
      subtitle: '${u.title} • ${bank.companyById(u.companyId)?.name ?? 'Bağımsız'}',
      icon: Icons.badge_outlined,
      accent: u.avatarColor == 0
          ? Theme.of(context).colorScheme.primary
          : Color(u.avatarColor),
      maxWidth: 880,
      scrollable: false,
      child: _UserDetailBody(userId: u.id, bank: bank),
    );
  }
}

/// Kullanıcı detay gövdesi (sekme: özet / işlemler / krediler).
class _UserDetailBody extends StatefulWidget {
  final String userId;
  final BankProvider bank;

  const _UserDetailBody({required this.userId, required this.bank});

  @override
  State<_UserDetailBody> createState() => _UserDetailBodyState();
}

class _UserDetailBodyState extends State<_UserDetailBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    final user = bank.userById(widget.userId);
    final scheme = Theme.of(context).colorScheme;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Kullanıcı bulunamadı',
          message: 'Bu kayıt silinmiş olabilir.',
        ),
      );
    }
    final company = bank.companyById(user.companyId);
    final txns = bank.txnsOfUser(user.id);
    final loans = bank.loansOfUser(user.id);
    final tax = bank.settings.taxEnabled
        ? user.salary * (bank.settings.taxPercent / 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (user.avatarColor == 0 ? scheme.primary : Color(user.avatarColor))
                      .withValues(alpha: 0.85),
                  scheme.secondary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                AvatarBubble(
                    name: user.fullName,
                    colorValue: user.avatarColor,
                    radius: 26),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${user.roleLabel} • ${company?.name ?? 'Bağımsız'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bank.money(user.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PillBadge(
                      label: user.isActive ? 'Aktif' : 'Pasif',
                      color: user.isActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 6),
                    PillBadge(
                      label: user.isContractExpired
                          ? 'Sözleşme bitti'
                          : '${user.contractDaysLeft} gün kaldı',
                      color: user.isContractExpired
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(
                  value: 0,
                  label: Text('Özet'),
                  icon: Icon(Icons.info_outline, size: 15)),
              ButtonSegment(
                  value: 1,
                  label: Text('İşlemler (${txns.length})'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 15)),
              ButtonSegment(
                  value: 2,
                  label: Text('Krediler (${loans.length})'),
                  icon: const Icon(Icons.request_quote_outlined, size: 15)),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      KeyValueRow(
                          label: 'E-posta',
                          value: user.email,
                          icon: Icons.alternate_email),
                      KeyValueRow(
                          label: 'Telefon',
                          value: user.phone.isEmpty ? '-' : user.phone,
                          icon: Icons.phone_outlined),
                      KeyValueRow(
                          label: 'IBAN',
                          value: user.iban.isEmpty ? '-' : user.iban,
                          icon: Icons.account_balance_outlined),
                      KeyValueRow(
                          label: 'Departman',
                          value:
                              user.department.isEmpty ? '-' : user.department,
                          icon: Icons.grid_view_outlined),
                      KeyValueRow(
                          label: 'İşe giriş',
                          value: Fmt.date(user.hireDate),
                          icon: Icons.event_outlined),
                      KeyValueRow(
                          label: 'Son giriş',
                          value: user.lastLogin == null
                              ? '-'
                              : Fmt.dateTime(user.lastLogin!),
                          icon: Icons.login_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      KeyValueRow(
                          label: 'Maaş',
                          value: bank.money(user.salary),
                          icon: Icons.payments_outlined),
                      KeyValueRow(
                          label: 'Aylık prim',
                          value: bank.money(user.bonus),
                          icon: Icons.card_giftcard),
                      if (tax > 0)
                        KeyValueRow(
                            label: 'Gelir vergisi',
                            value: '-${bank.money(tax)}',
                            valueColor: const Color(0xFFEF4444),
                            icon: Icons.percent),
                      KeyValueRow(
                          label: 'Net aylık',
                          value: bank.money(user.salary - tax + user.bonus),
                          icon: Icons.savings_outlined,
                          valueColor: const Color(0xFF10B981)),
                      KeyValueRow(
                          label: 'Maaş günü',
                          value: 'Her ayın ${user.salaryDate.day}. günü',
                          icon: Icons.event_repeat_outlined),
                      KeyValueRow(
                          label: 'Sözleşme',
                          value:
                              '${Fmt.date(user.contractStart)} → ${Fmt.date(user.contractEnd)}',
                          icon: Icons.event_note_outlined),
                      KeyValueRow(
                          label: 'Fesih ücreti',
                          value: bank.money(user.terminationFee),
                          icon: Icons.description_outlined),
                    ],
                  ),
                ),
              ],
            ),
            if (user.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(user.notes),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => showUserEditor(context, user: user),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Tam Düzenle'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showPaySalaryDialog(context, user),
                  icon: const Icon(Icons.payments_outlined, size: 17),
                  label: const Text('Maaş Öde'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showBonusDialog(context, targets: [user]),
                  icon: const Icon(Icons.card_giftcard, size: 17),
                  label: const Text('Prim'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showPenaltyDialog(context, targets: [user]),
                  icon: const Icon(Icons.gavel_outlined, size: 17),
                  label: const Text('Ceza'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showPromoteDialog(context, targets: [user]),
                  icon: const Icon(Icons.trending_up, size: 17),
                  label: const Text('Terfi'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showContractDialog(context, user),
                  icon: const Icon(Icons.event_note_outlined, size: 17),
                  label: const Text('Sözleşme'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showTransferDialog(context, user),
                  icon: const Icon(Icons.swap_horiz, size: 17),
                  label: const Text('Şirket Değiştir'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showLoanDialog(context, user),
                  icon: const Icon(Icons.request_quote_outlined, size: 17),
                  label: const Text('Kredi'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showPasswordDialog(context, user),
                  icon: const Icon(Icons.lock_reset, size: 17),
                  label: const Text('Şifre'),
                ),
              ],
            ),
          ] else if (_tab == 1) ...[
            if (txns.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'İşlem yok',
                message: 'Bu kullanıcı için kayıtlı hareket bulunmuyor.',
              )
            else
              for (final t in txns.take(80))
                TxnListTile(
                  txn: t,
                  currency: bank.currency,
                  digits: bank.decimalDigits,
                  perspectiveId: user.id,
                ),
          ] else ...[
            if (loans.isEmpty)
              const EmptyState(
                icon: Icons.request_quote_outlined,
                title: 'Kredi kaydı yok',
                message: 'Bu kullanıcıya tanımlanmış kredi bulunmuyor.',
              )
            else
              for (final loan in loans)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.request_quote_outlined),
                  title: Text(bank.money(loan.principal)),
                  subtitle: Text(
                      '${loan.paidInstallments}/${loan.totalInstallments} taksit • kalan ${bank.money(loan.remaining)}'),
                  trailing: PillBadge(
                    label: loan.isFinished ? 'Tamamlandı' : 'Aktif',
                    color: loan.isFinished
                        ? const Color(0xFF22C55E)
                        : scheme.primary,
                    dense: true,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
