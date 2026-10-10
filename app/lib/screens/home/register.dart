import 'package:flutter/material.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_app_bar.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _account = XvayAccount();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _invite.dispose();
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
      await _account.register(_name.text, _password.text, _invite.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _message = authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = LetsColors.of(context);
    return Scaffold(
      backgroundColor: palette.page,
      appBar: const LetsAppBar(title: '注册'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text(
            '注册',
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
                  textInputAction: TextInputAction.next,
                  decoration: authFieldDecoration(palette, '密码'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invite,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: authFieldDecoration(palette, '邀请码，选填'),
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(
                  label: '注册',
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('已有账号，去登录'),
          ),
        ],
      ),
    );
  }
}
