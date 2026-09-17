import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan vurgu (accent) paletleri.
class AccentPreset {
  final String id;
  final String label;
  final Color seed;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color danger;
  final List<Color> gradient;

  const AccentPreset({
    required this.id,
    required this.label,
    required this.seed,
    required this.secondary,
    required this.gradient,
    this.success = const Color(0xFF2EBD85),
    this.warning = const Color(0xFFF5A524),
    this.danger = const Color(0xFFF31260),
  });
}

const List<AccentPreset> kAccentPresets = [
  AccentPreset(
    id: 'indigo',
    label: 'İndigo',
    seed: Color(0xFF4F5BD5),
    secondary: Color(0xFF00BFA6),
    gradient: [Color(0xFF3A47C4), Color(0xFF7C4DFF)],
  ),
  AccentPreset(
    id: 'emerald',
    label: 'Zümrüt',
    seed: Color(0xFF0E9F6E),
    secondary: Color(0xFF14B8A6),
    gradient: [Color(0xFF059669), Color(0xFF34D399)],
  ),
  AccentPreset(
    id: 'ocean',
    label: 'Okyanus',
    seed: Color(0xFF1D6FE0),
    secondary: Color(0xFF06B6D4),
    gradient: [Color(0xFF1552C0), Color(0xFF38BDF8)],
  ),
  AccentPreset(
    id: 'violet',
    label: 'Mor',
    seed: Color(0xFF8B3DFF),
    secondary: Color(0xFFE879F9),
    gradient: [Color(0xFF6D28D9), Color(0xFFC084FC)],
  ),
  AccentPreset(
    id: 'sunset',
    label: 'Gün Batımı',
    seed: Color(0xFFF97316),
    secondary: Color(0xFFEC4899),
    gradient: [Color(0xFFEA580C), Color(0xFFF472B6)],
  ),
  AccentPreset(
    id: 'gold',
    label: 'Altın',
    seed: Color(0xFFC79217),
    secondary: Color(0xFFEAB308),
    gradient: [Color(0xFFA16207), Color(0xFFFACC15)],
  ),
  AccentPreset(
    id: 'rose',
    label: 'Gül',
    seed: Color(0xFFE11D48),
    secondary: Color(0xFFFB7185),
    gradient: [Color(0xFFBE123C), Color(0xFFFB7185)],
  ),
  AccentPreset(
    id: 'graphite',
    label: 'Grafit',
    seed: Color(0xFF4B5563),
    secondary: Color(0xFF94A3B8),
    gradient: [Color(0xFF334155), Color(0xFF94A3B8)],
  ),
];

AccentPreset accentById(String? id) {
  for (final p in kAccentPresets) {
    if (p.id == id) return p;
  }
  return kAccentPresets.first;
}

/// Arayüz yoğunluğu (masaüstünde daha sıkı listeler tercih edilir).
enum UiDensity {
  compact('Sıkı', 0.86),
  normal('Normal', 1.0),
  comfortable('Rahat', 1.14);

  final String label;
  final double scale;
  const UiDensity(this.label, this.scale);

  static UiDensity fromId(String? id) {
    for (final d in UiDensity.values) {
      if (d.name == id) return d;
    }
    return UiDensity.normal;
  }
}

/// Merkezî tema üreticisi. Ayar değişikliklerinde yeniden kurulur.
class AppTheme {
  AppTheme._();

  static const List<Color> _darkBg = [
    Color(0xFF0B1020),
    Color(0xFF10162B),
  ];
  static const List<Color> _lightBg = [
    Color(0xFFF4F6FB),
    Color(0xFFEDF1F9),
  ];

  static List<Color> scaffoldGradient(bool dark, AccentPreset preset) {
    if (dark) return _darkBg;
    return _lightBg;
  }

  static ThemeData build({
    required bool dark,
    required AccentPreset preset,
    required UiDensity density,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: preset.seed,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      secondary: preset.secondary,
      error: preset.danger,
    );

    final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: dark ? Brightness.dark : Brightness.light,
      textTheme: text,
      visualDensity: VisualDensity(
        horizontal: density == UiDensity.compact ? -1 : 0,
        vertical: density == UiDensity.compact
            ? -1
            : (density == UiDensity.comfortable ? 1 : 0),
      ),
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0B1020) : const Color(0xFFF4F6FB),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.black.withValues(alpha: 0.025),
        isDense: density == UiDensity.compact,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        backgroundColor: dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.7),
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: scheme.onSurfaceVariant,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E2438) : const Color(0xFF2A3040),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1B2136) : const Color(0xFF232A3D),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF141A2E) : Colors.white,
        elevation: 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF141A2E) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? const Color(0xFF1A2136) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 10,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.15),
        circularTrackColor: scheme.primary.withValues(alpha: 0.15),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 6,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurface.withValues(alpha: 0.22),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.28),
        selectionHandleColor: scheme.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
