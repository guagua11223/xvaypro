import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../extensions/localization.dart';
import '../screens/home/account.dart';
import '../screens/home/dashboard.dart';
import '../screens/home/logs.dart';
import '../screens/home/profiles.dart';
import '../screens/home/select_line.dart';
import '../screens/home/settings.dart';
import '../screens/home/settings/about.dart';
import '../theme/lets_colors.dart';
import '../theme/lets_icons.dart';
import '../utils/prefs.dart';
import '../utils/vpn_manager.dart';

class HomeDrawerPanel extends StatefulWidget {
  const HomeDrawerPanel({
    super.key,
    required this.onNavigate,
    this.showBackButton = true,
  });

  final void Function(Widget page) onNavigate;
  final bool showBackButton;

  @override
  State<HomeDrawerPanel> createState() => _HomeDrawerPanelState();
}

class _HomeDrawerPanelState extends State<HomeDrawerPanel> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = "v${info.version}+${info.buildNumber}";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return ColoredBox(
      color: palette.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const LetsIcon(LetsIcons.back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
              child: ListenableBuilder(
                listenable: Listenable.merge([prefs, vPNMan]),
                builder: (context, _) {
                  final name =
                      prefs.getString("cache.app.selectedProfileName") ??
                      context.loc.please_select_a_profile;
                  final status = vPNMan.isCoreActive
                      ? context.loc.home_status_connected
                      : context.loc.home_status_disconnected;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: LetsColors.accent.withValues(alpha: 0.12),
                        child: const LetsIcon(
                          LetsIcons.account,
                          size: 28,
                          color: LetsColors.accent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "讯连宝",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const LetsIcon(LetsIcons.chevron),
                        onPressed: () => widget.onNavigate(const SettingList()),
                      ),
                    ],
                  );
                },
              ),
            ),
            Divider(height: 1, color: palette.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: LetsIcons.account,
                    label: '讯连宝账户',
                    onTap: () => widget.onNavigate(const AccountScreen()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.region,
                    label: context.loc.switch_region,
                    onTap: () => widget.onNavigate(const SelectLineScreen()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.profiles,
                    label: context.loc.profiles,
                    onTap: () => widget.onNavigate(const ProfileList()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.dashboard,
                    label: context.loc.dashboard,
                    onTap: () => widget.onNavigate(const Dashboard()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.logs,
                    label: context.loc.logs,
                    onTap: () => widget.onNavigate(const LogViewer()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.settings,
                    label: context.loc.settings,
                    onTap: () => widget.onNavigate(const SettingList()),
                  ),
                  _DrawerItem(
                    icon: LetsIcons.about,
                    label: context.loc.about,
                    onTap: () => widget.onNavigate(const AboutScreen()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LetsColors.accent,
                    foregroundColor: LetsColors.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LetsColors.radiusCard),
                    ),
                  ),
                  onPressed: () => widget.onNavigate(const ProfileList()),
                  child: Text(context.loc.manage_profiles),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _version,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = LetsColors.of(context).text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 16, 10),
        child: Row(
          children: [
            LetsIcon(icon, color: color),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
