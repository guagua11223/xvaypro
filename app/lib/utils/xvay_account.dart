import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;

import '../config/backend.dart';
import '../models/core.dart';
import '../models/profile.dart';
import '../models/profile_group.dart';
import 'db.dart';
import 'db/update_profile_group.dart';
import 'logger.dart';
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

  Future<Map<String, dynamic>> me() async {
    final current = token;
    if (current == null || current.isEmpty) {
      throw Exception('尚未登录');
    }
    final response = await _client.get(
      Uri.parse('$kBackendBase/api/app/me'),
      headers: {'Authorization': 'Bearer $current'},
    );
    final payload = _decode(response);
    final data = payload['data'];
    if (data is! Map) {
      throw Exception('账号信息缺少内容');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> connect({int? nodeId, String region = 'auto'}) async {
    final current = token;
    if (current == null || current.isEmpty) {
      throw Exception('尚未登录');
    }
    final body = <String, dynamic>{
      'region': region,
      'deviceId': await deviceId(),
    };
    if (nodeId != null) {
      body['nodeId'] = nodeId;
    }
    final response = await _client.post(
      Uri.parse('$kBackendBase/api/app/connect'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $current',
      },
      body: jsonEncode(body),
    );
    final payload = _decode(response);
    final data = payload['data'];
    if (data is! Map || data['profile'] is! Map) {
      throw Exception('连接响应缺少节点配置');
    }
    final profile = Map<String, dynamic>.from(data['profile'] as Map);
    var keys = data['keys'];
    if (keys is! Map) {
      try {
        keys = await vlessKeys();
      } catch (error) {
        logger.w('vless keys: $error');
      }
    }
    if (keys is Map) {
      applyVlessKeys(profile, Map<String, dynamic>.from(keys));
    }
    await applyConnectProfile(profile);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> vlessKeys() async {
    final current = token;
    if (current == null || current.isEmpty) {
      throw Exception('尚未登录');
    }
    final response = await _client.get(
      Uri.parse('$kBackendBase/api/app/keys'),
      headers: {'Authorization': 'Bearer $current'},
    );
    final payload = _decode(response);
    final data = payload['data'];
    if (data is! Map) {
      throw Exception('密钥响应缺少内容');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> disconnect() async {
    final current = token;
    if (current == null || current.isEmpty) return;
    try {
      await _client.post(
        Uri.parse('$kBackendBase/api/app/disconnect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $current',
        },
        body: jsonEncode({'deviceId': await deviceId()}),
      );
    } catch (error) {
      logger.w('disconnect: $error');
    }
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
    try {
      await bootstrap();
    } catch (error) {
      logger.w('bootstrap: $error');
    }
    return user;
  }

  Future<Map<String, dynamic>> bootstrap() async {
    final current = token;
    if (current == null || current.isEmpty) {
      throw Exception('尚未登录');
    }
    final response = await _client.get(
      Uri.parse('$kBackendBase/api/app/bootstrap'),
      headers: {'Authorization': 'Bearer $current'},
    );
    final payload = _decode(response);
    final data = payload['data'];
    if (data is! Map) {
      throw Exception('缺少套餐和公告');
    }
    final result = Map<String, dynamic>.from(data);
    final settings = result['settings'];
    if (settings is Map) {
      final announcement = settings['announcement'];
      if (announcement is String) {
        await prefs.setString('xvay.announcement', announcement);
      }
      final appName = settings['appName'];
      if (appName is String && appName.isNotEmpty) {
        await prefs.setString('xvay.appName', appName);
      }
    }
    final plans = result['openPlans'];
    if (plans is List) {
      await prefs.setString('xvay.plans', jsonEncode(plans));
    }
    prefs.notifyListeners();
    return result;
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

Future<void> ensureBackendProfile() async {
  final account = XvayAccount();
  try {
    Map<String, dynamic> user;
    if (account.isLoggedIn) {
      try {
        user = await account.me();
      } catch (_) {
        await prefs.remove(_tokenKey);
        user = await _deviceAccount(account);
      }
    } else {
      user = await _deviceAccount(account);
    }
    await syncSubscription(user);
    await account.bootstrap();
  } catch (error) {
    logger.w('ensureBackendProfile: $error');
  }
}

Future<Map<String, dynamic>> _deviceAccount(XvayAccount account) async {
  var email = prefs.getString('xvay.deviceEmail');
  var password = prefs.getString('xvay.devicePassword');
  if (email == null ||
      email.isEmpty ||
      password == null ||
      password.length < 8) {
    final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    email = 'd$id@feilian.app';
    password = 'Fl$id!a8';
    await prefs.setString('xvay.deviceEmail', email);
    await prefs.setString('xvay.devicePassword', password);
  }
  try {
    return await account.login(email, password);
  } catch (_) {
    return account.register(email, password);
  }
}

Future<void> syncSubscription(Map<String, dynamic> user) async {
  final raw = user['subscriptionUrl'] as String?;
  if (raw == null || raw.isEmpty) return;
  final url = reachableBackendUrl(raw);
  final name = (user['email'] as String?) ?? '飞连';
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
  await selectFirstProfile();
}

const _deviceIdKey = 'xvay.deviceId';

Future<String> deviceId() async {
  final saved = prefs.getString(_deviceIdKey);
  if (saved != null && saved.length >= 8) return saved;
  final random = Random.secure();
  final id = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await prefs.setString(_deviceIdKey, id);
  return id;
}

int? nodeIdFromProfileKey(String? key) {
  if (key == null) return null;
  final match = RegExp(r'^n(\d+)-(reality|hysteria2)$').firstMatch(key);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

void applyVlessKeys(Map<String, dynamic> profile, Map<String, dynamic> _) {
  // 手机里的 xray 是 v1.251015.0，只接受 none。写入 mlkem 字符串后核心拒绝加载，
  // 虚拟网卡仍显示已连接，浏览器流量会被整段丢掉。
  const publicKey = 'none';
  final raw = profile['coreConfig'];
  if (raw is! Map) return;
  final config = Map<String, dynamic>.from(raw);
  final outbounds = config['outbounds'];
  if (outbounds is! List) return;
  for (final outbound in outbounds) {
    if (outbound is! Map) continue;
    final settings = outbound['settings'];
    if (settings is! Map) continue;
    final next = settings['vnext'];
    if (next is! List) continue;
    for (final node in next) {
      if (node is! Map) continue;
      final users = node['users'];
      if (users is! List) continue;
      for (final user in users) {
        if (user is Map) user['encryption'] = publicKey;
      }
    }
  }
  profile['coreConfig'] = config;
}

Future<void> applyConnectProfile(Map<String, dynamic> profile) async {
  final name = profile['name'] as String? ?? '飞连';
  final key = profile['key'] as String? ?? name;
  final coreTypeName = profile['coreType'] as String? ?? 'xray';
  final format = profile['format'] as String? ?? 'json';
  final rawConfig = profile['coreConfig'];
  final coreCfg = rawConfig is Map ? jsonEncode(rawConfig) : rawConfig?.toString() ?? '{}';
  final coreTypes = await (db.select(
    db.coreType,
  )..where((row) => row.name.equals(coreTypeName))).get();
  if (coreTypes.isEmpty) {
    throw Exception('当前客户端不能启动 $coreTypeName');
  }
  final coreType = coreTypes.first;
  final matches = await (db.select(
    db.profile,
  )..where((row) => row.key.equals(key))).get();
  final selectedId = prefs.getInt('app.selectedProfileId');
  final existing = matches.where((row) => row.id == selectedId).firstOrNull ??
      matches.firstOrNull;
  final companion = ProfileCompanion(
    name: drift.Value(name),
    key: drift.Value(key),
    coreCfg: drift.Value(coreCfg),
    coreCfgFmt: drift.Value(format),
    updatedAt: drift.Value(DateTime.now()),
    type: const drift.Value(ProfileType.local),
    profileGroupId: drift.Value(existing?.profileGroupId ?? 1),
    coreTypeId: drift.Value(coreType.id),
  );
  final int profileId;
  if (existing == null) {
    profileId = await db.into(db.profile).insert(companion);
  } else {
    profileId = existing.id;
    await (db.update(db.profile)..where((row) => row.id.equals(profileId))).write(
      companion,
    );
  }
  await prefs.setInt('app.selectedProfileId', profileId);
  await prefs.setString('cache.app.selectedProfileName', name);
  prefs.notifyListeners();
}

Future<void> selectFirstProfile() async {
  final selectedId = prefs.getInt('app.selectedProfileId');
  if (selectedId != null) {
    final current = await (db.select(
      db.profile,
    )..where((row) => row.id.equals(selectedId))).getSingleOrNull();
    if (current != null) return;
  }
  final profiles = await db.select(db.profile).get();
  if (profiles.isEmpty) return;
  var chosen = profiles.first;
  for (final profile in profiles) {
    final reality =
        profile.coreTypeId == CoreTypeDefault.xray.index ||
        profile.name.contains('Reality');
    if (reality) {
      chosen = profile;
      break;
    }
  }
  await prefs.setInt('app.selectedProfileId', chosen.id);
  await prefs.setString('cache.app.selectedProfileName', chosen.name);
  prefs.notifyListeners();
}
