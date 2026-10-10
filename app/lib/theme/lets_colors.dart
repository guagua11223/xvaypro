import 'package:flutter/material.dart';

/// Connectivity palette. One cyan accent, navy ink, 8pt radius system:
/// cards 16, inputs and buttons 12.
class LetsColors {
  static const accent = Color(0xFF0E7490);
  static const accentPressed = Color(0xFF155E75);
  static const onAccent = Color(0xFFF8FAFC);

  static const pageBg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF020617);
  static const textSecondary = Color(0xFF475569);
  static const divider = Color(0xFFE2E8F0);
  static const white = Color(0xFFF8FAFC);

  static const danger = Color(0xFFDC2626);
  static const seriesDirect = Color(0xFF64748B);

  static const splash = Color(0xFF020617);
  static const pageBgDark = Color(0xFF020617);
  static const surfaceDark = Color(0xFF0F172A);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const dividerDark = Color(0xFF1E293B);

  static const radiusCard = 16.0;
  static const radiusInput = 12.0;

  static const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
  );

  /// Windows desktop shell (Lets-style sidebar).
  static const deskBlue = Color(0xFF1877F2);
  static const deskBlueDark = Color(0xFF1464D0);
  static const deskPink = Color(0xFFD6538D);
  static const deskPinkDark = Color(0xFFC0447A);
  static const deskSidebar = Color(0xFFEEF1F5);
  static const deskPage = Color(0xFFF7F8FA);
  static const deskBanner = Color(0xFFE8F1FC);

  static LetsPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? LetsPalette.dark : LetsPalette.light;
  }

  static AppBarTheme appBarTheme({required bool dark, bool transparent = false}) {
    final palette = dark ? LetsPalette.dark : LetsPalette.light;
    final foreground = transparent ? palette.text : palette.onBar;
    return AppBarTheme(
      backgroundColor: transparent ? Colors.transparent : palette.bar,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      iconTheme: IconThemeData(color: foreground, size: 22),
      actionsIconTheme: IconThemeData(color: foreground, size: 22),
      titleTextStyle: TextStyle(
        color: foreground,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class LetsPalette {
  const LetsPalette({
    required this.page,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.bar,
    required this.onBar,
  });

  final Color page;
  final Color surface;
  final Color text;
  final Color muted;
  final Color line;
  final Color bar;
  final Color onBar;

  static const light = LetsPalette(
    page: LetsColors.pageBg,
    surface: LetsColors.surface,
    text: LetsColors.textPrimary,
    muted: LetsColors.textSecondary,
    line: LetsColors.divider,
    bar: LetsColors.ink,
    onBar: LetsColors.onAccent,
  );

  static const dark = LetsPalette(
    page: LetsColors.pageBgDark,
    surface: LetsColors.surfaceDark,
    text: LetsColors.textPrimaryDark,
    muted: LetsColors.textSecondaryDark,
    line: LetsColors.dividerDark,
    bar: LetsColors.pageBgDark,
    onBar: LetsColors.textPrimaryDark,
  );
}
