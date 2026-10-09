import 'package:flutter/material.dart';

import 'lets_colors.dart';

/// Outlined Material icons, one size. Filled glyphs are not used for navigation.
class LetsIcons {
  static const size = 22.0;

  static const menu = Icons.menu;
  static const back = Icons.arrow_back;
  static const chevron = Icons.chevron_right;
  static const more = Icons.more_horiz;

  static const account = Icons.account_circle_outlined;
  static const region = Icons.public_outlined;
  static const profiles = Icons.description_outlined;
  static const dashboard = Icons.dashboard_outlined;
  static const logs = Icons.article_outlined;
  static const settings = Icons.settings_outlined;
  static const about = Icons.info_outline;
  static const edit = Icons.edit_outlined;

  static const general = Icons.tune_outlined;
  static const proxy = Icons.swap_horiz_outlined;
  static const systemProxy = Icons.language_outlined;
  static const tun = Icons.vpn_lock_outlined;
  static const cores = Icons.memory_outlined;
  static const assets = Icons.inventory_2_outlined;
  static const override = Icons.build_outlined;

  static const power = Icons.power_settings_new_outlined;
  static const sync = Icons.sync;
  static const bolt = Icons.flash_on_outlined;
  static const shield = Icons.shield_outlined;
}

class LetsIcon extends StatelessWidget {
  const LetsIcon(this.icon, {super.key, this.color, this.size = LetsIcons.size});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? LetsColors.of(context).text,
    );
  }
}
