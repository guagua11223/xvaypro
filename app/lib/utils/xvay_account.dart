import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/backend.dart';
import '../models/profile_group.dart';
import 'db.dart';
import 'db/update_profile_group.dart';
import 'prefs.dart';

const _tokenKey = 'xvay.token';
const _emailKey = 'xvay.email';

class XvayAccount {
  XvayAccount({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String? get token => prefs.getString(_tokenKey);
  String? get email => prefs.getString(_emailKey);
  bool get isLoggedIn => (token ?? '').isNotEmpty;

  Future<Map<String, dynamic>> register(String email, String password) {
    return _auth('/api/app/register', email, password);
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return _auth('/api/app/login', email, password);
  }

  Future<void> logout() async {
    final current = token;
    if (current != null && current.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('$kBackendBase/api/app/logout'),
          headers: {'Authorization': 'Bearer $current'},
        );
      } catch (_) {}
    }
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  Future<Map<String, dynamic>> _auth(
    String path,
    String email,
    String password,
  ) async {
    final response = await _client.post(
      Uri.parse('$kBackendBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final payload = _decode(response);
    final data = payload['data'];
    if (data is! Map) {
      throw Exception('登录响应缺少用户信息');
    }
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final sessionToken = data['token'] as String? ?? '';
    await prefs.setString(_tokenKey, sessionToken);
    await prefs.setString(_emailKey, user['email'] as String? ?? email.trim());
    await syncSubscription(user);
    return user;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final payload = jsonDecode(response.body);
    if (payload is! Map) {
      throw Exception('服务器返回了无法识别的内容');
    }
    final body = Map<String, dynamic>.from(payload);
    if (response.statusCode >= 400 || body['ok'] == false) {
      final error = body['error'];
      final message = error is Map ? error['message'] : null;
      throw Exception(message ?? '请求失败 (${response.statusCode})');
    }
    return body;
  }
}

Future<void> syncSubscription(Map<String, dynamic> user) async {
  final url = user['subscriptionUrl'] as String?;
  if (url == null || url.isEmpty) return;
  final name = (user['email'] as String?) ?? 'xvay';
  final remotes = await db.select(db.profileGroupRemote).get();
  ProfileGroupData? existing;
  for (final remote in remotes) {
    if (remote.url == url) {
      existing = await (db.select(db.profileGroup)
            ..where((row) => row.id.equals(remote.profileGroupId)))
          .getSingleOrNull();
      break;
    }
  }
  await updateProfileGroup(
    oldProfileGroup: existing,
    name: name,
    profileGroupType: ProfileGroupType.remote,
    profileGroupRemoteProtocol: ProfileGroupRemoteProtocol.anyportalRest,
    url: url,
    autoUpdateInterval: 86400,
  );
}
