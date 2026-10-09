import 'package:flutter/material.dart';

import 'package:drift/drift.dart' hide Column;

import '../../extensions/localization.dart';
import '../../models/profile_group.dart';
import '../../theme/lets_colors.dart';
import '../../utils/db.dart';
import '../../utils/logger.dart';
import '../../utils/prefs.dart';
import '../../utils/profile_selection.dart';
import '../../utils/show_snack_bar_now.dart';
import '../../utils/vpn_manager.dart';
import '../../widgets/lets_app_bar.dart';
import 'profiles.dart';

class SelectLineScreen extends StatefulWidget {
  const SelectLineScreen({super.key});

  @override
  State<SelectLineScreen> createState() => _SelectLineScreenState();
}

class _SelectLineScreenState extends State<SelectLineScreen> {
  int? _selectedProfileId = prefs.getInt('app.selectedProfileId');
  bool _fullMask = prefs.getBool('tun') ?? false;
  List<ProfileData> _allProfiles = [];
  Map<int, List<ProfileData>> _groupedProfiles = {};
  Map<int, ProfileGroupData> _profileGroups = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles =
        await (db.select(db.profile)..orderBy([
              (u) => OrderingTerm(expression: u.name),
            ]))
            .get();
    final groups =
        await (db.select(db.profileGroup)..orderBy([
              (u) => OrderingTerm(expression: u.name),
            ]))
            .get();

    final grouped = <int, List<ProfileData>>{};
    for (final profile in profiles) {
      grouped.putIfAbsent(profile.profileGroupId, () => []).add(profile);
    }

    if (!mounted) return;
    setState(() {
      _allProfiles = profiles;
      _groupedProfiles = grouped;
      _profileGroups = {for (final g in groups) g.id: g};
      _selectedProfileId = prefs.getInt('app.selectedProfileId');
      _fullMask = prefs.getBool('tun') ?? false;
      _loading = false;
    });
  }

  String _groupTitle(ProfileGroupData group) {
    if (group.id == 1) return context.loc.default_;
    return group.name;
  }

  Future<void> _selectProfile(ProfileData profile) async {
    await selectProfileAndRestartIfNeeded(context: context, profile: profile);
    if (mounted) {
      setState(() {
        _selectedProfileId = profile.id;
      });
    }
  }

  void _handleTunError(Object e) {
    logger.e("tun: $e");
    if (mounted) showSnackBarNow(context, Text("虚拟网卡：$e"));
  }

  Future<void> _setFullMask(bool enable) async {
    setState(() {
      _fullMask = enable;
    });
    await prefs.setBool('tun', enable);
    prefs.notifyListeners();
    if (await vPNMan.getIsCoreActive()) {
      if (enable) {
        await vPNMan.startTun().catchError(_handleTunError);
      } else {
        await vPNMan.stopTun().catchError(_handleTunError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LetsColors.pageBg,
      appBar: LetsAppBar(
        title: context.loc.switch_region,
        actions: [
          IconButton(
            tooltip: context.loc.profiles,
            color: LetsColors.white,
            icon: const Icon(Icons.edit_note),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileList()),
              );
              await _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: LetsColors.white,
            elevation: 2,
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  _ModeLabel(
                    text: context.loc.full_mask,
                    selected: _fullMask,
                    onTap: () => _setFullMask(true),
                  ),
                  Expanded(
                    child: Center(
                      child: Switch(
                        value: !_fullMask,
                        activeColor: LetsColors.accent,
                        onChanged: (smart) => _setFullMask(!smart),
                      ),
                    ),
                  ),
                  _ModeLabel(
                    text: context.loc.full_speed,
                    selected: !_fullMask,
                    onTap: () => _setFullMask(false),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: LetsColors.accent,
                    onRefresh: _load,
                    child: _allProfiles.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Icon(
                                Icons.public_off,
                                size: 48,
                                color: LetsColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.loc.no_profile_yet_create_one_first,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: LetsColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileList(),
                                      ),
                                    );
                                    await _load();
                                  },
                                  child: Text(context.loc.add_profile),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
                            itemCount: _profileGroups.length,
                            itemBuilder: (context, index) {
                              final groupId = _profileGroups.keys.elementAt(
                                index,
                              );
                              final group = _profileGroups[groupId]!;
                              final profiles = _groupedProfiles[groupId] ?? [];
                              if (profiles.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Material(
                                  color: LetsColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          4,
                                        ),
                                        child: Text(
                                          _groupTitle(group),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: LetsColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ...profiles.map((profile) {
                                        final selected =
                                            profile.id == _selectedProfileId;
                                        final latency = profile.httping;
                                        return InkWell(
                                          onTap: () => _selectProfile(profile),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: selected
                                                      ? LetsColors.accent
                                                      : LetsColors.pageBg,
                                                  child: Text(
                                                    profile.name.isEmpty
                                                        ? "?"
                                                        : profile
                                                              .name
                                                              .characters
                                                              .first,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: selected
                                                          ? LetsColors.white
                                                          : LetsColors
                                                                .textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    profile.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: selected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: LetsColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (latency != null)
                                                  Text(
                                                    latency == -1
                                                        ? "timeout"
                                                        : "${latency}ms",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: latency == -1
                                                          ? Colors.red
                                                          : LetsColors.accent,
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  selected
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .radio_button_unchecked,
                                                  color: selected
                                                      ? LetsColors.accent
                                                      : LetsColors.divider,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: selected ? LetsColors.textPrimary : const Color(0xFF20A1FF),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
