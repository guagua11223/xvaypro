import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../home/login.dart';
import '../home/register.dart';
import 'lets_nav.dart';
import 'lets_session.dart';

class LetsSidebar extends StatefulWidget {
  const LetsSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onRenew,
  });

  final LetsNav selected;
  final ValueChanged<LetsNav> onSelect;
  final VoidCallback onRenew;

  @override
  State<LetsSidebar> createState() => _LetsSidebarState();
}

class _LetsSidebarState extends State<LetsSidebar> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _openAuth({required bool register}) async {
    final page = register ? const RegisterScreen() : const LoginScreen();
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => page),
    );
    if (ok == true) await LetsSession.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LetsSession.instance,
      builder: (context, _) {
        final session = LetsSession.instance;
        return ColoredBox(
          color: LetsColors.deskSidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(session: session, onTapAccount: () {
                if (!session.loggedIn) _openAuth(register: false);
              }),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in LetsNavX.menuItems)
                      _NavTile(
                        item: item,
                        selected: widget.selected == item,
                        badge: item == LetsNav.messages
                            ? session.unreadMessages
                            : 0,
                        onTap: () => widget.onSelect(item),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LetsColors.deskBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: widget.onRenew,
                    child: const Text('续费会员', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Text(
                      '版本号：${_version.isEmpty ? '—' : _version}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: LetsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => LetsSession.instance.refresh(),
                      child: const Icon(
                        Icons.refresh,
                        size: 14,
                        color: LetsColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (!session.loggedIn)
                      TextButton(
                        onPressed: () => _openAuth(register: true),
                        style: TextButton.styleFrom(
                          foregroundColor: LetsColors.deskBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('注册', style: TextStyle(fontSize: 12)),
                      ),
                    if (session.loggedIn)
                      TextButton(
                        onPressed: () async {
                          await XvayAccount().logout();
                          await LetsSession.instance.refresh();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: LetsColors.textSecondary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('退出', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.onTapAccount});

  final LetsSession session;
  final VoidCallback onTapAccount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapAccount,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.userId.isEmpty
                        ? '飞连'
                        : '飞连 (ID: ${session.userId})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LetsColors.textPrimary,
                    ),
                  ),
                ),
                if (session.userId.isNotEmpty)
                  IconButton(
                    tooltip: '复制 ID',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: session.userId));
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.person, color: Colors.grey.shade600, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          session.expired ? '已过期' : '有效',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '到期时间: ${session.expireText}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: LetsColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final LetsNav item;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LetsColors.deskBlue : LetsColors.textPrimary;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 44,
                color: selected ? LetsColors.deskBlue : Colors.transparent,
              ),
              const SizedBox(width: 17),
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
