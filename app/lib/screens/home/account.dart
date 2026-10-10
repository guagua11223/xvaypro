import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/lets_colors.dart';
import '../../theme/lets_icons.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_app_bar.dart';
import 'auth_widgets.dart';
import 'login.dart';
import 'register.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _account = XvayAccount();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _withdraw = TextEditingController();
  final _ticketTitle = TextEditingController();
  final _ticketBody = TextEditingController();
  bool _busy = false;
  String? _message;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _wallet = {};
  Map<String, dynamic> _inviteInfo = {};
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _tickets = [];
  Uint8List? _qr;

  bool get _loggedIn => _account.isLoggedIn;

  @override
  void initState() {
    super.initState();
    if (_loggedIn) _refresh();
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _withdraw.dispose();
    _ticketTitle.dispose();
    _ticketBody.dispose();
    super.dispose();
  }

  String _moneyStatus(dynamic value, List<String> names) {
    final index = value is int ? value : int.tryParse('$value') ?? -1;
    if (index < 0 || index >= names.length) return '';
    return names[index];
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final profile = await _account.apiGet('/api/user/profile');
      final packages = await _account.apiGet('/api/packages');
      final orders = await _account.apiGet('/api/orders');
      final notices = await _account.apiGet('/api/announcements');
      final ads = await _account.apiGet('/api/ads');
      final services = await _account.apiGet('/api/customer-service');
      Map<String, dynamic> wallet = {};
      if (profile['walletEnabled'] == 1) {
        wallet = await _account.apiGet('/api/wallet');
      }
      final invite = await _account.apiGet('/api/invite');
      final tickets = await _account.apiGet('/api/user/tickets');
      Uint8List? qr;
      try {
        qr = await _account.apiBytes('/api/app/invite/qr.png');
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _packages = _list(packages['packages']);
        _orders = _list(orders['orders']);
        _wallet = wallet;
        _inviteInfo = invite;
        _notices = _list(notices['announcements']);
        _ads = _list(ads['ads']);
        _services = _list(services['services']);
        _tickets = _list(tickets['tickets']);
        _qr = qr;
        _message = null;
      });
      if (profile['emailStatus'] != 2 && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('账号防丢失'),
            content: const Text('还没有绑定邮箱。绑定后可以用邮箱找回账号和重置密码。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAuth(Widget page) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => page),
    );
    if (ok == true && mounted) await _refresh();
  }

  bool get _hasUnpaid => _orders.any(commerceOrderPending);

  Future<void> _buy(Map<String, dynamic> item) async {
    if (_hasUnpaid) {
      setState(() => _message = '有待支付订单，请先完成支付');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await _account.apiPost('/api/orders', {
        'packageId': item['id'],
      });
      final order = data['order'];
      final no = order is Map ? order['orderNo'] : '';
      if (mounted) setState(() => _message = '订单 $no 已创建，请点击支付打开 EPAY 收银台');
      await _refresh();
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteOrder(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订单'),
        content: Text('删除待支付订单 ${item['orderNo']}？删除后可以重新购买。'),
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
    setState(() => _busy = true);
    try {
      await _account.apiPost('/api/orders/cancel', {'orderId': item['id']});
      if (mounted) setState(() => _message = '已删除待支付订单');
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay(Map<String, dynamic> item) async {
    setState(() => _busy = true);
    try {
      final data = await _account.apiPost('/api/pay/create', {
        'orderId': item['id'],
      });
      final url = payLink(data);
      if (!mounted) return;
      if (url == null) {
        setState(
          () => _message =
              '订单 ${item['orderNo']} 待支付 ¥${item['amount']}，支付网关未返回链接',
        );
        return;
      }
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(
        () => _message = opened ? '已打开支付页面，完成后请刷新' : '无法打开支付页面',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdrawMoney() async {
    final amount = double.tryParse(_withdraw.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _message = '请填写提现金额');
      return;
    }
    setState(() => _busy = true);
    try {
      await _account.apiPost('/api/wallet/withdraw', {'amount': amount});
      _withdraw.clear();
      if (mounted) setState(() => _message = '提现申请已提交，等待审核');
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitTicket() async {
    if (_ticketTitle.text.trim().isEmpty || _ticketBody.text.trim().isEmpty) {
      setState(() => _message = '请填写工单标题和内容');
      return;
    }
    setState(() => _busy = true);
    try {
      await _account.apiPost('/api/user/tickets', {
        'title': _ticketTitle.text.trim(),
        'body': _ticketBody.text.trim(),
      });
      _ticketTitle.clear();
      _ticketBody.clear();
      if (mounted) setState(() => _message = '工单已提交');
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode(String scene) async {
    try {
      await _account.apiPost('/api/auth/email/send-code', {
        'email': _email.text.trim(),
        'scene': scene,
      }, auth: scene != 'bind_email');
      if (mounted) setState(() => _message = '验证码已发送，5 分钟内有效');
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _bind() async {
    try {
      await _account.apiPost('/api/user/email/bind', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
      });
      if (mounted) setState(() => _message = '邮箱已绑定');
      await _refresh();
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Scaffold(
      backgroundColor: palette.page,
      appBar: LetsAppBar(
        title: '我的',
        actions: [
          if (_loggedIn)
            IconButton(
              tooltip: '刷新',
              onPressed: _busy ? null : _refresh,
              color: palette.onBar,
              icon: const Icon(LetsIcons.refresh, size: LetsIcons.size),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: LetsColors.accent,
                backgroundColor: Colors.transparent,
              ),
            ),
          if (_message != null) ...[
            _note(palette, _message!),
            const SizedBox(height: 12),
          ],
          if (!_loggedIn) ..._guest(palette) else ..._home(palette),
        ],
      ),
    );
  }

  List<Widget> _guest(LetsPalette palette) {
    return [
      Text(
        '登录后查看流量、套餐和订单。',
        style: TextStyle(fontSize: 14, height: 1.4, color: palette.muted),
      ),
      const SizedBox(height: 16),
      AuthPrimaryButton(
        label: '登录',
        onPressed: () => _openAuth(const LoginScreen()),
      ),
      const SizedBox(height: 12),
      AuthSecondaryButton(
        label: '注册',
        onPressed: () => _openAuth(const RegisterScreen()),
      ),
    ];
  }

  List<Widget> _home(LetsPalette palette) {
    final gb = _profile['trafficRemainGb'];
    final seconds = _profile['remainSeconds'];
    final days = seconds is num ? (seconds.toInt() / 86400).floor() : 0;
    final traffic = gb is num ? gb.toStringAsFixed(2) : '0.00';
    final inviteCode = '${_inviteInfo['inviteCode'] ?? ''}';
    final inviteUrl = '${_inviteInfo['inviteUrl'] ?? ''}';
    final parentName = '${_profile['parentName'] ?? _inviteInfo['parentName'] ?? ''}';
    final invitees = _list(_inviteInfo['invitees']);
    return [
      _card(
        palette,
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_profile['userType'] ?? '普通用户'} · ID ${_profile['id'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                  if (parentName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '推荐人 $parentName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '复制 ID',
              onPressed: () => _copy('${_profile['id'] ?? ''}', '已复制 ID'),
              icon: Icon(LetsIcons.copy, color: palette.muted, size: LetsIcons.size),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _stat(palette, '剩余流量', '$traffic GB')),
          const SizedBox(width: 12),
          Expanded(child: _stat(palette, '剩余时长', '$days 天')),
        ],
      ),
      if (days > 0 && days <= 3) ...[
        const SizedBox(height: 12),
        _note(palette, '套餐将在 $days 天后到期。续费会按新套餐重新计算流量，到期流量不结转。'),
      ],
      const SizedBox(height: 20),
      _heading(palette, '购买 / 续费'),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          '支付走四方支付。续费成功后流量按新套餐重置，不结转剩余流量。',
          style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
        ),
      ),
      if (_hasUnpaid)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            '有待支付订单，请先完成支付后再购买。',
            style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
          ),
        ),
      if (_packages.isEmpty)
        _empty(palette, '暂时没有可购买的套餐')
      else
        ..._packages.map(
          (item) => _packageTile(palette, item, enabled: !_hasUnpaid),
        ),
      if (_profile['walletEnabled'] == 1) ...[
        const SizedBox(height: 8),
        _heading(palette, '钱包'),
        _card(
          palette,
          Column(
            children: [
              _kv(palette, '推荐获利', '¥${_wallet['totalIncome'] ?? 0}'),
              _kv(palette, '可提现', '¥${_wallet['balance'] ?? 0}'),
              _kv(palette, '冻结', '¥${_wallet['frozen'] ?? 0}'),
              _kv(
                palette,
                '负余额',
                '¥${_wallet['negativeBalance'] ?? 0}',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '最低提现 ¥${_wallet['minAmount'] ?? 0}，手续费 ${_wallet['feeRate'] ?? 0}%。待结算佣金在冻结里，结算后才能提现。',
          style: TextStyle(fontSize: 12, height: 1.4, color: palette.muted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _withdraw,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(palette, '提现金额'),
        ),
        const SizedBox(height: 8),
        _primaryButton(
          label: '申请提现',
          onPressed: _busy ? null : _withdrawMoney,
        ),
        if (_list(_wallet['commissions']).isNotEmpty) ...[
          const SizedBox(height: 8),
          _heading(palette, '返利明细'),
          _card(
            palette,
            Column(
              children: [
                for (final row in _list(_wallet['commissions']))
                  _kv(
                    palette,
                    '${row['fromUsername'] ?? row['fromUserId'] ?? ''} · ${row['level'] ?? ''}级 · ${_moneyStatus(row['status'], const ['待结算', '已结算', '已退回'])}',
                    '¥${row['amount'] ?? 0}',
                  ),
              ],
            ),
          ),
        ],
        if (_list(_wallet['withdrawals']).isNotEmpty) ...[
          const SizedBox(height: 8),
          _heading(palette, '提现记录'),
          _card(
            palette,
            Column(
              children: [
                for (final row in _list(_wallet['withdrawals']))
                  _kv(
                    palette,
                    '${_moneyStatus(row['status'], const ['待审核', '审核通过', '已打款', '已拒绝', '已取消'])}',
                    '¥${row['amount'] ?? 0}',
                  ),
              ],
            ),
          ),
        ],
      ],
      const SizedBox(height: 8),
      _heading(palette, '推荐有奖'),
      _card(
        palette,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copyLine(palette, '推荐码', inviteCode),
            if (inviteUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              _copyLine(palette, '推荐链接', inviteUrl),
            ],
            if (_qr != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Image.memory(_qr!, width: 160, height: 160),
              ),
            ],
            for (final ad in _ads.where((item) => item['slot'] == 'invite')) ...[
              const SizedBox(height: 12),
              _adImage(ad),
            ],
            if (_list(_inviteInfo['team']).isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final person in _list(_inviteInfo['team']))
                _kv(
                  palette,
                  '${person['username'] ?? ''}',
                  '${person['userTypeLabel'] ?? person['userType'] ?? ''} · ${person['level'] ?? ''}级',
                ),
            ],
            if ('${_inviteInfo['mode'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_inviteInfo['mode']}',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '已邀请 ${invitees.length} 人',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            if (invitees.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '把推荐码发给好友，对方注册时填写后会挂到你名下。',
                style: TextStyle(fontSize: 12, height: 1.4, color: palette.muted),
              ),
            ] else ...[
              for (var i = 0; i < invitees.length && i < 8; i++) ...[
                const SizedBox(height: 8),
                Text(
                  '${invitees[i]['username'] ?? ''} · ID ${invitees[i]['id'] ?? ''}',
                  style: TextStyle(fontSize: 13, color: palette.text),
                ),
              ],
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
      _heading(palette, '我的订单'),
      if (_orders.isEmpty)
        _empty(palette, '还没有订单')
      else
        _card(
          palette,
          Column(
            children: [
              for (var i = 0; i < _shownOrders.length; i++)
                _orderRow(
                  palette,
                  _shownOrders[i],
                  last: i == _shownOrders.length - 1,
                ),
            ],
          ),
        ),
      if (_notices.isNotEmpty) ...[
        const SizedBox(height: 8),
        _heading(palette, '公告'),
        ..._notices.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              palette,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_noticeKind(item['noticeType'])} · ${item['title']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item['body']}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      if (_services.isNotEmpty) ...[
        const SizedBox(height: 8),
        _heading(palette, '客服'),
        _card(
          palette,
          Column(
            children: [
              for (var i = 0; i < _services.length; i++) ...[
                _copyLine(
                  palette,
                  _channelName('${_services[i]['channel']}'),
                  '${_services[i]['account']}',
                  last: i == _services.length - 1 &&
                      '${_services[i]['qrUrl'] ?? ''}'.isEmpty,
                ),
                if ('${_services[i]['qrUrl'] ?? ''}'.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Image.network(
                      '${_services[i]['qrUrl']}',
                      height: 120,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 8),
      _heading(palette, '账号防丢失'),
      _card(
        palette,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '绑定邮箱后，可以用邮箱找回账号和重置密码。',
              style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(palette, '邮箱'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: _fieldDecoration(palette, '验证码'),
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              label: '发送绑定验证码',
              onPressed: () => _sendCode('bind_email'),
            ),
            const SizedBox(height: 8),
            _primaryButton(label: '绑定邮箱', onPressed: _busy ? null : _bind),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _heading(palette, '提交工单'),
      _card(
        palette,
        Column(
          children: [
            TextField(
              controller: _ticketTitle,
              decoration: _fieldDecoration(palette, '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ticketBody,
              minLines: 2,
              maxLines: 4,
              decoration: _fieldDecoration(palette, '内容'),
            ),
            const SizedBox(height: 12),
            _primaryButton(
              label: '提交工单',
              onPressed: _busy ? null : _submitTicket,
            ),
            if (_tickets.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final ticket in _tickets)
                _kv(
                  palette,
                  '${ticket['title'] ?? ''}',
                  '${ticket['status'] ?? ''}',
                ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _secondaryButton(
        label: '退出登录',
        onPressed: () async {
          await _account.logout();
          if (mounted) {
            setState(() {
              _profile = {};
              _message = null;
            });
          }
        },
      ),
    ];
  }

  void _copy(String text, String tip) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _message = tip);
  }

  Widget _note(LetsPalette palette, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LetsColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LetsColors.radiusInput),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, height: 1.4, color: palette.text),
      ),
    );
  }

  Widget _card(LetsPalette palette, Widget child) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(LetsColors.radiusCard),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _heading(LetsPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: palette.text,
        ),
      ),
    );
  }

  Widget _empty(LetsPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        palette,
        Text(text, style: TextStyle(fontSize: 13, color: palette.muted)),
      ),
    );
  }

  Widget _stat(LetsPalette palette, String label, String value) {
    return _card(
      palette,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: palette.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _shownOrders => visibleOrders(_orders);

  Widget _packageTile(
    LetsPalette palette,
    Map<String, dynamic> item, {
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(LetsColors.radiusCard),
            onTap: !enabled || _busy ? null : () => _buy(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['trafficGb']} GB · ${item['durationDays']} 天',
                          style: TextStyle(fontSize: 13, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¥${item['price']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: LetsColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(
    LetsPalette palette,
    String label,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyLine(
    LetsPalette palette,
    String label,
    String value, {
    bool last = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(fontSize: 13, height: 1.4, color: palette.text),
            ),
          ),
          if (value.isNotEmpty)
            InkWell(
              onTap: () => _copy(value, '已复制$label'),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  LetsIcons.copy,
                  size: 18,
                  color: palette.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderRow(
    LetsPalette palette,
    Map<String, dynamic> item, {
    required bool last,
  }) {
    final status = _payName(item['payStatus']);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['orderNo']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: palette.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${item['amount']}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: status == '已支付' ? LetsColors.accent : palette.muted,
                ),
              ),
              if (commerceOrderPending(item)) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LetsColors.accent,
                          foregroundColor: LetsColors.onAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _busy ? null : () => _pay(item),
                        child: const Text('支付', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.text,
                          side: BorderSide(color: palette.line),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _busy ? null : () => _deleteOrder(item),
                        child: const Text('删除', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: LetsColors.accent,
          foregroundColor: LetsColors.onAccent,
          disabledBackgroundColor: LetsColors.accent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final palette = LetsColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  String _displayName() {
    final name = '${_profile['nickname'] ?? _profile['username'] ?? ''}';
    return name;
  }

  String _initial() {
    final name = _displayName();
    if (name.isEmpty) return '讯';
    return String.fromCharCode(name.runes.first);
  }

  Widget _avatar() {
    final url = '${_profile['avatar'] ?? ''}';
    if (url.startsWith('http')) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: LetsColors.accent.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: LetsColors.accent.withValues(alpha: 0.12),
      child: Text(
        _initial(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LetsColors.accent,
        ),
      ),
    );
  }

  Widget _adImage(Map<String, dynamic> ad) {
    final image = '${ad['imageUrl'] ?? ''}';
    return GestureDetector(
      onTap: () => _openLink('${ad['linkUrl'] ?? ''}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LetsColors.radiusInput),
        child: image.isEmpty
            ? Text('${ad['title'] ?? ''}')
            : Image.network(
                image,
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text('${ad['title'] ?? ''}'),
              ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _noticeKind(dynamic value) {
    switch ('$value') {
      case 'activity':
        return '活动';
      case 'maintenance':
        return '维护';
      default:
        return '公告';
    }
  }

  String _channelName(String value) {
    switch (value) {
      case 'wechat':
        return '微信';
      case 'qq':
        return 'QQ';
      case 'telegram':
        return 'Telegram';
      case 'online':
        return '在线客服';
      default:
        return value;
    }
  }

  String _payName(dynamic value) {
    const names = ['待支付', '已支付', '已退款', '已关闭'];
    final index = value is num ? value.toInt() : -1;
    if (index < 0 || index >= names.length) return '—';
    return names[index];
  }

  InputDecoration _fieldDecoration(LetsPalette palette, String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LetsColors.radiusInput),
      borderSide: BorderSide(color: palette.line),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.muted),
      filled: true,
      fillColor: palette.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: LetsColors.accent, width: 1.5),
      ),
    );
  }
}

bool commerceOrderPending(Map<String, dynamic> item) {
  final value = item['payStatus'];
  return value is num && value.toInt() == 0;
}

List<Map<String, dynamic>> visibleOrders(List<Map<String, dynamic>> orders) {
  final pending = orders.where(commerceOrderPending).toList();
  final rest = orders.where((item) => !commerceOrderPending(item)).take(8);
  return [...pending, ...rest];
}

String? payLink(Map<String, dynamic> data) {
  for (final key in ['payUrl', 'url', 'gateway']) {
    final value = data[key];
    if (value is String &&
        (value.startsWith('http://') || value.startsWith('https://'))) {
      return value;
    }
  }
  return null;
}
