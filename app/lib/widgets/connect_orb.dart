import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lets_colors.dart';

class ConnectOrb extends StatefulWidget {
  const ConnectOrb({
    super.key,
    required this.isActive,
    required this.isToggling,
    required this.label,
    required this.onPressed,
  });

  final bool isActive;
  final bool isToggling;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<ConnectOrb> createState() => _ConnectOrbState();
}

class _ConnectOrbState extends State<ConnectOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ConnectOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isToggling != widget.isToggling) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isActive || widget.isToggling) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isActive
        ? LetsColors.orbCyan
        : LetsColors.orbPinkDeep;
    final fill = widget.isActive ? LetsColors.accent : LetsColors.orbPink;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: SizedBox(
          width: 250,
          height: 250,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _OrbPainter(
                  progress: _controller.value,
                  accent: accent,
                  fill: fill,
                  active: widget.isActive,
                  toggling: widget.isToggling,
                ),
                child: child,
              );
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isToggling
                        ? Icons.sync
                        : widget.isActive
                        ? Icons.power_settings_new
                        : Icons.power_settings_new,
                    size: 36,
                    color: accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.accent,
    required this.fill,
    required this.active,
    required this.toggling,
  });

  final double progress;
  final Color accent;
  final Color fill;
  final bool active;
  final bool toggling;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide / 2;

    for (var i = 0; i < 3; i++) {
      final wave = ((progress + i / 3) % 1.0);
      final radius = base * (0.62 + wave * 0.32);
      final opacity = (1 - wave) * (active || toggling ? 0.28 : 0.12);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = accent.withValues(alpha: opacity),
      );
    }

    canvas.drawCircle(
      center,
      base * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LetsColors.white,
            fill.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: base * 0.58)),
    );

    canvas.drawCircle(
      center,
      base * 0.58,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent.withValues(alpha: 0.55),
    );

    if (toggling) {
      final sweep = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          accent.withValues(alpha: 0),
          accent,
          accent.withValues(alpha: 0),
        ],
        transform: GradientRotation(progress * math.pi * 2),
      );
      canvas.drawCircle(
        center,
        base * 0.58,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..shader = sweep.createShader(
            Rect.fromCircle(center: center, radius: base * 0.58),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.active != active ||
        oldDelegate.toggling != toggling;
  }
}
