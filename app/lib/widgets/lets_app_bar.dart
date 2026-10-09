import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/lets_colors.dart';
import '../theme/lets_icons.dart';

class LetsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LetsAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.onLeadingTap,
    this.automaticallyImplyLeading = true,
  });


  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onLeadingTap;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

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
              trailing: actions == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
              centerMiddle: true,
            ),
          ),
        ),
      ),
    );
  }
}
