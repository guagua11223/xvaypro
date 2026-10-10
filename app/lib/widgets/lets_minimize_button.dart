import 'package:flutter/material.dart';

import '../theme/lets_colors.dart';
import '../utils/minimize_app.dart';
import '../utils/runtime_platform.dart';

/// Shown on Android / Windows home shells to send the app away without quitting.
class LetsMinimizeButton extends StatelessWidget {
  const LetsMinimizeButton({
    super.key,
    this.color,
    this.tooltip = '最小化',
  });

  final Color? color;
  final String tooltip;

  static bool get supported =>
      RuntimePlatform.isAndroid || RuntimePlatform.isWindows;

  @override
  Widget build(BuildContext context) {
    if (!supported) return const SizedBox.shrink();
    final palette = LetsColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: minimizeApp,
      color: color ?? palette.onBar,
      icon: const Icon(Icons.remove, size: 22),
    );
  }
}
