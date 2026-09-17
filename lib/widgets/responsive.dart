import 'package:flutter/material.dart';

/// Ekran genişliği kırılım noktaları (Windows masaüstü odaklı).
class Breakpoints {
  Breakpoints._();

  /// Telefon / dar pencere
  static const double compact = 760;

  /// Tablet / küçük masaüstü penceresi
  static const double medium = 1120;

  /// Geniş masaüstü
  static const double wide = 1500;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  static bool isCompact(BuildContext context) => width(context) < compact;

  static bool isMedium(BuildContext context) =>
      width(context) >= compact && width(context) < medium;

  static bool isWide(BuildContext context) => width(context) >= medium;

  static bool isDesktop(BuildContext context) => width(context) >= 980;

  static bool useSidebar(BuildContext context) => width(context) >= 900;

  /// İçeriğe sığan sütun sayısı.
  static int columns(
    BuildContext context, {
    double minItemWidth = 250,
    int max = 4,
    double horizontalPadding = 48,
  }) {
    final available = width(context) - horizontalPadding;
    final count = (available / minItemWidth).floor();
    return count.clamp(1, max);
  }
}

/// Otomatik sarmalanan ızgara (sabit oran istemez, yüksekliği çocuk belirler).
class WrapGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  const WrapGrid({
    super.key,
    required this.children,
    this.minItemWidth = 250,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns = (available / minItemWidth).floor().clamp(1, maxColumns);
        if (columns <= 0) columns = 1;
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Geniş ekranda yan yana, dar ekranda alt alta yerleşim.
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final List<int> flex;
  final double breakpoint;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const AdaptiveRow({
    super.key,
    required this.children,
    this.flex = const [],
    this.breakpoint = Breakpoints.medium,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= breakpoint;
    if (!isWide) {
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
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(
            flex: i < flex.length ? flex[i] : 1,
            child: children[i],
          ),
          if (i != children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// İçeriği maksimum genişlikte ortalar.
class Centered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const Centered({
    super.key,
    required this.child,
    this.maxWidth = 1500,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Masaüstünde ayırıcılı, mobilde yığın görünümlü liste sarmalayıcı.
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveList({
    super.key,
    required this.children,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
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
}
