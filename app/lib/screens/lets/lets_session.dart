import 'package:flutter/foundation.dart';

import '../../utils/prefs.dart';
import '../../utils/xvay_account.dart';

/// Shared account snapshot for Lets shell / personal center.
class LetsSession extends ChangeNotifier {
  LetsSession._();
  static final LetsSession instance = LetsSession._();

  final _account = XvayAccount();
  Map<String, dynamic> profile = {};
  Map<String, dynamic> invite = {};
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> orders = [];
  bool loading = false;
  String? error;

  bool get loggedIn => _account.isLoggedIn;
  String get username {
    final name = '${profile['username'] ?? ''}';
    if (name.isNotEmpty) return name;
    return loggedIn ? '飞连用户' : '未登录账户';
  }

  String get userId => '${profile['id'] ?? ''}';

  bool get expired {
    final seconds = profile['remainSeconds'];
    if (seconds is num) return seconds.toInt() <= 0;
    return !loggedIn;
  }

  String get expireText {
    final at = profile['expireAt'];
    if (at is num && at.toInt() > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(at.toInt());
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:$ss';
    }
    return '—';
  }

  int get remainMinutes {
    final seconds = profile['remainSeconds'];
    if (seconds is! num) return 0;
    final m = (seconds.toInt() / 60).floor();
    return m < 0 ? 0 : m;
  }

  int get unreadMessages => announcements.length.clamp(0, 99);

  String get announcementBanner {
    final fromPrefs = prefs.getString('xvay.announcement') ?? '';
    if (fromPrefs.isNotEmpty) return fromPrefs;
    if (announcements.isNotEmpty) {
      return '${announcements.first['title'] ?? ''}';
    }
    return '欢迎使用飞连，线路与套餐由后台统一下发。';
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    if (!_account.isLoggedIn) {
      profile = {};
      invite = {};
      announcements = [];
      services = [];
      packages = [];
      orders = [];
      loading = false;
      notifyListeners();
      return;
    }
    try {
      final results = await Future.wait([
        _account.apiGet('/api/user/profile'),
        _account.apiGet('/api/invite'),
        _account.apiGet('/api/announcements'),
        _account.apiGet('/api/customer-service'),
        _account.apiGet('/api/packages'),
        _account.apiGet('/api/orders'),
      ]);
      profile = results[0];
      invite = results[1];
      announcements = _list(results[2]['announcements']);
      services = _list(results[3]['services']);
      packages = _list(results[4]['packages']);
      orders = _list(results[5]['orders']);
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
