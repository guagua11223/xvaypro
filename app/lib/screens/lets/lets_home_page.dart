import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';
import '../../utils/prefs.dart';
import '../../utils/show_snack_bar_now.dart';
import '../../utils/vpn_manager.dart';
import 'lets_session.dart';

class LetsHomePage extends StatefulWidget {
  const LetsHomePage({super.key, this.onOpenRegion});

  final VoidCallback? onOpenRegion;

  @override
  State<LetsHomePage> createState() => _LetsHomePageState();
}

class _LetsHomePageState extends State<LetsHomePage> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (vPNMan.isCoreActive) {
        await vPNMan.stopAll();
      } else {
        await vPNMan.startAll();
      }
    } catch (e) {
      if (mounted) showSnackBarNow(context, Text('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LetsSession.instance, vPNMan, prefs]),
      builder: (context, _) {
        final session = LetsSession.instance;
        final connected = vPNMan.isCoreActive;
        final line =
            prefs.getString('cache.app.selectedProfileName') ?? '自动';
        final minutes = session.remainMinutes;
        final digits = minutes
            .clamp(0, 9999)
            .toString()
            .padLeft(4, '0')
            .split('');

        return ColoredBox(
          color: LetsColors.deskPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 36,
                color: LetsColors.deskBanner,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: LetsColors.deskBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.announcementBanner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: LetsColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Text(
                      session.expired
                          ? '会员已过期，剩余时长(分钟)'
                          : '剩余时长(分钟)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: LetsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.shopping_cart_outlined, size: 16),
                    const Spacer(),
                    for (final d in digits)
                      Container(
                        width: 28,
                        height: 32,
                        margin: const EdgeInsets.only(left: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFD8DDE5)),
                        ),
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                connected
                                    ? Icons.link
                                    : Icons.link_off,
                                size: 40,
                                color: LetsColors.deskPink,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connected ? 'VPN 已连接' : 'VPN 已断开连接',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: widget.onOpenRegion,
                                  child: Text(
                                    '网络：$line',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: LetsColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 280,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: LetsColors.deskPink,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  LetsColors.deskPink.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: _busy ? null : _toggle,
                            child: Text(
                              _busy
                                  ? '处理中…'
                                  : (connected ? '断开连接' : '开启快连'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
      },
    );
  }
}
