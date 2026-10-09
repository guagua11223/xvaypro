import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/lets_colors.dart';

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
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      if (onLeadingTap != null) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.menu),
          color: LetsColors.white,
          onPressed: onLeadingTap,
        );
      } else if (canPop) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back),
          color: LetsColors.white,
          onPressed: () => Navigator.of(context).pop(),
        );
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        elevation: 0,
        child: Container(
          decoration: const BoxDecoration(gradient: LetsColors.toolbarGradient),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: NavigationToolbar(
                leading: leadingWidget,
                middle: Text(
                  title,
                  style: const TextStyle(
                    color: LetsColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
