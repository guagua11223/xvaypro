import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lets_colors.dart';
import '../../theme/lets_icons.dart';
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
      appBar: LetsAppBar(
        title: '我的',
        actions: [
          if (_loggedIn)
            IconButton(
              tooltip: '刷新',
              onPressed: _busy ? null : _refresh,
              color: palette.onBar,
              icon: const Icon(Icons.refresh, size: LetsIcons.size),
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
        _recover ? '找回账号' : (_register ? '注册' : '登录'),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: palette.text,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '用户名和密码即可注册，不需要实名、微信或手机授权。',
        style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
      ),
      const SizedBox(height: 16),
      _card(
        palette,
        Column(
          children: [
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(palette, '用户名或邮箱'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              textInputAction: _register || _recover
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: _fieldDecoration(palette, '密码'),
            ),
            if (_register) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _invite,
                decoration: _fieldDecoration(palette, '邀请码，可选'),
              ),
            ],
            if (_recover) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(palette, '绑定邮箱'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                decoration: _fieldDecoration(palette, '验证码'),
              ),
            ],
            const SizedBox(height: 16),
            if (!_recover)
              _primaryButton(
                label: _register ? '注册' : '登录',
                onPressed: _busy ? null : _submit,
              )
            else ...[
              _primaryButton(
                label: '查看关联账号',
                onPressed: _busy ? null : _find,
              ),
              const SizedBox(height: 8),
              _secondaryButton(label: '重置密码', onPressed: _reset),
              const SizedBox(height: 8),
              _secondaryButton(
                label: '发送找回验证码',
                onPressed: () => _sendCode('find_account'),
              ),
              const SizedBox(height: 8),
              _secondaryButton(
                label: '发送重置验证码',
                onPressed: () => _sendCode('reset_password'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          if (!_recover)
            TextButton(
              onPressed: () => setState(() {
                _register = !_register;
                _message = null;
              }),
              child: Text(_register ? '已有账号，去登录' : '没有账号，去注册'),
            ),
          TextButton(
            onPressed: () => setState(() {
              _recover = !_recover;
              _register = false;
              _message = null;
            }),
            child: Text(_recover ? '返回登录' : '找回账号'),
          ),
        ],
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
    return [
      _card(
        palette,
        Row(
          children: [
            CircleAvatar(
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
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_profile['username'] ?? ''}',
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
                ],
              ),
            ),
            IconButton(
              tooltip: '复制 ID',
              onPressed: () => _copy('${_profile['id'] ?? ''}', '已复制 ID'),
              icon: Icon(Icons.copy_outlined, color: palette.muted, size: 20),
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
      const SizedBox(height: 20),
      _heading(palette, '购买节点'),
      if (_packages.isEmpty)
        _empty(palette, '暂时没有可购买的套餐')
      else
        ..._packages.map((item) => _packageTile(palette, item)),
      if (_profile['walletEnabled'] == 1) ...[
        const SizedBox(height: 8),
        _heading(palette, '钱包'),
        _card(
          palette,
          Column(
            children: [
              _kv(palette, '推荐获利', '¥${_wallet['totalIncome'] ?? 0}'),
              _kv(palette, '可提现', '¥${_wallet['balance'] ?? 0}'),
              _kv(palette, '冻结', '¥${_wallet['frozen'] ?? 0}', last: true),
            ],
          ),
        ),
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
            if ('${_inviteInfo['mode'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_inviteInfo['mode']}',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
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
              for (var i = 0; i < _orders.take(8).length; i++)
                _orderRow(
                  palette,
                  _orders[i],
                  last: i == _orders.take(8).length - 1,
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
                    '${item['title']}',
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
              for (var i = 0; i < _services.length; i++)
                _copyLine(
                  palette,
                  '${_services[i]['channel']}',
                  '${_services[i]['account']}',
                  last: i == _services.length - 1,
                ),
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

  Widget _packageTile(LetsPalette palette, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(LetsColors.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(LetsColors.radiusCard),
          onTap: _busy ? null : () => _buy(item),
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
                  Icons.copy_outlined,
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
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              color: status == '已支付' ? LetsColors.accent : palette.muted,
            ),
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
