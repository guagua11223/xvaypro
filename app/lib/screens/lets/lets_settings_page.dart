import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/lets_colors.dart';
import '../../utils/locale_manager.dart';
import '../../utils/platform_launch_at_login.dart';
import '../../utils/prefs.dart';

class LetsSettingsPage extends StatefulWidget {
  const LetsSettingsPage({super.key});

  @override
  State<LetsSettingsPage> createState() => _LetsSettingsPageState();
}

class _LetsSettingsPageState extends State<LetsSettingsPage> {
  bool _launchAtLogin = false;
  String _version = '';
  String _locale = 'system';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final enabled = await platformLaunchAtLogin.isEnabled();
    final follow = prefs.getBool('app.locale.followSystem') ?? true;
    final code = prefs.getString('app.locale') ?? 'zh_CN';
    if (!mounted) return;
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
      _launchAtLogin = enabled;
      _locale = follow ? 'system' : (code.startsWith('zh') ? 'zh_CN' : 'en');
    });
  }

  Future<void> _setLaunch(bool value) async {
    setState(() => _launchAtLogin = value);
    if (value) {
      await platformLaunchAtLogin.enable();
    } else {
      await platformLaunchAtLogin.disable();
    }
  }

  Future<void> _setLocale(String? value) async {
    if (value == null) return;
    setState(() => _locale = value);
    if (value == 'system') {
      await prefs.setBool('app.locale.followSystem', true);
    } else {
      await prefs.setBool('app.locale.followSystem', false);
      await prefs.setString('app.locale', value);
    }
    LocaleManager().update(notify: true);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LetsColors.deskPage,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: [
          const Text(
            '软件设置',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _Section(
            icon: Icons.power_settings_new,
            title: '开机启动',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Switch(
                  value: _launchAtLogin,
                  activeThumbColor: Colors.white,
                  activeTrackColor: LetsColors.deskBlue,
                  onChanged: _setLaunch,
                ),
                const Text(
                  '开启后，登录 Windows 时自动启动飞连。',
                  style: TextStyle(fontSize: 13, color: LetsColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 36),
          _Section(
            icon: Icons.language,
            title: '显示语言',
            child: DropdownButtonFormField<String>(
              initialValue: _locale,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                DropdownMenuItem(value: 'zh_CN', child: Text('简体中文')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: _setLocale,
            ),
          ),
          const Divider(height: 36),
          _Section(
            icon: Icons.info_outline,
            title: '关于我们',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('版本号：$_version'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('当前已是最新版本')),
                    );
                  },
                  child: const Text(
                    '检查更新',
                    style: TextStyle(color: LetsColors.deskBlue),
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/anyportal/anyportal'),
                  ),
                  child: const Text(
                    '开源主页',
                    style: TextStyle(color: LetsColors.deskBlue),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '飞连 · AnyPortal 客户端',
                  style: TextStyle(fontSize: 12, color: LetsColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: LetsColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
