import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_app_bar.dart';
import 'auth_widgets.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _account = XvayAccount();
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _message = '请填写用户名和密码');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _account.login(_name.text, _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _message = authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Scaffold(
      backgroundColor: palette.page,
      appBar: const LetsAppBar(title: '登录'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text(
            '登录',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '使用用户名或邮箱登录。',
            style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
          ),
          const SizedBox(height: 16),
          if (_message != null) ...[
            AuthNote(text: _message!),
            const SizedBox(height: 12),
          ],
          AuthCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: authFieldDecoration(palette, '用户名或邮箱'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: authFieldDecoration(palette, '密码'),
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(
                  label: '登录',
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _openRegister,
            child: const Text('没有账号，去注册'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecoverScreen()),
                    );
                  },
            child: const Text('找回账号'),
          ),
        ],
      ),
    );
  }
}

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _account = XvayAccount();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode(String scene) async {
    try {
      await _account.apiPost('/api/auth/email/send-code', {
        'email': _email.text.trim(),
        'scene': scene,
      }, auth: false);
      if (mounted) setState(() => _message = '验证码已发送，5 分钟内有效');
    } catch (error) {
      if (mounted) setState(() => _message = authError(error));
    }
  }

  Future<void> _find() async {
    try {
      final data = await _account.apiPost('/api/auth/find-account', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
      }, auth: false);
      if (mounted) {
        setState(
          () => _message = '关联账号 ${data['userId']}（${data['username']}）',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = authError(error));
    }
  }

  Future<void> _reset() async {
    try {
      await _account.apiPost('/api/auth/reset-password-by-email', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
        'password': _password.text,
      }, auth: false);
      if (mounted) setState(() => _message = '密码已重置，请返回登录');
    } catch (error) {
      if (mounted) setState(() => _message = authError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Scaffold(
      backgroundColor: palette.page,
      appBar: const LetsAppBar(title: '找回账号'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text(
            '找回账号',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '用绑定邮箱接收验证码，查看账号或重置密码。',
            style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
          ),
          const SizedBox(height: 16),
          if (_message != null) ...[
            AuthNote(text: _message!),
            const SizedBox(height: 12),
          ],
          AuthCard(
            child: Column(
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: authFieldDecoration(palette, '绑定邮箱'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  decoration: authFieldDecoration(palette, '验证码'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: authFieldDecoration(palette, '新密码'),
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(label: '查看关联账号', onPressed: _find),
                const SizedBox(height: 8),
                AuthSecondaryButton(label: '重置密码', onPressed: _reset),
                const SizedBox(height: 8),
                AuthSecondaryButton(
                  label: '发送找回验证码',
                  onPressed: () => _sendCode('find_account'),
                ),
                const SizedBox(height: 8),
                AuthSecondaryButton(
                  label: '发送重置验证码',
                  onPressed: () => _sendCode('reset_password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
