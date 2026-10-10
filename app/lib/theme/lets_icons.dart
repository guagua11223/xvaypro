import 'package:flutter/material.dart';

import 'lets_colors.dart';

/// One outlined icon family, one size.
class LetsIcons {
  static const size = 22.0;

  static const menu = Icons.menu;
  static const back = Icons.arrow_back;
  static const chevron = Icons.chevron_right;
  static const more = Icons.more_horiz_outlined;

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
  static const sync = Icons.sync_outlined;
  static const bolt = Icons.flash_on_outlined;
  static const shield = Icons.shield_outlined;

  static const add = Icons.add;
  static const close = Icons.close;
  static const search = Icons.search;
  static const check = Icons.check;
  static const refresh = Icons.refresh;
  static const copy = Icons.copy_outlined;
  static const folder = Icons.folder_open_outlined;
  static const selected = Icons.check_circle_outline;
  static const unselected = Icons.radio_button_unchecked;
  static const play = Icons.play_arrow_outlined;
  static const stop = Icons.stop_outlined;
  static const warning = Icons.priority_high;
  static const open = Icons.open_in_new;
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

class LetsMark extends StatelessWidget {
  const LetsMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
