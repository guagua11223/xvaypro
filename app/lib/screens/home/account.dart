import 'package:flutter/material.dart';

import '../../config/backend.dart';
import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _account = XvayAccount();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _email.text = _account.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = '请填写邮箱和密码');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final user = _register
          ? await _account.register(email, password)
          : await _account.login(email, password);
      if (!mounted) return;
      setState(() {
        _message = '已同步订阅：${user['subscriptionUrl'] ?? ''}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    await _account.logout();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = '已退出';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LetsColors.pageBg,
      appBar: AppBar(
        title: const Text('XVAY 账户'),
        backgroundColor: LetsColors.white,
        foregroundColor: LetsColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            kBackendBase,
            style: const TextStyle(color: LetsColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('登录后会把你的订阅写入线路配置，客户端按这个地址拉取节点。'),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '邮箱'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '请稍候' : (_register ? '注册并同步' : '登录并同步')),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _register = !_register),
            child: Text(_register ? '已有账号，去登录' : '没有账号，注册试用'),
          ),
          if (_account.isLoggedIn)
            TextButton(onPressed: _busy ? null : _logout, child: const Text('退出登录')),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
