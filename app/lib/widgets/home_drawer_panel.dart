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
    return ColoredBox(
      color: LetsColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
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
                        backgroundColor: LetsColors.orbPink,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: LetsColors.orbPinkDeep,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AnyPortal",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: LetsColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: LetsColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 12,
                                color: LetsColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => widget.onNavigate(const SettingList()),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, color: LetsColors.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.account_circle_outlined,
                    label: '飞连 账户',
                    onTap: () => widget.onNavigate(const AccountScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.public,
                    label: context.loc.switch_region,
                    onTap: () => widget.onNavigate(const SelectLineScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: context.loc.profiles,
                    onTap: () => widget.onNavigate(const ProfileList()),
                  ),
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: context.loc.dashboard,
                    onTap: () => widget.onNavigate(const Dashboard()),
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline,
                    label: context.loc.logs,
                    onTap: () => widget.onNavigate(const LogViewer()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: context.loc.settings,
                    onTap: () => widget.onNavigate(const SettingList()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
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
                    foregroundColor: LetsColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: LetsColors.textSecondary,
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
    const color = Color(0xFF333333);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 16, 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
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
