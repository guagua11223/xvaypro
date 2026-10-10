import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:system_theme/system_theme.dart';

import '../theme/lets_colors.dart';
import '../theme/lets_icons.dart';
import 'prefs.dart';
import 'runtime_platform.dart';
import 'theme_manager.dart';

bool getIsTransparentBG() {
  bool isTransparentBG = false;
  if (RuntimePlatform.isWindows) {
    // Windows uses the same solid page as Android. Mica makes the layout look broken.
    isTransparentBG = false;
  } else if (RuntimePlatform.isMacOS) {
    /// macos window theme can not be controlled by app
    isTransparentBG =
        ThemeManager().platformBrightnessIsDark == ThemeManager().isDark;
  }
  return isTransparentBG;
}

Color getColorSchemeSeed() {
  if (RuntimePlatform.isWeb) {
    return const Color.fromARGB(82, 0, 140, 255);
  }
  return SystemTheme.accentColor.accent;
}

ThemeData getPlatformThemeData() {
  bool isTransparentBG = getIsTransparentBG();

  if (RuntimePlatform.isMacOS) {
    return ThemeData(
      // colorSchemeSeed: SystemTheme.accentColor.accent,
      colorSchemeSeed: LetsColors.accent,
      useMaterial3: true,
      scaffoldBackgroundColor: isTransparentBG ? Colors.transparent : null,
      cardTheme: CardThemeData(
        color: const Color.fromARGB(240, 255, 255, 255),
        shadowColor: const Color.fromARGB(172, 0, 0, 0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      appBarTheme: LetsColors.appBarTheme(
        dark: false,
        transparent: isTransparentBG,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isTransparentBG ? Colors.transparent : null,
        indicatorColor: const Color.fromARGB(240, 255, 255, 255),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  } else {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: LetsColors.accent,
        brightness: Brightness.light,
        surface: LetsColors.pageBg,
      ).copyWith(primary: LetsColors.accent, onPrimary: LetsColors.onAccent),
      useMaterial3: true,
      scaffoldBackgroundColor: LetsColors.pageBg,
      iconTheme: const IconThemeData(size: LetsIcons.size, color: LetsColors.textPrimary),
      filledButtonTheme: _filledButtons(),
      elevatedButtonTheme: _elevatedButtons(),
      outlinedButtonTheme: _outlinedButtons(),
      cardTheme: CardThemeData(
        color: LetsColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LetsColors.divider,
        thickness: 1,
      ),
      appBarTheme: LetsColors.appBarTheme(dark: false),
    );
  }
}

ThemeData getPlatformDarkThemeData() {
  final isBlackDark = prefs.getBool("app.brightness.dark.black")!;
  bool isTransparentBG = getIsTransparentBG();

  if (RuntimePlatform.isMacOS) {
    return ThemeData(
      brightness: Brightness.dark,
      // colorSchemeSeed: SystemTheme.accentColor.accent,
      colorSchemeSeed: LetsColors.accent,
      useMaterial3: true,
      scaffoldBackgroundColor: isBlackDark
          ? Colors.black
          : isTransparentBG
          ? Colors.transparent
          : null,
      cardTheme: CardThemeData(
        color: const Color.fromARGB(16, 255, 255, 255),
        shadowColor: const Color.fromARGB(64, 0, 0, 0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      appBarTheme: LetsColors.appBarTheme(
        dark: true,
        transparent: isTransparentBG && !isBlackDark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isBlackDark
            ? Colors.black
            : isTransparentBG
            ? Colors.transparent
            : null,
        indicatorColor: const Color.fromARGB(16, 255, 255, 255),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  } else {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LetsColors.accent,
        brightness: Brightness.dark,
        surface: LetsColors.pageBgDark,
      ).copyWith(primary: LetsColors.accent, onPrimary: LetsColors.onAccent),
      useMaterial3: true,
      scaffoldBackgroundColor: isBlackDark
          ? const Color(0xFF000000)
          : LetsColors.pageBgDark,
      iconTheme: const IconThemeData(
        size: LetsIcons.size,
        color: LetsColors.textPrimaryDark,
      ),
      filledButtonTheme: _filledButtons(),
      elevatedButtonTheme: _elevatedButtons(),
      outlinedButtonTheme: _outlinedButtons(),
      cardTheme: CardThemeData(
        color: LetsColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LetsColors.dividerDark,
        thickness: 1,
      ),
      appBarTheme: LetsColors.appBarTheme(dark: true),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isBlackDark
            ? const Color.fromARGB(16, 255, 255, 255)
            : null,
      ),
    );
  }
}

FilledButtonThemeData _filledButtons() {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: LetsColors.accent,
      foregroundColor: LetsColors.onAccent,
      elevation: 0,
      shape: LetsColors.buttonShape,
    ),
  );
}

ElevatedButtonThemeData _elevatedButtons() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LetsColors.accent,
      foregroundColor: LetsColors.onAccent,
      elevation: 0,
      shape: LetsColors.buttonShape,
    ),
  );
}

OutlinedButtonThemeData _outlinedButtons() {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LetsColors.accent,
      side: const BorderSide(color: LetsColors.accent),
      shape: LetsColors.buttonShape,
    ),
  );
}
