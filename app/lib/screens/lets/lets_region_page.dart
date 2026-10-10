import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';
import '../../utils/db.dart';
import '../../utils/logger.dart';
import '../../utils/prefs.dart';
import '../../utils/profile_selection.dart';
import '../../utils/show_snack_bar_now.dart';
import '../../utils/vpn_manager.dart';

class LetsRegionPage extends StatefulWidget {
  const LetsRegionPage({super.key});

  @override
  State<LetsRegionPage> createState() => _LetsRegionPageState();
}

class _LetsRegionPageState extends State<LetsRegionPage> {
  bool _loading = true;
  bool _fullMask = prefs.getBool('tun') ?? false;
  bool _autoFastest = true;
  int? _selectedProfileId = prefs.getInt('app.selectedProfileId');
  List<ProfileData> _profiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await (db.select(db.profile)
          ..orderBy([(u) => OrderingTerm(expression: u.name)]))
        .get();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _selectedProfileId = prefs.getInt('app.selectedProfileId');
      _fullMask = prefs.getBool('tun') ?? false;
      _loading = false;
    });
  }

  Future<void> _setMode(bool secure) async {
    setState(() => _fullMask = secure);
    await prefs.setBool('tun', secure);
    await prefs.setBool('systemProxy', !secure);
    prefs.notifyListeners();
    if (await vPNMan.getIsCoreActive()) {
      try {
        if (secure) {
          await vPNMan.stopSystemProxy();
          await vPNMan.startTun();
        } else {
          await vPNMan.stopTun();
          await vPNMan.startSystemProxy();
        }
      } catch (e) {
        logger.e('mode: $e');
        if (mounted) showSnackBarNow(context, Text('$e'));
      }
    }
  }

  Future<void> _select(ProfileData profile) async {
    setState(() {
      _autoFastest = false;
      _selectedProfileId = profile.id;
    });
    await selectProfileAndRestartIfNeeded(context: context, profile: profile);
  }

  Map<String, List<ProfileData>> _byRegion() {
    final map = <String, List<ProfileData>>{};
    for (final p in _profiles) {
      final name = p.name;
      String region = '其他';
      if (name.contains('香港') ||
          name.contains('台湾') ||
          name.contains('日本') ||
          name.contains('韩国') ||
          name.contains('新加坡') ||
          name.contains('印尼') ||
          name.contains('印度') ||
          name.contains('马来') ||
          name.contains('菲律宾') ||
          name.contains('泰国') ||
          name.contains('越南') ||
          name.contains('亚洲')) {
        region = '亚洲';
      } else if (name.contains('瑞士') ||
          name.contains('德国') ||
          name.contains('爱尔兰') ||
          name.contains('瑞典') ||
          name.contains('欧洲') ||
          name.contains('英国') ||
          name.contains('法国')) {
        region = '欧洲';
      } else if (name.contains('澳洲') ||
          name.contains('澳大利亚') ||
          name.contains('新西兰') ||
          name.contains('大洋')) {
        region = '大洋洲';
      } else if (name.contains('美国') ||
          name.contains('加拿大') ||
          name.contains('北美')) {
        region = '北美';
      }
      map.putIfAbsent(region, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: LetsColors.deskPage,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final regions = _byRegion();
    return ColoredBox(
      color: LetsColors.deskPage,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: [
          const Text(
            '选择模式',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            selected: !_fullMask,
            title: '极速模式',
            subtitle: '智能分流，仅代理需要翻墙的网络流量，不影响本地资源访问。',
            onTap: () => _setMode(false),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            selected: _fullMask,
            title: '安全模式',
            subtitle: '代理全部网络流量，改变 IP 地址，安全性极强。',
            onTap: () => _setMode(true),
          ),
          const SizedBox(height: 28),
          const Text(
            '选择网络',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _RadioRow(
            selected: _autoFastest,
            label: '自动匹配最快网络',
            leading: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: LetsColors.deskPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.bolt, size: 14, color: LetsColors.deskPink),
            ),
            onTap: () => setState(() => _autoFastest = true),
          ),
          const SizedBox(height: 16),
          for (final entry in regions.entries) ...[
            Text(
              entry.key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LetsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final profile in entry.value)
                  SizedBox(
                    width: 180,
                    child: _RadioRow(
                      selected:
                          !_autoFastest && _selectedProfileId == profile.id,
                      label: profile.name,
                      onTap: () => _select(profile),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? LetsColors.textPrimary : LetsColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (selected)
            Container(
              margin: const EdgeInsets.only(left: 28, top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFC5CAD3),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: LetsColors.textSecondary,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: LetsColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.selected,
    required this.label,
    required this.onTap,
    this.leading,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
            ),
            const SizedBox(width: 8),
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
