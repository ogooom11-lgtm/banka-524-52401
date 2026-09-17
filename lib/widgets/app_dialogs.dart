import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/bank_provider.dart';
import '../utils/formatters.dart';

/// Uygulamanın ortak diyalog çerçevesi.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData? icon,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 560,
  bool scrollable = true,
  Color? accent,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(24, 8, 24, 20),
}) {
  final scheme = Theme.of(context).colorScheme;
  final color = accent ?? scheme.primary;
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 8),
              child: Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  if (icon != null) const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              subtitle,
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    icon: const Icon(Icons.close, size: 19),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: padding,
                      child: child,
                    )
                  : Padding(padding: padding, child: child),
            ),
            if (actions.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Diyalog içinde başlıklı bölüm.
class DialogSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final String? description;

  const DialogSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: scheme.primary),
                const SizedBox(width: 7),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.7)),
              ),
            ],
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                description!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// İki sütunlu form satırı.
class FormRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const FormRow({super.key, required this.children, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

/// Sayı alanı.
class NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? suffix;
  final String? helper;
  final bool autofocus;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String? errorText;
  final String? hint;

  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.suffix,
    this.helper,
    this.autofocus = false,
    this.allowDecimal = true,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9.,\-]') : RegExp(r'[0-9\-]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixText: suffix,
        helperText: helper,
        helperMaxLines: 2,
        errorText: errorText,
      ),
    );
  }
}

/// Tutar isteyen küçük diyalog. Onaylanırsa tutarı döndürür.
Future<double?> showAmountDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? description,
  String? currency,
  double? initial,
  double? max,
  double? min,
  IconData icon = Icons.payments_outlined,
  String confirmText = 'Uygula',
}) {
  final controller = TextEditingController(
    text: initial == null ? '' : initial.toStringAsFixed(2).replaceAll('.', ','),
  );
  String? error;

  return showAppDialog<double>(
    context,
    title: title,
    subtitle: description,
    icon: icon,
    maxWidth: 460,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberField(
            controller: controller,
            label: label,
            icon: Icons.attach_money,
            suffix: currency,
            autofocus: true,
            errorText: error,
            onSubmitted: () {
              final v = Fmt.parseAmount(controller.text);
              if (v == null) {
                setState(() => error = 'Geçerli bir tutar girin.');
                return;
              }
              if (min != null && v < min) {
                setState(() => error = 'En az ${Fmt.number(min)} olmalıdır.');
                return;
              }
              if (max != null && v > max) {
                setState(() => error = 'En fazla ${Fmt.number(max)} olabilir.');
                return;
              }
              Navigator.pop(ctx, v);
            },
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
          if (max != null || min != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${min != null ? 'Alt sınır: ${Fmt.number(min)}' : ''}'
                '${min != null && max != null ? ' • ' : ''}'
                '${max != null ? 'Üst sınır: ${Fmt.number(max)}' : ''}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 18),
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
                  final v = Fmt.parseAmount(controller.text);
                  if (v == null) {
                    setState(() => error = 'Geçerli bir tutar girin.');
                    return;
                  }
                  if (min != null && v < min) {
                    setState(() => error = 'En az ${Fmt.number(min)} olmalıdır.');
                    return;
                  }
                  if (max != null && v > max) {
                    setState(() => error = 'En fazla ${Fmt.number(max)} olabilir.');
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                child: Text(confirmText),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Metin isteyen küçük diyalog.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? description,
  String? initial,
  String confirmText = 'Kaydet',
  IconData icon = Icons.edit_outlined,
  int maxLines = 1,
  int? maxLength,
  String? hint,
  bool required = true,
}) {
  final controller = TextEditingController(text: initial ?? '');
  String? error;

  return showAppDialog<String>(
    context,
    title: title,
    subtitle: description,
    icon: icon,
    maxWidth: 480,
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: error,
            ),
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
                  final value = controller.text.trim();
                  if (required && value.isEmpty) {
                    setState(() => error = 'Bu alan boş bırakılamaz.');
                    return;
                  }
                  Navigator.pop(ctx, value);
                },
                child: Text(confirmText),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Bilgilendirme diyaloğu.
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline,
  String? extra,
}) {
  return showAppDialog<void>(
    context,
    title: title,
    icon: icon,
    maxWidth: 460,
    child: Text(message, style: const TextStyle(height: 1.6)),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Anladım'),
      ),
    ],
  );
}

/// Kullanıcı seçici (aramalı, avatarlı).
Future<AppUser?> showUserPickerDialog(
  BuildContext context, {
  required List<AppUser> users,
  String title = 'Kullanıcı Seç',
  String? subtitle,
  Set<String> excludeIds = const {},
  bool includeInactive = true,
  String currency = '₺',
}) {
  final controller = TextEditingController();
  return showAppDialog<AppUser?>(
    context,
    title: title,
    subtitle: subtitle,
    icon: Icons.person_search_outlined,
    maxWidth: 520,
    scrollable: false,
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final query = controller.text.trim().toLowerCase();
        final filtered = users
            .where((u) => !excludeIds.contains(u.id))
            .where((u) => includeInactive || u.isActive)
            .where((u) =>
                query.isEmpty ||
                u.fullName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query) ||
                u.title.toLowerCase().contains(query))
            .toList();
        return Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ada, e-postaya veya unvana göre ara',
                prefixIcon: Icon(Icons.search, size: 19),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 340,
              child: filtered.isEmpty
                  ? const Center(child: Text('Sonuç bulunamadı.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (c, i) {
                        final u = filtered[i];
                        return ListTile(
                          dense: true,
                          leading: AvatarBubbleSmall(user: u),
                          title: Text(u.fullName),
                          subtitle: Text(
                            '${u.title} • ${u.email}'
                            '${u.isActive ? '' : ' • pasif'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(ctx, u),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

/// Küçük avatar (diyalog listeleri için).
class AvatarBubbleSmall extends StatelessWidget {
  final AppUser user;
  final double radius;

  const AvatarBubbleSmall({super.key, required this.user, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final color = user.avatarColor != 0
        ? Color(user.avatarColor)
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius * 0.7),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        Fmt.initials(user.fullName),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// Şirket seçici.
Future<Company?> showCompanyPickerDialog(
  BuildContext context, {
  required List<Company> companies,
  String title = 'Şirket Seç',
  String? subtitle,
}) {
  return showAppDialog<Company>(
    context,
    title: title,
    subtitle: subtitle,
    icon: Icons.business_outlined,
    maxWidth: 480,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in companies)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: (c.colorValue == 0
                      ? Theme.of(context).colorScheme.primary
                      : Color(c.colorValue))
                  .withValues(alpha: 0.2),
              child: Icon(
                Icons.business,
                color: c.colorValue == 0
                    ? Theme.of(context).colorScheme.primary
                    : Color(c.colorValue),
                size: 19,
              ),
            ),
            title: Text(c.name),
            subtitle: Text(
              '${c.sector.isEmpty ? 'Sektör belirtilmemiş' : c.sector} • '
              'sınır ${Fmt.number(c.salaryLimit)}',
            ),
            onTap: () => Navigator.pop(context, c),
          ),
      ],
    ),
  );
}
