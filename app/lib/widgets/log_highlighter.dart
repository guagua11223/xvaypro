import 'package:flutter/material.dart';

import '../theme/lets_colors.dart';

class LogHighlighter extends StatelessWidget {
  final String logLine;

  const LogHighlighter({super.key, required this.logLine});

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _highlightLog(logLine),
      ),
    );
  }

  List<TextSpan> _highlightLog(String text) {
    final patterns = <RegExp, TextStyle>{
      // Date: 2025/07/04 or 2025-07-04
      RegExp(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b'): TextStyle(
        color: LetsColors.accent,
      ),
      // Time: 15:56:20 or 15:56:47.240788
      RegExp(r'\b\d{2}:\d{2}:\d{2}(?:\.\d+)?\b'): TextStyle(
        color: LetsColors.accent,
      ),

      // Address: domain:port
      RegExp(r'([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}):(\d{1,5})'): TextStyle(
        color: LetsColors.seriesDirect,
      ),
      // Address: ipv4:port
      RegExp(r'((?:\d{1,3}\.){3}\d{1,3}):(\d{1,5})'): TextStyle(
        color: LetsColors.seriesDirect,
      ),
      // Address: domain:port
      RegExp(r'\[([0-9a-fA-F:]+)\]:(\d{1,5})'): TextStyle(
        color: LetsColors.seriesDirect,
      ),
      RegExp(r'(tcp:|udp:)', caseSensitive: false): TextStyle(
        color: LetsColors.seriesDirect,
      ),

      // Log level: ERROR, Warning, debug, info, etc.
      RegExp(
        r'\b(error|warning|info|debug)\b',
        caseSensitive: false,
      ): TextStyle(
        color: LetsColors.danger,
        fontWeight: FontWeight.bold,
      ),
      // Arrow symbol ->
      RegExp(r'->'): const TextStyle(
        color: LetsColors.accent,
        fontWeight: FontWeight.bold,
      ),

      // Square brackets quoted contents
      RegExp(r'\[.*?\]'): const TextStyle(color: LetsColors.textSecondary),
      // High frequency keywords
      RegExp(r'\b(from|accepted|failed)\b', caseSensitive: false): TextStyle(
        color: LetsColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    };

    final matches = <_Match>[];

    patterns.forEach((regex, style) {
      for (final match in regex.allMatches(text)) {
        matches.add(_Match(match.start, match.end, style));
      }
    });

    // Sort by start, then by longest first
    matches.sort((a, b) {
      if (a.start != b.start) return a.start.compareTo(b.start);
      return b.length.compareTo(a.length); // longer match first
    });

    // Keep only non-overlapping matches
    final nonOverlapping = <_Match>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        nonOverlapping.add(m);
        lastEnd = m.end;
      }
    }

    // Build TextSpans
    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final m in nonOverlapping) {
      if (m.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, m.start),
            // style: TextStyle(color: Colors.black),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: m.style,
        ),
      );
      currentIndex = m.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          // style: TextStyle(color: Colors.black),
        ),
      );
    }

    return spans;
  }
}

class _Match {
  final int start;
  final int end;
  final TextStyle style;

  _Match(this.start, this.end, this.style);

  int get length => end - start;
}
