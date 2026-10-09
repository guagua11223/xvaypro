const _backendOverride = String.fromEnvironment('BACKEND_BASE');

/// 真机通过 adb reverse 把手机上的 127.0.0.1:8787 转到本机 houduan。
/// 模拟器请用 --dart-define=BACKEND_BASE=http://10.0.2.2:8787。
String resolveBackendBase() {
  if (_backendOverride.isNotEmpty) return _backendOverride;
  return 'http://127.0.0.1:8787';
}

final String kBackendBase = resolveBackendBase();

/// 订阅地址如果指向本机回环或未放行的 80 端口，改成手机实际能访问的地址。
String reachableBackendUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.host == '47.84.63.205' &&
      uri.scheme == 'http' &&
      (uri.port == 80 || !uri.hasPort)) {
    return uri.replace(port: 888).toString();
  }
  const loopback = {'127.0.0.1', 'localhost', '10.0.2.2', '0.0.0.0'};
  if (loopback.contains(uri.host)) {
    final api = Uri.parse(kBackendBase);
    return uri
        .replace(scheme: api.scheme, host: api.host, port: api.port)
        .toString();
  }
  return url;
}
