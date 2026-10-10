import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';

String authError(Object error) => '$error'.replaceFirst('Exception: ', '');

InputDecoration authFieldDecoration(LetsPalette palette, String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(LetsColors.radiusInput),
    borderSide: BorderSide(color: palette.line),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: palette.muted),
    filled: true,
    fillColor: palette.page,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: LetsColors.accent, width: 1.5),
    ),
  );
}

class AuthNote extends StatelessWidget {
  const AuthNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LetsColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LetsColors.radiusInput),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, height: 1.4, color: palette.text),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(LetsColors.radiusCard),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: LetsColors.accent,
          foregroundColor: LetsColors.onAccent,
          disabledBackgroundColor: LetsColors.accent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
