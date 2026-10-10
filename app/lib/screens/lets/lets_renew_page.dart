import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../home/account.dart' show commerceOrderPending, payLink;
import 'lets_session.dart';

class LetsRenewPage extends StatefulWidget {
  const LetsRenewPage({super.key});

  @override
  State<LetsRenewPage> createState() => _LetsRenewPageState();
}

class _LetsRenewPageState extends State<LetsRenewPage> {
  final _account = XvayAccount();
  int? _selectedId;
  String _payChannel = 'gateway';
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final packages = LetsSession.instance.packages;
      if (packages.isNotEmpty && _selectedId == null) {
        setState(() => _selectedId = packages.first['id'] is num
            ? (packages.first['id'] as num).toInt()
            : null);
      }
    });
  }

  Map<String, dynamic>? get _selected {
    for (final item in LetsSession.instance.packages) {
      final id = item['id'];
      if (id is num && id.toInt() == _selectedId) return item;
    }
    return null;
  }

  bool get _hasUnpaid =>
      LetsSession.instance.orders.any(commerceOrderPending);

  List<Map<String, dynamic>> get _pendingOrders =>
      LetsSession.instance.orders.where(commerceOrderPending).toList();

  Future<void> _payExisting(Map<String, dynamic> order) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final pay = await _account.apiPost('/api/pay/create', {
        'orderId': order['id'],
      });
      final url = payLink(pay);
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => _message = '已打开 EPAY 支付页面');
      } else {
        setState(
          () => _message =
              '订单 ${order['orderNo']} 待支付 ¥${order['amount']}，支付网关未返回链接',
        );
      }
      await LetsSession.instance.refresh();
    } catch (e) {
      setState(() => _message = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteOrder(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订单'),
        content: Text('删除待支付订单 ${order['orderNo']}？删除后可以重新购买。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _account.apiPost('/api/orders/cancel', {'orderId': order['id']});
      setState(() => _message = '已删除待支付订单');
      await LetsSession.instance.refresh();
    } catch (e) {
      setState(() => _message = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final pack = _selected;
    if (pack == null) {
      setState(() => _message = '请选择套餐');
      return;
    }
    if (_hasUnpaid) {
      setState(() => _message = '有待支付订单，请先在右侧完成支付或删除后再购买');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final created = await _account.apiPost('/api/orders', {
        'packageId': pack['id'],
      });
      final order = created['order'];
      if (order is! Map) throw Exception('下单失败');
      if (_payChannel == 'manual') {
        setState(
          () => _message =
              '订单 ${order['orderNo']} 已创建 ¥${order['amount']}，请联系客服人工确认',
        );
      } else {
        final pay = await _account.apiPost('/api/pay/create', {
          'orderId': order['id'],
        });
        final url = payLink(pay);
        if (url != null) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          setState(() => _message = '已打开 EPAY 支付页面');
        } else {
          setState(
            () => _message =
                '订单 ${order['orderNo']} 已创建 ¥${order['amount']}，等待支付到账',
          );
        }
      }
      await LetsSession.instance.refresh();
    } catch (e) {
      setState(() => _message = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LetsSession.instance,
      builder: (context, _) {
        final packages = LetsSession.instance.packages;
        final selected = _selected;
        return ColoredBox(
          color: LetsColors.deskPage,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 16, 32),
                  children: [
                    const Text(
                      '选择会员',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (packages.isEmpty)
                      const Text('暂无套餐，请稍后刷新或联系管理员。')
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final item in packages)
                            _PackageCard(
                              item: item,
                              selected: item['id'] is num &&
                                  (item['id'] as num).toInt() == _selectedId,
                              onTap: () => setState(
                                () => _selectedId =
                                    (item['id'] as num).toInt(),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 28),
                    const Text(
                      '选择付款方式',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PayOption(
                      selected: _payChannel == 'gateway',
                      title: '在线支付',
                      subtitle: '跳转 EPAY 收银台完成付款',
                      onTap: () => setState(() => _payChannel = 'gateway'),
                    ),
                    const SizedBox(height: 10),
                    _PayOption(
                      selected: _payChannel == 'manual',
                      title: '人工确认',
                      subtitle: '创建订单后由后台确认到账',
                      onTap: () => setState(() => _payChannel = 'manual'),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message!,
                        style: const TextStyle(color: LetsColors.deskPink),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: LetsColors.deskBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _busy || _hasUnpaid ? null : _pay,
                        child: Text(
                          _busy
                              ? '提交中…'
                              : _hasUnpaid
                                  ? '请先处理待支付订单'
                                  : '确认支付',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '订单信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selected == null
                            ? '未选择套餐'
                            : '${selected['name']} · ${selected['durationDays']} 天',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selected == null
                            ? ''
                            : '${selected['trafficGb']} GB 流量',
                        style: const TextStyle(color: LetsColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('订单金额'),
                          const Spacer(),
                          Text(
                            selected == null
                                ? '—'
                                : '¥${selected['price']}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: LetsColors.deskPink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE8ECF1)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            '待支付订单',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_pendingOrders.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: LetsColors.deskPink.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_pendingOrders.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LetsColors.deskPink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _pendingOrders.isEmpty
                            ? const Text(
                                '暂无待支付订单',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LetsColors.textSecondary,
                                ),
                              )
                            : ListView.separated(
                                itemCount: _pendingOrders.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final order = _pendingOrders[index];
                                  final name =
                                      '${order['packageName'] ?? ''}'.trim();
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order['orderNo']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          name.isEmpty
                                              ? '¥${order['amount']} · 待支付'
                                              : '$name · ¥${order['amount']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: LetsColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 32,
                                                child: FilledButton(
                                                  style:
                                                      FilledButton.styleFrom(
                                                    backgroundColor:
                                                        LetsColors.deskBlue,
                                                    padding: EdgeInsets.zero,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: _busy
                                                      ? null
                                                      : () => _payExisting(
                                                            order,
                                                          ),
                                                  child: const Text(
                                                    '支付',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 32,
                                                child: OutlinedButton(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        LetsColors.textPrimary,
                                                    side: const BorderSide(
                                                      color: Color(0xFFD8DDE5),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: _busy
                                                      ? null
                                                      : () => _deleteOrder(
                                                            order,
                                                          ),
                                                  child: const Text(
                                                    '删除',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.headset_mic,
                              color: LetsColors.deskBlue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '7×24 在线客服随时为您服务。支付异常请联系客服。',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? LetsColors.deskPink.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? LetsColors.deskPink : const Color(0xFFD8DDE5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['name']}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${item['price']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: selected ? LetsColors.deskPink : LetsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${item['trafficGb']} GB · ${item['durationDays']} 天',
              style: const TextStyle(
                fontSize: 12,
                color: LetsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? LetsColors.deskBlue : const Color(0xFFD8DDE5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? LetsColors.deskBlue : LetsColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LetsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
