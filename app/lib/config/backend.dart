const String kBackendBase = 'http://47.84.63.205:888';

/// 80 端口在云安全组里没放行，订阅地址如果还写着 80，改走已经开放的 888。
String reachableBackendUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != '47.84.63.205') return url;
  if (uri.scheme == 'http' && (uri.port == 80 || uri.hasPort == false)) {
    return uri.replace(port: 888).toString();
  }
  return url;
}
