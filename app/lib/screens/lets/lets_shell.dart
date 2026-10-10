import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_minimize_button.dart';
import 'lets_home_page.dart';
import 'lets_invite_page.dart';
import 'lets_messages_page.dart';
import 'lets_nav.dart';
import 'lets_placeholder_page.dart';
import 'lets_profile_page.dart';
import 'lets_region_page.dart';
import 'lets_renew_page.dart';
import 'lets_session.dart';
import 'lets_settings_page.dart';
import 'lets_sidebar.dart';
import 'lets_support_page.dart';

class LetsShell extends StatefulWidget {
  const LetsShell({super.key});

  @override
  State<LetsShell> createState() => _LetsShellState();
}

class _LetsShellState extends State<LetsShell> {
  LetsNav _nav = LetsNav.home;

  @override
  void initState() {
    super.initState();
    LetsSession.instance.refresh();
  }

  void _select(LetsNav nav) {
    setState(() => _nav = nav);
    if (nav == LetsNav.invite ||
        nav == LetsNav.messages ||
        nav == LetsNav.support ||
        nav == LetsNav.renew ||
        nav == LetsNav.profile) {
      if (XvayAccount().isLoggedIn) {
        LetsSession.instance.refresh();
      }
    }
  }

  Widget _page() {
    switch (_nav) {
      case LetsNav.home:
        return LetsHomePage(onOpenRegion: () => _select(LetsNav.region));
      case LetsNav.region:
        return const LetsRegionPage();
      case LetsNav.invite:
        return const LetsInvitePage();
      case LetsNav.free:
        return const LetsPlaceholderPage(title: '免费领会员');
      case LetsNav.freeze:
        return const LetsPlaceholderPage(title: '时长冻结');
      case LetsNav.messages:
        return const LetsMessagesPage();
      case LetsNav.settings:
        return const LetsSettingsPage();
      case LetsNav.support:
        return const LetsSupportPage();
      case LetsNav.renew:
        return const LetsRenewPage();
      case LetsNav.profile:
        return const LetsProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LetsColors.deskPage,
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 248,
                child: LetsSidebar(
                  selected: _nav,
                  onSelect: _select,
                  onRenew: () => _select(LetsNav.renew),
                  onOpenProfile: () => _select(LetsNav.profile),
                ),
              ),
              Container(width: 1, color: const Color(0xFFD8DDE5)),
              Expanded(child: _page()),
            ],
          ),
          const Positioned(
            top: 2,
            right: 4,
            child: LetsMinimizeButton(color: LetsColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
