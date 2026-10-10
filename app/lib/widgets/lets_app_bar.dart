import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/lets_colors.dart';
import '../theme/lets_icons.dart';
import 'lets_minimize_button.dart';

class LetsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LetsAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.onLeadingTap,
    this.automaticallyImplyLeading = true,
    this.showMinimize,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onLeadingTap;
  final bool automaticallyImplyLeading;
  /// Defaults to true on Android / Windows.
  final bool? showMinimize;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  bool get _minimizeEnabled =>
      showMinimize ?? LetsMinimizeButton.supported;

  Widget? _trailing(LetsPalette palette) {
    final extras = <Widget>[
      ...?actions,
      if (_minimizeEnabled) LetsMinimizeButton(color: palette.onBar),
    ];
    if (extras.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: extras);
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    final canPop = Navigator.of(context).canPop();
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      if (onLeadingTap != null) {
        leadingWidget = IconButton(
          icon: const Icon(LetsIcons.menu, size: LetsIcons.size),
          color: palette.onBar,
          onPressed: onLeadingTap,
        );
      } else if (canPop) {
        leadingWidget = IconButton(
          icon: const Icon(LetsIcons.back, size: LetsIcons.size),
          color: palette.onBar,
          onPressed: () => Navigator.of(context).pop(),
        );
      }
    }

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Material(
        elevation: 0,
        color: palette.bar,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: NavigationToolbar(
              leading: leadingWidget,
              middle: Text(
                title,
                style: TextStyle(
                  color: palette.onBar,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: _trailing(palette),
              centerMiddle: true,
            ),
          ),
        ),
      ),
    );
  }
}
