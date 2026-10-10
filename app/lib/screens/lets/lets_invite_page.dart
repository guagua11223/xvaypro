import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lets_colors.dart';
import 'lets_session.dart';

class LetsInvitePage extends StatelessWidget {
  const LetsInvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LetsSession.instance,
      builder: (context, _) {
        final session = LetsSession.instance;
        final code = '${session.invite['inviteCode'] ?? ''}';
        final url = '${session.invite['inviteUrl'] ?? ''}';
        final invitees = (session.invite['invitees'] is List)
            ? (session.invite['invitees'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];
        final count = invitees.length;

        return ColoredBox(
          color: LetsColors.deskPage,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              const Text(
                '推荐有奖',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: LetsColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: '分享你的推荐码 '),
                    TextSpan(
                      text: code.isEmpty ? '—' : code,
                      style: const TextStyle(
                        color: LetsColors.deskBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，好友注册并付费后你可获得推荐奖励。'),
                    if ('${session.invite['mode'] ?? ''}'.isNotEmpty)
                      TextSpan(
                        text: ' ${session.invite['mode']}',
                        style: const TextStyle(color: LetsColors.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 200,
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LetsColors.deskBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      final text = url.isNotEmpty ? url : code;
                      if (text.isEmpty) return;
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制推荐信息')),
                      );
                    },
                    child: const Text('推荐给好友'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        _StatCard(label: '成功推荐', value: '$count人'),
                        const SizedBox(height: 12),
                        const _StatCard(label: '累计获得', value: '—'),
                        const SizedBox(height: 12),
                        const _StatCard(label: '累计奖励', value: '—'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 280),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE3E6EC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '我的奖励（只显示最近10条）',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (invitees.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 48,
                                      color: Color(0xFFC5CAD3),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '还没有奖励记录',
                                      style: TextStyle(
                                        color: LetsColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            for (final item in invitees.take(10))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '${item['username'] ?? ''} · ID ${item['id'] ?? ''}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: LetsColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: LetsColors.deskBlue,
            ),
          ),
        ],
      ),
    );
  }
}
