import 'package:flutter/material.dart';

/// One accent, cool gray surfaces. Radius: buttons are pills, cards are 16, inputs are 12.
class LetsColors {
  static const accent = Color(0xFF2457D6);
  static const accentPressed = Color(0xFF1C46B0);
  static const onAccent = Color(0xFFF7F8FA);

  static const pageBg = Color(0xFFF4F5F7);
  static const surface = Color(0xFFF7F8FA);
  static const ink = Color(0xFF1C2430);
  static const textPrimary = Color(0xFF1C1E24);
  static const textSecondary = Color(0xFF5C6370);
  static const divider = Color(0xFFD5D8DE);
  static const white = Color(0xFFF7F8FA);

  static const splash = Color(0xFF12141A);
  static const pageBgDark = Color(0xFF12141A);
  static const surfaceDark = Color(0xFF1C1F27);
  static const textPrimaryDark = Color(0xFFF2F3F5);
  static const textSecondaryDark = Color(0xFFA7ADB8);
  static const dividerDark = Color(0xFF2C313C);

  static const radiusCard = 16.0;
  static const radiusInput = 12.0;

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
        fontWeight: FontWeight.w600,
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
    bar: Color(0xFF161A22),
    onBar: LetsColors.textPrimaryDark,
  );
}
