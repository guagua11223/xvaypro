import 'dart:async';

import 'package:flutter/material.dart';

import '../../extensions/localization.dart';
import '../../theme/lets_colors.dart';
import '../../utils/db.dart';
import '../../utils/prefs.dart';
import '../../utils/profile_selection.dart';
import '../../utils/xvay_account.dart';
import '../../utils/show_snack_bar_now.dart';
import '../../utils/vpn_manager.dart';
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

  @override
  void initState() {
    super.initState();
    vPNMan.addListener(_onVpnChanged);
    _syncConnectedClock();
    ensureBackendProfile();
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
    return ColoredBox(
      color: LetsColors.pageBg,
      child: Column(
        children: [
          LetsAppBar(
            title: "AnyPortal",
            automaticallyImplyLeading: widget.showMenuButton,
            onLeadingTap: widget.showMenuButton ? widget.onOpenDrawer : null,
          ),
          Material(
            color: LetsColors.pageBg,
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
                              style: const TextStyle(
                                fontSize: 14,
                                color: LetsColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: LetsColors.textSecondary,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ListenableBuilder(
                listenable: vPNMan,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConnectOrb(
                        isActive: vPNMan.isCoreActive,
                        isToggling: vPNMan.isTogglingAll || _preparing,
                        label: _orbLabel(context),
                        onPressed: vPNMan.isTogglingAll || _preparing
                            ? null
                            : _handleToggle,
                      ),
                      if (vPNMan.isCoreActive) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatElapsed(_elapsed),
                          style: const TextStyle(
                            fontSize: 16,
                            color: LetsColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          Material(
            elevation: 10,
            color: LetsColors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 85,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: LetsColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: LetsColors.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.list_alt,
                                  color: LetsColors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.loc.manage_profiles,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: LetsColors.white,
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
