import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_app_bar.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _account = XvayAccount();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _register = false;
  bool _recover = false;
  bool _busy = false;
  String? _message;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _wallet = {};
  Map<String, dynamic> _inviteInfo = {};
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _services = [];

  bool get _loggedIn => _account.isLoggedIn;

  @override
  void initState() {
    super.initState();
    if (_loggedIn) _refresh();
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _invite.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
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
      final services = await _account.apiGet('/api/customer-service');
      Map<String, dynamic> wallet = {};
      if (profile['walletEnabled'] == 1) {
        wallet = await _account.apiGet('/api/wallet');
      }
      final invite = await _account.apiGet('/api/invite');
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _packages = _list(packages['packages']);
        _orders = _list(orders['orders']);
        _wallet = wallet;
        _inviteInfo = invite;
        _notices = _list(notices['announcements']);
        _services = _list(services['services']);
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

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      if (_register) {
        await _account.register(_name.text, _password.text, _invite.text);
      } else {
        await _account.login(_name.text, _password.text);
      }
      await _refresh();
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    setState(() => _busy = true);
    try {
      final data = await _account.apiPost('/api/orders', {
        'packageId': item['id'],
      });
      final order = data['order'];
      final no = order is Map ? order['orderNo'] : '';
      if (mounted) setState(() => _message = '订单 $no 已创建，等待四方支付到账');
      await _refresh();
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
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

  Future<void> _find() async {
    try {
      final data = await _account.apiPost('/api/auth/find-account', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
      }, auth: false);
      if (mounted)
        setState(
          () => _message = '关联账号 ${data['userId']}（${data['username']}）',
        );
    } catch (error) {
      if (mounted)
        setState(() => _message = '$error'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reset() async {
    try {
      await _account.apiPost('/api/auth/reset-password-by-email', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
        'password': _password.text,
      }, auth: false);
      if (mounted) setState(() => _message = '密码已重置，请登录');
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
      appBar: const LetsAppBar(title: '我的'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_message != null)
            Text(
              _message!,
              style: const TextStyle(color: LetsColors.textSecondary),
            ),
          if (!_loggedIn) ..._guest() else ..._home(),
        ],
      ),
    );
  }

  List<Widget> _guest() {
    return [
      Text(
        _recover ? '找回账号' : (_register ? '注册' : '登录'),
        style: const TextStyle(fontSize: 22),
      ),
      const SizedBox(height: 8),
      const Text('用户名和密码即可注册，不需要实名、微信或手机授权。'),
      const SizedBox(height: 12),
      TextField(
        controller: _name,
        decoration: _fieldDecoration(LetsColors.of(context), '用户名或邮箱'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: _fieldDecoration(LetsColors.of(context), '密码'),
      ),
      if (_register) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _invite,
          decoration: _fieldDecoration(LetsColors.of(context), '邀请码，可选'),
        ),
      ],
      if (_recover) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: _fieldDecoration(LetsColors.of(context), '绑定邮箱'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          decoration: _fieldDecoration(LetsColors.of(context), '验证码'),
        ),
      ],
      const SizedBox(height: 12),
      if (!_recover)
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_register ? '注册' : '登录'),
        ),
      TextButton(
        onPressed: () => setState(() => _register = !_register),
        child: Text(_register ? '已有账号，去登录' : '没有账号，去注册'),
      ),
      TextButton(
        onPressed: () => setState(() => _recover = !_recover),
        child: Text(_recover ? '返回登录' : '找回账号'),
      ),
      if (_recover) ...[
        TextButton(
          onPressed: () => _sendCode('find_account'),
          child: const Text('发送找回验证码'),
        ),
        TextButton(onPressed: _find, child: const Text('查看关联账号')),
        TextButton(
          onPressed: () => _sendCode('reset_password'),
          child: const Text('发送重置验证码'),
        ),
        TextButton(onPressed: _reset, child: const Text('重置密码')),
      ],
    ];
  }

  List<Widget> _home() {
    final gb = _profile['trafficRemainGb'];
    final seconds = _profile['remainSeconds'];
    final days = seconds is num ? (seconds.toInt() / 86400).floor() : 0;
    return [
      Row(
        children: [
          CircleAvatar(child: Text(_initial())),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_profile['username'] ?? ''}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '${_profile['userType'] ?? '普通用户'} · ID ${_profile['id'] ?? ''}',
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${_profile['id'] ?? ''}'));
              setState(() => _message = '已复制 ID');
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('剩余流量 ${gb is num ? gb.toStringAsFixed(2) : '0.00'} GB'),
      Text('剩余 $days 天'),
      const SizedBox(height: 16),
      const Text('购买节点', style: TextStyle(fontSize: 16)),
      ..._packages.map(
        (item) => ListTile(
          title: Text('${item['name']}'),
          subtitle: Text('${item['trafficGb']} GB · ${item['durationDays']} 天'),
          trailing: Text('¥${item['price']}'),
          onTap: _busy ? null : () => _buy(item),
        ),
      ),
      if (_profile['walletEnabled'] == 1) ...[
        const Text('钱包', style: TextStyle(fontSize: 16)),
        Text('推荐获利 ¥${_wallet['totalIncome'] ?? 0}'),
        Text('可提现 ¥${_wallet['balance'] ?? 0}  冻结 ¥${_wallet['frozen'] ?? 0}'),
      ],
      const SizedBox(height: 8),
      const Text('推荐有奖', style: TextStyle(fontSize: 16)),
      Text('推荐码 ${_inviteInfo['inviteCode'] ?? ''}'),
      Text('${_inviteInfo['inviteUrl'] ?? ''}'),
      Text('${_inviteInfo['mode'] ?? ''}'),
      const SizedBox(height: 8),
      const Text('我的订单', style: TextStyle(fontSize: 16)),
      ..._orders
          .take(8)
          .map(
            (item) => ListTile(
              title: Text('${item['orderNo']}'),
              subtitle: Text(
                '¥${item['amount']} · ${_payName(item['payStatus'])}',
              ),
            ),
          ),
      const SizedBox(height: 8),
      const Text('公告', style: TextStyle(fontSize: 16)),
      ..._notices.map(
        (item) => ListTile(
          title: Text('${item['title']}'),
          subtitle: Text('${item['body']}'),
        ),
      ),
      const Text('客服', style: TextStyle(fontSize: 16)),
      ..._services.map(
        (item) => Text('${item['channel']}  ${item['account']}'),
      ),
      const SizedBox(height: 12),
      const Text('账号防丢失', style: TextStyle(fontSize: 16)),
      TextField(
        controller: _email,
        decoration: _fieldDecoration(LetsColors.of(context), '邮箱'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        decoration: _fieldDecoration(LetsColors.of(context), '验证码'),
      ),
      TextButton(
        onPressed: () => _sendCode('bind_email'),
        child: const Text('发送绑定验证码'),
      ),
      TextButton(onPressed: _bind, child: const Text('绑定邮箱')),
      TextButton(
        onPressed: () async {
          await _account.logout();
          if (mounted) setState(() => _profile = {});
        },
        child: const Text('退出登录'),
      ),
    ];
  }

  String _initial() {
    final name = '${_profile['username'] ?? ''}';
    if (name.isEmpty) return '飞';
    return String.fromCharCode(name.runes.first);
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
