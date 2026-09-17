import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Grafik çubuğu verisi.
class ChartBar {
  final String label;
  final List<double> values;
  final List<Color> colors;

  const ChartBar({
    required this.label,
    required this.values,
    required this.colors,
  });
}

/// Gruplu çubuk grafik (gelir / gider / maaş karşılaştırması).
class GroupedBarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final List<String> seriesLabels;
  final double height;
  final String currency;
  final int digits;
  final bool showValues;

  const GroupedBarChart({
    super.key,
    required this.bars,
    required this.seriesLabels,
    required this.currency,
    this.height = 220,
    this.digits = 0,
    this.showValues = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Grafik için veri yok.')),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < seriesLabels.length; i++) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bars.first.colors.length > i
                      ? bars.first.colors[i]
                      : scheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                seriesLabels[i],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size.infinite,
              painter: _BarPainter(
                bars: bars,
                progress: t,
                textColor: scheme.onSurfaceVariant,
                gridColor: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<ChartBar> bars;
  final double progress;
  final Color textColor;
  final Color gridColor;

  _BarPainter({
    required this.bars,
    required this.progress,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomSpace = 26.0;
    const topSpace = 8.0;
    final chartHeight = size.height - bottomSpace - topSpace;
    if (chartHeight <= 0) return;

    double maxValue = 0;
    for (final bar in bars) {
      for (final v in bar.values) {
        if (v > maxValue) maxValue = v;
      }
    }
    if (maxValue <= 0) maxValue = 1;

    // Yatay kılavuz çizgileri
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const lines = 4;
    for (var i = 0; i <= lines; i++) {
      final y = topSpace + chartHeight * (i / lines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final groupWidth = size.width / bars.length;
    final barCount = bars.first.values.length;
    final barWidth =
        (groupWidth * 0.62 / barCount).clamp(3.0, 26.0);
    final radius = Radius.circular(barWidth / 2.4);

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final groupCenter = groupWidth * i + groupWidth / 2;
      final totalWidth = barWidth * barCount + 6 * (barCount - 1);
      var x = groupCenter - totalWidth / 2;

      for (var j = 0; j < bar.values.length; j++) {
        final value = bar.values[j] * progress;
        final barHeight = maxValue == 0 ? 0.0 : (value / maxValue) * chartHeight;
        final rect = Rect.fromLTWH(
          x,
          topSpace + chartHeight - barHeight,
          barWidth,
          barHeight,
        );
        final color = j < bar.colors.length
            ? bar.colors[j]
            : ThemeData.dark().colorScheme.primary;
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.55),
            ],
          ).createShader(rect);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
        x += barWidth + 6;
      }

      // Ay etiketi
      final tp = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: TextStyle(fontSize: 10.5, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: groupWidth);
      tp.paint(
        canvas,
        Offset(groupCenter - tp.width / 2, size.height - bottomSpace + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.bars != bars;
}

/// Halka grafik (pasta grafiğin modern hali).
class DonutSlice {
  final String label;
  final double value;
  final Color color;

  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final String centerTitle;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 190,
    this.thickness = 22,
    this.centerTitle = 'Toplam',
    this.centerValue = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _DonutPainter(
            slices: total <= 0 ? const [] : slices,
            total: total,
            thickness: thickness,
            progress: t,
            background: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    child: Text(
                      centerValue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double total;
  final double thickness;
  final double progress;
  final Color background;

  _DonutPainter({
    required this.slices,
    required this.total,
    required this.thickness,
    required this.progress,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - thickness) / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = background;
    canvas.drawCircle(center, radius, bg);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    final gap = 0.035;
    for (final slice in slices) {
      final sweep = (slice.value / total) * (2 * math.pi) * progress;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        math.max(sweep - gap, 0.01),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.slices != slices;
}

/// Küçük çizgi grafik (sparkline).
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final double height;
  final bool fill;

  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.height = 46,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _SparkPainter(
            values: values,
            color: c,
            progress: t,
            fill: fill,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double progress;
  final bool fill;

  _SparkPainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    double minV = values.first;
    double maxV = values.first;
    for (final v in values) {
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height * 0.86 - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final visible = _trimPath(path, progress);
    if (fill) {
      final fillPath = Path.from(visible)
        ..lineTo(dx * (values.length - 1) * progress, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      visible,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  Path _trimPath(Path source, double progress) {
    final metrics = source.computeMetrics().toList();
    final out = Path();
    for (final m in metrics) {
      out.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress || old.values != values;
}

/// Dairesel ilerleme göstergesi (sözleşme / kredi doluluk oranı).
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double thickness;
  final Color? color;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 74,
    this.thickness = 8,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final v = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: animated,
                strokeWidth: thickness,
                strokeCap: StrokeCap.round,
                backgroundColor: c.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(c),
              ),
            ),
            child ??
                Text(
                  Fmt.percent(animated * 100, digits: 0),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.22,
                    color: c,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Basit yatay çubuk listesi (kategoriler için).
class HorizontalBars extends StatelessWidget {
  final List<DonutSlice> items;
  final String Function(double value) formatValue;
  final double barHeight;

  const HorizontalBars({
    super.key,
    required this.items,
    required this.formatValue,
    this.barHeight = 10,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = items.fold<double>(0, (s, e) => s + e.value);
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    Text(
                      formatValue(item.value),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        total <= 0
                            ? '%0'
                            : Fmt.percent(item.value / total * 100, digits: 0),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: total <= 0 ? 0 : (item.value / total).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: barHeight,
                      backgroundColor: item.color.withValues(alpha: 0.14),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
