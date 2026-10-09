import 'package:flutter/material.dart';

/// Visual tokens matching the reference consumer VPN UI.
class LetsColors {
  static const pageBg = Color(0xFFF7F7F7);
  static const toolbarStart = Color(0xFFFC5B74);
  static const toolbarEnd = Color(0xFF00B6F9);
  static const accent = Color(0xFF2686EA);
  static const accentPressed = Color(0xFF2172C6);
  static const splash = Color(0xFF0E122D);
  static const orbPink = Color(0xFFFFB4C0);
  static const orbPinkDeep = Color(0xFFFC5B74);
  static const orbCyan = Color(0xFF00B6F9);
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF666666);
  static const divider = Color(0xFFD9D9D9);
  static const white = Color(0xFFFFFFFF);
  static const drawerHighlight = Color(0xFFDE618D);

  static const toolbarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [toolbarStart, toolbarEnd],
  );
}
