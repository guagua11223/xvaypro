const _backendOverride = String.fromEnvironment('BACKEND_BASE');

/// 默认走线上接口。本地调试用 --dart-define=BACKEND_BASE=http://127.0.0.1:8787。
String resolveBackendBase() {
  if (_backendOverride.isNotEmpty) return _backendOverride;
  return 'http://47.84.63.205';
}

final String kBackendBase = resolveBackendBase();

const _localHosts = {'127.0.0.1', 'localhost', '10.0.2.2', '0.0.0.0'};

/// 订阅地址如果指到本机，改写到当前接口。
String reachableBackendUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !_localHosts.contains(uri.host)) return url;
  final api = Uri.parse(kBackendBase);
  return uri
      .replace(
        scheme: api.scheme,
        host: api.host,
        port: api.hasPort ? api.port : 80,
      )
      .toString();
}
