import 'package:flutter/material.dart';

/// ICEBERG dark design language — tokens sampled from the design reference
/// screenshots (dark navy/teal surfaces, lime neon accent, mint secondary).
///
/// All student screens read these via `context.ice` so the appearance
/// settings (theme + accent colour) can swap the whole palette at runtime.
class IceTokens extends ThemeExtension<IceTokens> {
  // Surfaces
  final Color bg; // page background
  final Color card; // standard card
  final Color cardHi; // gradient top of hero cards
  final Color cardLo; // gradient bottom of hero cards
  final Color inset; // inset fields / chips on cards
  final Color stroke; // hairline card border

  // Text
  final Color textHi;
  final Color textMid;
  final Color textLow;

  // Brand
  final Color accent; // lime by default
  final Color onAccent; // dark text on the accent
  final Color mint; // soft cyan/mint secondary (ICEBERG wordmark)

  // Semantics
  final Color coral; // absent / overdue / danger
  final Color sky; // late / info
  final Color amber; // pending / warning

  final bool isDark;

  const IceTokens({
    required this.bg,
    required this.card,
    required this.cardHi,
    required this.cardLo,
    required this.inset,
    required this.stroke,
    required this.textHi,
    required this.textMid,
    required this.textLow,
    required this.accent,
    required this.onAccent,
    required this.mint,
    required this.coral,
    required this.sky,
    required this.amber,
    required this.isDark,
  });

  factory IceTokens.dark({Color accent = IceAccents.lime}) => IceTokens(
    bg: const Color(0xFF071719),
    card: const Color(0xFF0D2529),
    cardHi: const Color(0xFF12333A),
    cardLo: const Color(0xFF0A2024),
    inset: const Color(0xFF123034),
    stroke: const Color(0xFF1B3D42),
    textHi: const Color(0xFFF1FAF8),
    textMid: const Color(0xFF9FBDBA),
    textLow: const Color(0xFF5F7F7D),
    accent: accent,
    onAccent: const Color(0xFF13230F),
    mint: const Color(0xFFB8E0DB),
    coral: const Color(0xFFF2917F),
    sky: const Color(0xFF93D2EC),
    amber: const Color(0xFFF4C95D),
    isDark: true,
  );

  factory IceTokens.light({Color accent = IceAccents.lime}) => IceTokens(
    bg: const Color(0xFFF4F8F7),
    card: Colors.white,
    cardHi: const Color(0xFF0E3A41), // hero cards stay deep teal in light mode
    cardLo: const Color(0xFF082329),
    inset: const Color(0xFFEAF2F0),
    stroke: const Color(0xFFD8E6E3),
    textHi: const Color(0xFF0A2A2E),
    textMid: const Color(0xFF55726F),
    textLow: const Color(0xFF8AA3A0),
    accent: accent,
    onAccent: const Color(0xFF13230F),
    mint: const Color(0xFF0E6873),
    coral: const Color(0xFFE0584A),
    sky: const Color(0xFF2E96C4),
    amber: const Color(0xFFD79A22),
    isDark: false,
  );

  /// Slightly translucent accent for soft fills behind icons.
  Color get accentSoft => accent.withValues(alpha: 0.14);
  Color get coralSoft => coral.withValues(alpha: 0.14);
  Color get skySoft => sky.withValues(alpha: 0.16);
  Color get amberSoft => amber.withValues(alpha: 0.16);

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardHi, cardLo],
  );

  @override
  IceTokens copyWith({Color? accent}) => accent == null
      ? this
      : (isDark
            ? IceTokens.dark(accent: accent)
            : IceTokens.light(accent: accent));

  @override
  IceTokens lerp(ThemeExtension<IceTokens>? other, double t) {
    if (other is! IceTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return IceTokens(
      bg: l(bg, other.bg),
      card: l(card, other.card),
      cardHi: l(cardHi, other.cardHi),
      cardLo: l(cardLo, other.cardLo),
      inset: l(inset, other.inset),
      stroke: l(stroke, other.stroke),
      textHi: l(textHi, other.textHi),
      textMid: l(textMid, other.textMid),
      textLow: l(textLow, other.textLow),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      mint: l(mint, other.mint),
      coral: l(coral, other.coral),
      sky: l(sky, other.sky),
      amber: l(amber, other.amber),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Accent palette selectable in Settings → Appearance.
class IceAccents {
  static const lime = Color(0xFFCDF163);
  static const cyan = Color(0xFF6FE3D4);
  static const pink = Color(0xFFF49AC1);
  static const purple = Color(0xFFC49BF4);
  static const blue = Color(0xFF7FB7F7);
  static const orange = Color(0xFFF5B36B);

  static const byName = <String, Color>{
    'lime': lime,
    'cyan': cyan,
    'pink': pink,
    'purple': purple,
    'blue': blue,
    'orange': orange,
  };
}

extension IceContext on BuildContext {
  IceTokens get ice =>
      Theme.of(this).extension<IceTokens>() ?? IceTokens.dark();
}

/// Builds the student-app ThemeData carrying [IceTokens].
ThemeData buildIceTheme({required bool dark, required Color accent}) {
  final t = dark
      ? IceTokens.dark(accent: accent)
      : IceTokens.light(accent: accent);
  final base = dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    extensions: [t],
    scaffoldBackgroundColor: t.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.mint,
      surface: t.card,
      onSurface: t.textHi,
      error: t.coral,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: t.textHi,
      displayColor: t.textHi,
    ),
    splashFactory: InkSparkle.splashFactory,
    dividerColor: t.stroke,
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.textHi,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.inset,
      hintStyle: TextStyle(color: t.textLow, fontSize: 14),
      labelStyle: TextStyle(color: t.textMid, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.coral),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.cardHi,
      contentTextStyle: TextStyle(color: t.textHi, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
  );
}
