import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';

class LetsPlaceholderPage extends StatelessWidget {
  const LetsPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle = '即将开放，敬请期待。',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LetsColors.deskPage,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: LetsColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
