import 'package:flutter/material.dart';

/// Word Quest pastel palette.
class Pal {
  const Pal._();

  static const Color ink = Color(0xFF3D3654); // deep soft purple-grey
  static const Color inkSoft = Color(0xFF6F6790);
  static const Color lavender = Color(0xFF9D8BE0);
  static const Color lavenderSoft = Color(0xFFECE6FB);
  static const Color blush = Color(0xFFF3A0BC);
  static const Color blushSoft = Color(0xFFFDE7EF);
  static const Color mint = Color(0xFF8CCFA9);
  static const Color mintSoft = Color(0xFFDFF4E8);
  static const Color sky = Color(0xFF7FB4E8);
  static const Color skySoft = Color(0xFFE1EFFB);
  static const Color butter = Color(0xFFE8B660);
  static const Color butterSoft = Color(0xFFFBF0D9);
  static const Color peachSoft = Color(0xFFFBE3DB);
  static const Color surface = Color(0xFFF8F4FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEDE6F7);
  static const Color danger = Color(0xFFE5738F);
}

/// A pastel colour pair used to give every topic its own accent.
class TopicColor {
  const TopicColor(this.main, this.soft);

  final Color main;
  final Color soft;
}

/// Topic accent colours in the same order as the vocab topics.
const List<TopicColor> topicAccents = <TopicColor>[
  TopicColor(Pal.lavender, Pal.lavenderSoft),
  TopicColor(Pal.sky, Pal.skySoft),
  TopicColor(Pal.mint, Pal.mintSoft),
  TopicColor(Pal.blush, Pal.blushSoft),
  TopicColor(Pal.butter, Pal.butterSoft),
];

/// Soft shadow used on rounded cards ("soft shadow" design requirement).
const List<BoxShadow> softShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x246E5FB5),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
];

const List<BoxShadow> tinyShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x186E5FB5),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

/// Alpha helper that works on both Flutter 3.24 (`withOpacity`) and newer
/// SDKs that removed it in favour of `withValues`.
Color fade(Color color, double opacity) {
  int alpha = (opacity * 255).round();
  if (alpha < 0) {
    alpha = 0;
  } else if (alpha > 255) {
    alpha = 255;
  }
  return color.withAlpha(alpha);
}

ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: Pal.lavender,
    brightness: Brightness.light,
  ).copyWith(
    primary: Pal.lavender,
    onPrimary: Colors.white,
    secondary: Pal.blush,
    onSecondary: Colors.white,
    surface: Pal.surface,
    onSurface: Pal.ink,
    outline: Pal.border,
    outlineVariant: Pal.border,
    error: Pal.danger,
    errorContainer: Pal.blushSoft,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.surface,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Pal.lavender,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pal.lavender,
        side: const BorderSide(color: Pal.lavender, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Pal.lavender,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Pal.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Pal.lavender,
      thumbColor: Pal.lavender,
      inactiveTrackColor: Pal.border,
      overlayColor: fade(Pal.lavender, 0.12),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Pal.lavender),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fade(Pal.lavenderSoft, 0.5),
      hintStyle: const TextStyle(color: Pal.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Pal.lavender, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: Pal.ink,
        letterSpacing: 0.2,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        color: Pal.ink,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: Pal.ink),
      bodyLarge: TextStyle(height: 1.45, color: Pal.ink),
      bodyMedium: TextStyle(height: 1.45, color: Pal.ink),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
