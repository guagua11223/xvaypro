import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../extensions/localization.dart';
import '../../theme/lets_colors.dart';
import '../../utils/prefs.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await prefs.setBool('app.guide.completed', true);
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _GuideSlide(
        icon: Icons.bolt,
        title: context.loc.guide_title_1,
        subtitle: context.loc.guide_desc_1,
      ),
      _GuideSlide(
        icon: Icons.shield_outlined,
        title: context.loc.guide_title_2,
        subtitle: context.loc.guide_desc_2,
      ),
      _GuideSlide(
        icon: Icons.public,
        title: context.loc.guide_title_3,
        subtitle: context.loc.guide_desc_3,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LetsColors.splash,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    context.loc.guide_skip,
                    style: const TextStyle(color: LetsColors.onAccent),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => pages[i],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? LetsColors.accent
                          : LetsColors.onAccent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LetsColors.accent,
                      foregroundColor: LetsColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LetsColors.radiusCard),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_index < pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(
                      _index < pages.length - 1
                          ? context.loc.guide_next
                          : context.loc.guide_start,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSlide extends StatelessWidget {
  const _GuideSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: LetsColors.accent),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: LetsColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: LetsColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
