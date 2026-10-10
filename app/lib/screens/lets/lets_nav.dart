import 'package:flutter/material.dart';

enum LetsNav {
  home,
  region,
  invite,
  free,
  freeze,
  messages,
  settings,
  support,
  renew,
  profile,
}

extension LetsNavX on LetsNav {
  String get label {
    switch (this) {
      case LetsNav.home:
        return '首页';
      case LetsNav.region:
        return '变更国家和地区';
      case LetsNav.invite:
        return '推荐有奖';
      case LetsNav.free:
        return '免费领会员';
      case LetsNav.freeze:
        return '时长冻结';
      case LetsNav.messages:
        return '消息中心';
      case LetsNav.settings:
        return '软件设置';
      case LetsNav.support:
        return '在线客服';
      case LetsNav.renew:
        return '续费会员';
      case LetsNav.profile:
        return '个人中心';
    }
  }

  IconData get icon {
    switch (this) {
      case LetsNav.home:
        return Icons.home_outlined;
      case LetsNav.region:
        return Icons.public_outlined;
      case LetsNav.invite:
        return Icons.card_giftcard_outlined;
      case LetsNav.free:
        return Icons.confirmation_number_outlined;
      case LetsNav.freeze:
        return Icons.lock_outline;
      case LetsNav.messages:
        return Icons.notifications_none_outlined;
      case LetsNav.settings:
        return Icons.settings_outlined;
      case LetsNav.support:
        return Icons.headset_mic_outlined;
      case LetsNav.renew:
        return Icons.shopping_cart_outlined;
      case LetsNav.profile:
        return Icons.person_outline;
    }
  }

  static const menuItems = <LetsNav>[
    LetsNav.home,
    LetsNav.region,
    LetsNav.invite,
    LetsNav.free,
    LetsNav.freeze,
    LetsNav.messages,
    LetsNav.settings,
    LetsNav.support,
  ];
}
