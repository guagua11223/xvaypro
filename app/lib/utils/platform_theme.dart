import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:system_theme/system_theme.dart';

import '../theme/lets_colors.dart';
import 'platform_version.dart';
import 'prefs.dart';
import 'runtime_platform.dart';
import 'theme_manager.dart';

bool getIsTransparentBG() {
  bool isTransparentBG = false;
  if (RuntimePlatform.isWindows) {
    final windowsVersionNumber = getPlatformVersionNumber();
    isTransparentBG =
        windowsVersionNumber != null && windowsVersionNumber >= 22000;
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

  if (RuntimePlatform.isWindows || RuntimePlatform.isMacOS) {
    return ThemeData(
      // colorSchemeSeed: SystemTheme.accentColor.accent,
      colorSchemeSeed: getColorSchemeSeed(),
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
      appBarTheme: LetsColors.appBarTheme(dark: false, transparent: isTransparentBG),
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
        seedColor: const Color(0xFF2457D6),
        brightness: Brightness.light,
        surface: const Color(0xFFF4F5F7),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F5F7),
      iconTheme: const IconThemeData(size: 22),
      cardTheme: CardThemeData(
        color: const Color(0xFFF7F8FA),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFD5D8DE), thickness: 1),
      appBarTheme: LetsColors.appBarTheme(dark: false),
    );
  }
}

ThemeData getPlatformDarkThemeData() {
  final isBlackDark = prefs.getBool("app.brightness.dark.black")!;
  bool isTransparentBG = getIsTransparentBG();

  if (RuntimePlatform.isWindows || RuntimePlatform.isMacOS) {
    return ThemeData(
      brightness: Brightness.dark,
      // colorSchemeSeed: SystemTheme.accentColor.accent,
      colorSchemeSeed: getColorSchemeSeed(),
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
        seedColor: const Color(0xFF2457D6),
        brightness: Brightness.dark,
        surface: const Color(0xFF12141A),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: isBlackDark
          ? const Color(0xFF0E1014)
          : const Color(0xFF12141A),
      iconTheme: const IconThemeData(size: 22),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1F27),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2C313C), thickness: 1),
      appBarTheme: LetsColors.appBarTheme(dark: true),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isBlackDark
            ? const Color.fromARGB(16, 255, 255, 255)
            : null,
      ),
    );
  }
}
