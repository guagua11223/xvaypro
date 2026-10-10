import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lets_colors.dart';
import 'lets_session.dart';

class LetsSupportPage extends StatelessWidget {
  const LetsSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LetsSession.instance,
      builder: (context, _) {
        final services = LetsSession.instance.services;
        return ColoredBox(
          color: LetsColors.deskPage,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              const Text(
                '在线客服',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '7×24 在线客服随时为您服务。支付或连接遇到问题可联系以下渠道。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: LetsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (services.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3E6EC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.headset_mic_outlined, color: LetsColors.deskBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '暂未配置客服渠道，请稍后再试或联系管理员。',
                          style: TextStyle(color: LetsColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final item in services)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final text = '${item['account'] ?? ''}';
                          if (text.isEmpty) return;
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已复制 ${item['channel']}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE3E6EC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.support_agent,
                                color: LetsColors.deskBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['channel'] ?? '客服'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['account'] ?? ''}',
                                      style: const TextStyle(
                                        color: LetsColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.copy_outlined, size: 18),
                            ],
                          ),
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
