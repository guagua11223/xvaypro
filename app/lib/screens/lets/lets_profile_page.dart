import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lets_colors.dart';
import '../../utils/xvay_account.dart';
import '../../widgets/lets_app_bar.dart';
import '../home/login.dart';
import 'lets_session.dart';

class LetsProfilePage extends StatefulWidget {
  const LetsProfilePage({super.key, this.asPage = false});

  /// Android / mobile: push as a full page with app bar.
  final bool asPage;

  @override
  State<LetsProfilePage> createState() => _LetsProfilePageState();
}

class _LetsProfilePageState extends State<LetsProfilePage> {
  final _account = XvayAccount();
  final _invite = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.asPage && _account.isLoggedIn) {
      LetsSession.instance.refresh();
    }
  }

  @override
  void dispose() {
    _invite.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _bindInvite() async {
    final code = _invite.text.trim();
    if (code.isEmpty) {
      setState(() => _message = '请填写邀请码');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _account.apiPost('/api/user/invite/bind', {'inviteCode': code});
      _invite.clear();
      await LetsSession.instance.refresh();
      if (mounted) setState(() => _message = '邀请码已绑定');
    } catch (e) {
      if (mounted) {
        setState(() => _message = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPassword.text.isEmpty || _newPassword.text.isEmpty) {
      setState(() => _message = '请填写原密码和新密码');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _message = '两次输入的新密码不一致');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _account.apiPost('/api/user/password/change', {
        'oldPassword': _oldPassword.text,
        'password': _newPassword.text,
      });
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) setState(() => _message = '密码已修改');
    } catch (e) {
      if (mounted) {
        setState(() => _message = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchAccount() async {
    await _account.logout();
    await LetsSession.instance.refresh();
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (ok == true) {
      await LetsSession.instance.refresh();
      return;
    }
    if (widget.asPage && mounted && !_account.isLoggedIn) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: LetsSession.instance,
      builder: (context, _) {
        final session = LetsSession.instance;
        final profile = session.profile;
        final parentName = '${profile['parentName'] ?? ''}';
        final parentId = profile['parentId'];
        final hasParent =
            parentId is num && parentId.toInt() > 0 || parentName.isNotEmpty;
        final email = '${profile['email'] ?? ''}';
        final userType = '${profile['userType'] ?? '普通用户'}';
        final inviteCode =
            '${profile['inviteCode'] ?? session.invite['inviteCode'] ?? ''}';
        final pad = widget.asPage
            ? const EdgeInsets.fromLTRB(16, 16, 16, 28)
            : const EdgeInsets.fromLTRB(28, 24, 28, 32);

        return ColoredBox(
          color: LetsColors.deskPage,
          child: ListView(
            padding: pad,
            children: [
              if (!widget.asPage) ...[
                const Text(
                  '个人中心',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '查看账号信息，绑定推荐关系，或切换登录账号。',
                  style: TextStyle(
                    fontSize: 13,
                    color: LetsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const Text(
                  '查看账号信息，绑定推荐关系，或切换登录账号。',
                  style: TextStyle(
                    fontSize: 13,
                    color: LetsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_message != null) ...[
                _Notice(text: _message!),
                const SizedBox(height: 16),
              ],
              _Card(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: widget.asPage ? 28 : 34,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                        size: widget.asPage ? 30 : 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ID ${session.userId.isEmpty ? '—' : session.userId}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: LetsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userType,
                            style: const TextStyle(
                              fontSize: 13,
                              color: LetsColors.deskBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.userId.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: session.userId),
                          );
                          setState(() => _message = '已复制用户 ID');
                        },
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('复制 ID'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: '个人信息',
                child: Column(
                  children: [
                    _InfoRow(label: '用户名', value: session.username),
                    _InfoRow(
                      label: '用户 ID',
                      value: session.userId.isEmpty ? '—' : session.userId,
                    ),
                    _InfoRow(label: '邮箱', value: email.isEmpty ? '未绑定' : email),
                    _InfoRow(label: '账号类型', value: userType),
                    _InfoRow(
                      label: '推荐人',
                      value: hasParent
                          ? (parentName.isEmpty ? 'ID $parentId' : parentName)
                          : '未绑定',
                    ),
                    _InfoRow(
                      label: '我的邀请码',
                      value: inviteCode.isEmpty ? '—' : inviteCode,
                      trailing: inviteCode.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '复制邀请码',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: inviteCode),
                                );
                                setState(() => _message = '已复制邀请码');
                              },
                              icon: const Icon(Icons.copy_outlined, size: 16),
                            ),
                    ),
                    _InfoRow(label: '到期时间', value: session.expireText),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: '绑定邀请码',
                child: hasParent
                    ? Text(
                        '已绑定推荐人${parentName.isEmpty ? '' : '：$parentName'}，不能重复绑定。',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: LetsColors.textSecondary,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '注册时未填写邀请码的，可在这里补绑一次。绑定后挂到对方名下，不能再改。',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: LetsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _invite,
                            decoration: _inputDecoration('请输入邀请码'),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              style: _primaryButton(),
                              onPressed: _busy ? null : _bindInvite,
                              child: const Text('确认绑定'),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: '修改密码',
                child: Column(
                  children: [
                    TextField(
                      controller: _oldPassword,
                      obscureText: true,
                      decoration: _inputDecoration('原密码'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPassword,
                      obscureText: true,
                      decoration: _inputDecoration('新密码（至少 8 位）'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPassword,
                      obscureText: true,
                      decoration: _inputDecoration('确认新密码'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: _primaryButton(),
                        onPressed: _busy ? null : _changePassword,
                        child: const Text('保存新密码'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: '切换账号',
                child: widget.asPage
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '退出当前账号并打开登录页，可登录其他账号。',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: LetsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _busy ? null : _switchAccount,
                            child: const Text('切换账号'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '退出当前账号并打开登录页，可登录其他账号。',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: LetsColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _busy ? null : _switchAccount,
                            child: const Text('切换账号'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.asPage) return body;
    return Scaffold(
      backgroundColor: LetsColors.deskPage,
      appBar: const LetsAppBar(title: '个人中心'),
      body: body,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8DDE5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8DDE5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  ButtonStyle _primaryButton() {
    return FilledButton.styleFrom(
      backgroundColor: LetsColors.deskBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: LetsColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LetsColors.deskBanner,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
    );
  }
}
