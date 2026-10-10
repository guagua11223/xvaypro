import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../extensions/localization.dart';
import '../../theme/lets_colors.dart';
import '../../theme/lets_icons.dart';
import '../../utils/db.dart';
import '../../utils/prefs.dart';
import '../../utils/profile_selection.dart';
import '../../utils/xvay_account.dart';
import '../../utils/show_snack_bar_now.dart';
import '../../utils/vpn_manager.dart';
import 'settings/tun.dart';
import '../../widgets/connect_orb.dart';
import '../../widgets/lets_app_bar.dart';
import 'profiles.dart';
import 'select_line.dart';

class ConnectHome extends StatefulWidget {
  const ConnectHome({
    super.key,
    this.onOpenDrawer,
    this.showMenuButton = true,
  });

  final VoidCallback? onOpenDrawer;
  final bool showMenuButton;

  @override
  State<ConnectHome> createState() => _ConnectHomeState();
}

class _ConnectHomeState extends State<ConnectHome> {
  DateTime? _connectedSince;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _preparing = false;
  String _quota = '';
  List<Map<String, dynamic>> _banners = [];
  bool _promoAsked = false;
  bool _promoLoading = false;

  @override
  void initState() {
    super.initState();
    vPNMan.addListener(_onVpnChanged);
    _syncConnectedClock();
    ensureBackendProfile();
    _loadQuota();
  }

  @override
  void dispose() {
    vPNMan.removeListener(_onVpnChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onVpnChanged() {
    _syncConnectedClock();
    if (mounted) setState(() {});
  }

  void _syncConnectedClock() {
    if (vPNMan.isCoreActive) {
      _connectedSince ??= DateTime.now();
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _connectedSince == null) return;
        setState(() {
          _elapsed = DateTime.now().difference(_connectedSince!);
        });
      });
    } else {
      _connectedSince = null;
      _elapsed = Duration.zero;
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _ensurePromos() {
    if (!XvayAccount().isLoggedIn || _promoAsked || _promoLoading) return;
    _promoLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPromos();
    });
  }

  Future<void> _loadPromos() async {
    final account = XvayAccount();
    if (!account.isLoggedIn || _promoAsked) {
      _promoLoading = false;
      return;
    }
    _promoAsked = true;
    _promoLoading = false;
    try {
      final ads = await account.apiGet('/api/ads');
      final notices = await account.apiGet('/api/announcements');
      if (!mounted) return;
      final allAds = _maps(ads['ads']);
      final allNotices = _maps(notices['announcements']);
      setState(() {
        _banners = allAds.where((item) => item['slot'] == 'home_banner').toList();
      });
      final popup = allAds.where((item) => item['slot'] == 'popup').toList();
      if (popup.isEmpty && allNotices.isEmpty) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          final ad = popup.isEmpty ? null : popup.first;
          final notice = allNotices.isEmpty ? null : allNotices.first;
          return AlertDialog(
            title: Text('${notice?['title'] ?? ad?['title'] ?? '公告'}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notice != null)
                  Text('${notice['body'] ?? ''}', style: const TextStyle(height: 1.4)),
                if (ad != null && '${ad['imageUrl'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openLink('${ad['linkUrl'] ?? ''}'),
                    child: Image.network('${ad['imageUrl']}', height: 120, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
            ],
          );
        },
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadQuota() async {
    final account = XvayAccount();
    if (!account.isLoggedIn) return;
    try {
      final data = await account.apiGet('/api/user/profile');
      final gb = data['trafficRemainGb'];
      final seconds = data['remainSeconds'];
      final days = seconds is num ? (seconds.toInt() / 86400).floor() : 0;
      if (!mounted) return;
      setState(() {
        _quota =
            '剩余 ${gb is num ? gb.toStringAsFixed(2) : '0.00'} GB · 剩余 $days 天';
      });
    } catch (_) {}
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Future<void> _handleToggle() async {
    if (vPNMan.isTogglingAll || _preparing) return;
    if (vPNMan.isCoreActive) {
      await toggleVpnConnection(context);
      if (!vPNMan.isCoreActive) {
        await XvayAccount().disconnect();
      }
      return;
    }
    setState(() => _preparing = true);
    try {
      await ensureBackendProfile();
      final selectedId = prefs.getInt('app.selectedProfileId');
      int? nodeId;
      if (selectedId != null) {
        final selected = await (db.select(
          db.profile,
        )..where((row) => row.id.equals(selectedId))).getSingleOrNull();
        nodeId = nodeIdFromProfileKey(selected?.key);
      }
      await XvayAccount().connect(nodeId: nodeId);
    } catch (error) {
      if (mounted) {
        setState(() => _preparing = false);
        showSnackBarNow(context, Text(_errorText(error)));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _preparing = false);
    await tunHevSocks5TunnelConfInit();
    await toggleVpnConnection(context);
  }

  String _errorText(Object error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) return text.substring(prefix.length);
    return text;
  }

  String _orbLabel(BuildContext context) {
    if (vPNMan.isTogglingAll || _preparing) {
      return context.loc.home_connecting;
    }
    return vPNMan.isCoreActive
        ? context.loc.connect_cta_stop
        : context.loc.connect_cta_start;
  }

  @override
  Widget build(BuildContext context) {
    _ensurePromos();
    final palette = LetsColors.of(context);
    return ColoredBox(
      color: palette.page,
      child: Column(
        children: [
          LetsAppBar(
            title: "讯连宝",
            automaticallyImplyLeading: widget.showMenuButton,
            onLeadingTap: widget.showMenuButton ? widget.onOpenDrawer : null,
          ),
          if (_banners.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: _banners.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ad = _banners[index];
                  final image = '${ad['imageUrl'] ?? ''}';
                  return GestureDetector(
                    onTap: () => _openLink('${ad['linkUrl'] ?? ''}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(LetsColors.radiusInput),
                      child: SizedBox(
                        width: 220,
                        child: image.isEmpty
                            ? ColoredBox(
                                color: palette.surface,
                                child: Center(child: Text('${ad['title'] ?? ''}')),
                              )
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text('${ad['title'] ?? ''}'),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Material(
            color: palette.page,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectLineScreen()),
                );
              },
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                  child: ListenableBuilder(
                    listenable: prefs,
                    builder: (context, _) {
                      final name =
                          prefs.getString("cache.app.selectedProfileName") ??
                          context.loc.region_auto;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.loc.region_label(name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: palette.text,
                              ),
                            ),
                          ),
                          LetsIcon(LetsIcons.chevron, color: palette.muted),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final orbSize = (constraints.maxHeight * 0.46).clamp(
                  168.0,
                  250.0,
                );
                return ListenableBuilder(
                  listenable: Listenable.merge([vPNMan, prefs]),
                  builder: (context, _) {
                    final notice = prefs.getString('xvay.announcement') ?? '';
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (notice.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  8,
                                  28,
                                  12,
                                ),
                                child: Text(
                                  notice,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: palette.muted,
                                  ),
                                ),
                              ),
                            ConnectOrb(
                              isActive: vPNMan.isCoreActive,
                              isToggling: vPNMan.isTogglingAll || _preparing,
                              label: _orbLabel(context),
                              diameter: orbSize,
                              onPressed: vPNMan.isTogglingAll || _preparing
                                  ? null
                                  : _handleToggle,
                            ),
                            if (_quota.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  12,
                                  28,
                                  0,
                                ),
                                child: Text(
                                  _quota,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: LetsColors.textSecondary,
                                  ),
                                ),
                              ),
                            if (vPNMan.isCoreActive) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatElapsed(_elapsed),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Material(
            elevation: 0,
            color: palette.surface,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 85,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListenableBuilder(
                          listenable: Listenable.merge([prefs, vPNMan]),
                          builder: (context, _) {
                            final name =
                                prefs.getString(
                                  "cache.app.selectedProfileName",
                                ) ??
                                context.loc.please_select_a_profile;
                            final status = vPNMan.isCoreActive
                                ? context.loc.home_status_connected
                                : context.loc.home_status_disconnected;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Material(
                      color: LetsColors.accent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileList(),
                            ),
                          );
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LetsIcon(
                                  LetsIcons.profiles,
                                  color: LetsColors.onAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.loc.manage_profiles,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: LetsColors.onAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
