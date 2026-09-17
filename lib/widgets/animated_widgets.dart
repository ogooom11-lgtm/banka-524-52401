import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bank_provider.dart';

/// Sınırlı sayıda animasyon döngüsü oynatır.
///
/// Sonsuz (`repeat`) döngüler widget testlerinde `pumpAndSettle` çağrısının
/// asla sakinleşmemesine yol açtığı için tüm ortam animasyonları sınırlıdır.
void _playCycles(
  AnimationController controller, {
  int cycles = 3,
  bool reverse = false,
}) {
  var left = cycles;
  late void Function(AnimationStatus) listener;
  listener = (status) {
    if (status == AnimationStatus.completed) {
      if (reverse) {
        controller.reverse();
      } else {
        left -= 1;
        if (left <= 0) {
          controller.removeStatusListener(listener);
        } else {
          controller.forward(from: 0);
        }
      }
    } else if (status == AnimationStatus.dismissed) {
      left -= 1;
      if (left <= 0) {
        controller.removeStatusListener(listener);
      } else {
        controller.forward();
      }
    }
  };
  controller.addStatusListener(listener);
  controller.forward();
}

/// Yumuşak giriş animasyonu: aşağıdan yukarı + opaklık.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double offsetX;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 460),
    this.offsetY = 18,
    this.offsetX = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    final reduceMotion = context.read<BankProvider>().animationsEnabled == false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(
            widget.offsetX * (1 - _animation.value),
            widget.offsetY * (1 - _animation.value),
          ),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Çocukları sırayla (kademeli) canlandırır.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration step;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 70),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          FadeSlideIn(delay: step * i, child: children[i]),
          if (spacing > 0 && i != children.length - 1)
            SizedBox(height: spacing),
        ],
      ],
    );
  }
}

/// Hover'da hafifçe büyüyen / yükselen sarmalayıcı.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double scale;
  final double lift;
  final VoidCallback? onTap;
  final Duration duration;

  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.lift = 4,
    this.onTap,
    this.duration = const Duration(milliseconds: 170),
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: widget.duration,
          curve: Curves.easeOut,
          offset: Offset(0, _hovered ? -widget.lift / 100 : 0),
          child: AnimatedScale(
            duration: widget.duration,
            curve: Curves.easeOut,
            scale: _hovered ? widget.scale : 1,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Basıldığında küçülen dokunmatik alan (masaüstünde tıklama hissi).
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Nabız gibi atan canlı nokta.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const PulseDot({
    super.key,
    this.color = const Color(0xFF22C55E),
    this.size = 9,
    this.animate = true,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) _playCycles(_controller, cycles: 6);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.4,
      height: widget.size * 2.4,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.animate)
                Container(
                  width: widget.size * (1 + t * 1.6),
                  height: widget.size * (1 + t * 1.6),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// İskelet yükleme efekti.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 10,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _playCycles(_controller, cycles: 4);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);
    final highlight = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.13);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _controller.value * 2, 0),
            end: Alignment(1 + _controller.value * 2, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

/// Kayan gradyan arka plan + hafif ızgara deseni.
class GradientBackdrop extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration period;
  final bool animated;
  final bool showGrid;

  const GradientBackdrop({
    super.key,
    required this.child,
    required this.colors,
    this.period = const Duration(seconds: 18),
    this.animated = true,
    this.showGrid = true,
  });

  @override
  State<GradientBackdrop> createState() => _GradientBackdropState();
}

class _GradientBackdropState extends State<GradientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (widget.animated) {
      _playCycles(_controller, cycles: 2, reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.animated ? _controller.value : 0.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.6, -1),
              end: Alignment(1, 1 - t * 0.5),
              colors: widget.colors,
            ),
          ),
          child: child,
        );
      },
      child: CustomPaint(
        painter: widget.showGrid ? _GridPainter(dark: dark) : null,
        child: widget.child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool dark;
  _GridPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.030)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.dark != dark;
}

/// Sekme geçişlerinde yumuşak animasyon.
class AnimatedTabView extends StatelessWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedTabView({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, children.length - 1);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(safeIndex),
        child: children[safeIndex],
      ),
    );
  }
}

/// Açılır-kapanır bölüm (yardım sayfası ve ayarlar için).
class ExpandableSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final Color? accent;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.accent,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ?? scheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _expanded
              ? accent.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subtitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
