import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction.dart';
import '../providers/bank_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Geriye dönük uyumlu para biçimlendirme yardımcısı.
String money(
  double v,
  String currency, {
  int digits = 2,
  bool symbolAfter = true,
  bool signed = false,
  bool compact = false,
}) =>
    Fmt.money(
      v,
      currency,
      digits: digits,
      symbolAfter: symbolAfter,
      signed: signed,
      compact: compact,
    );

/// Uygulamanın standart yüzeyi: yumuşak kenarlı, hover'da yükselen kart.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final LinearGradient? gradient;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool hoverable;
  final double elevation;
  final bool blurGlow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.onSecondaryTap,
    this.gradient,
    this.color,
    this.borderColor,
    this.radius = 20,
    this.hoverable = true,
    this.elevation = 0,
    this.blurGlow = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.color ??
        (dark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.85));
    final border = widget.borderColor ??
        (_hovered
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.7));

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: widget.padding,
      transform: Matrix4.translationValues(0, _hovered && widget.hoverable ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: widget.gradient == null ? base : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: (widget.blurGlow ? scheme.primary : Colors.black)
                .withValues(alpha: _hovered ? 0.16 : 0.06),
            blurRadius: _hovered ? 26 : 14,
            offset: Offset(0, _hovered ? 10 : 5),
          ),
        ],
      ),
      child: widget.child,
    );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: card,
      ),
    );
  }
}

/// Bölüm başlığı (ikon + açıklama + aksiyon).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Renkli küçük etiket.
class PillBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool dense;
  final VoidCallback? onTap;

  const PillBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: c,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: content,
    );
  }
}

/// Baş harfleri gösteren renkli avatar.
class AvatarBubble extends StatelessWidget {
  final String name;
  final int colorValue;
  final double radius;
  final bool showStatus;
  final bool isActive;

  const AvatarBubble({
    super.key,
    required this.name,
    this.colorValue = 0,
    this.radius = 20,
    this.showStatus = false,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = colorValue != 0
        ? Color(colorValue)
        : Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: dark ? 0.85 : 0.95),
                Color.lerp(color, Colors.black, dark ? 0.45 : 0.15)!,
              ],
            ),
            borderRadius: BorderRadius.circular(radius * 0.66),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            Fmt.initials(name),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.72,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.62,
              height: radius * 0.62,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// İstatistik kartı — sayısal değerler animasyonla artar.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final double? numericValue;
  final bool currencyStyle;
  final int digits;
  final VoidCallback? onTap;
  final double? trendPercent;
  final String? trendLabel;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.numericValue,
    this.currencyStyle = true,
    this.digits = 2,
    this.onTap,
    this.trendPercent,
    this.trendLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final bank = context.read<BankProvider>();

    Widget valueWidget() {
      if (numericValue != null) {
        return AnimatedCounter(
          value: numericValue!,
          digits: digits,
          currency: currencyStyle ? bank.currency : null,
          symbolAfter: bank.symbolAfter,
          compact: currencyStyle && numericValue!.abs() > 100000,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        );
      }
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      blurGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.withValues(alpha: 0.28),
                      c.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          valueWidget(),
          const SizedBox(height: 6),
          Row(
            children: [
              if (trendPercent != null) ...[
                Icon(
                  trendPercent! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: trendPercent! >= 0
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  Fmt.percent(trendPercent!.abs()),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: trendPercent! >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trendLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.outline,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ] else if (subtitle != null)
                Expanded(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animasyonlu sayı göstergesi.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final int digits;
  final String? currency;
  final bool symbolAfter;
  final bool compact;
  final TextStyle? style;
  final Duration duration;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.digits = 2,
    this.currency,
    this.symbolAfter = true,
    this.compact = false,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text = currency == null
            ? Fmt.number(v, digits: digits)
            : Fmt.money(
                v,
                currency!,
                digits: digits,
                symbolAfter: symbolAfter,
                compact: compact,
              );
        return Text('$prefix$text', style: style);
      },
    );
  }
}

/// Etiket / değer satırı.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Widget? trailing;
  final bool dense;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 7),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: dense ? 11.5 : 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
                fontSize: dense ? 12.5 : 13.5,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// İnce ilerleme çubuğu.
class MiniProgress extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final bool showLabel;
  final String? label;

  const MiniProgress({
    super.key,
    required this.value,
    this.color,
    this.height = 7,
    this.showLabel = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  Fmt.percent(clamped * 100, digits: 0),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: height,
              backgroundColor: c.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
        ),
      ],
    );
  }
}

/// Boş durum gösterimi.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.action,
    this.iconSize = 46,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Arama kutusu (temizleme düğmeli).
class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final double? width;
  final Widget? suffix;
  final bool enabled;

  const SearchInput({
    super.key,
    required this.controller,
    this.hint = 'Ara...',
    this.onChanged,
    this.width,
    this.suffix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 19),
            suffixIcon: value.text.isEmpty
                ? suffix
                : IconButton(
                    tooltip: 'Temizle',
                    icon: const Icon(Icons.close, size: 17),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// Araç çubuğu ikon düğmesi (hover + ipucu).
class IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool filled;
  final int? badgeCount;

  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.filled = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    final button = Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 19,
        style: IconButton.styleFrom(
          backgroundColor: filled ? c.withValues(alpha: 0.14) : null,
          foregroundColor: c,
        ),
        icon: Icon(icon),
      ),
    );
    if (badgeCount == null || badgeCount == 0) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeCount! > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hareket türüne göre ikon ve renk.
class TxnIcon {
  static IconData of(TxnType t) {
    switch (t) {
      case TxnType.salary:
        return Icons.payments_outlined;
      case TxnType.bonus:
        return Icons.card_giftcard;
      case TxnType.penalty:
        return Icons.gavel_outlined;
      case TxnType.randomDeduction:
        return Icons.casino_outlined;
      case TxnType.promotion:
        return Icons.trending_up;
      case TxnType.transfer:
        return Icons.swap_horiz;
      case TxnType.credit:
        return Icons.account_balance_wallet_outlined;
      case TxnType.terminationFee:
        return Icons.description_outlined;
      case TxnType.loan:
        return Icons.request_quote_outlined;
      case TxnType.loanRepayment:
        return Icons.event_repeat_outlined;
      case TxnType.tax:
        return Icons.percent;
      case TxnType.expense:
        return Icons.receipt_long_outlined;
      case TxnType.interest:
        return Icons.savings_outlined;
      case TxnType.refund:
        return Icons.undo_rounded;
      case TxnType.system:
        return Icons.settings_suggest_outlined;
    }
  }

  static Color colorOf(TxnType t) {
    if (t.isIncoming) return const Color(0xFF10B981);
    if (t.isOutgoing) return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }
}

/// Hareket listesi satırı.
class TxnListTile extends StatelessWidget {
  final Txn txn;
  final String currency;
  final int digits;
  final bool dense;
  final String? perspectiveId;
  final VoidCallback? onTap;

  const TxnListTile({
    super.key,
    required this.txn,
    required this.currency,
    this.digits = 2,
    this.dense = true,
    this.perspectiveId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = TxnIcon.colorOf(txn.type);
    double effect = 0;
    if (perspectiveId != null) {
      effect = txn.effectFor(perspectiveId!);
    } else if (txn.type.isIncoming) {
      effect = txn.amount;
    } else if (txn.type.isOutgoing) {
      effect = -txn.amount;
    }
    final showSign = effect != 0;
    final amountText = Fmt.money(
      txn.amount,
      currency,
      digits: digits,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: dense ? 9 : 13,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(dense ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(TxnIcon.of(txn.type),
                  size: dense ? 16 : 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: dense ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${txn.type.label} • ${Fmt.dateTime(txn.date)}',
                    style: TextStyle(
                      fontSize: dense ? 10.5 : 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${showSign && effect > 0 ? '+' : (showSign ? '-' : '')}$amountText',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: dense ? 13 : 14.5,
                    color: showSign ? color : scheme.onSurfaceVariant,
                  ),
                ),
                if (showSign)
                  Text(
                    effect > 0 ? 'giriş' : 'çıkış',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Metni panoya kopyalar ve bilgi mesajı gösterir.
Future<void> copyToClipboard(BuildContext context, String value,
    {String label = 'Panoya kopyalandı'}) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) showSnackBar(context, label, icon: Icons.copy_rounded);
}

Future<void> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Onayla',
  String cancelText = 'İptal',
  Color? confirmColor,
  IconData? icon,
  bool danger = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: icon == null
          ? null
          : Icon(icon,
              size: 30,
              color: danger ? scheme.error : scheme.primary),
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(cancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger
                ? scheme.error
                : (confirmColor ?? scheme.primary),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

void showSnackBar(
  BuildContext context,
  String msg, {
  bool error = false,
  bool success = true,
  IconData? icon,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  final scheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final Color accent = error
      ? scheme.error
      : (success ? const Color(0xFF10B981) : scheme.primary);
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      action: action,
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon ??
                  (error
                      ? Icons.error_outline
                      : (success ? Icons.check_circle_outline : Icons.info_outline)),
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Hata mesajlarını kullanıcı dostu biçimde gösterir.
void showError(BuildContext context, Object error) {
  showSnackBar(
    context,
    error.toString().replaceAll('Exception: ', ''),
    error: true,
  );
}

/// Bölüm arka planı — sayfa gövdesi.
class PageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final ScrollController? controller;

  const PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 28),
    this.scrollable = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!scrollable) return Padding(padding: padding, child: child);
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: child,
        ),
      ),
    );
  }
}

/// Renk seçici palet.
class ColorChoiceRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final List<int> colors;

  const ColorChoiceRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = const [
      0xFF4F5BD5,
      0xFF0E9F6E,
      0xFF1D6FE0,
      0xFF8B3DFF,
      0xFFF97316,
      0xFFC79217,
      0xFFE11D48,
      0xFF4B5563,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(c).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: selected == c
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Yoğunluk temasına göre ölçeklenen boşluk.
double gapFor(BuildContext context, double base) {
  final density = UiDensity.fromId(context.watch<BankProvider>().densityId);
  return base * density.scale;
}
