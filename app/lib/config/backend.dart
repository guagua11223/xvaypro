const String kBackendBase = 'http://47.84.63.205';

const _localHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};

/// 订阅地址如果指到本机，改写到线上接口。
String reachableBackendUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !_localHosts.contains(uri.host)) return url;
  return uri
      .replace(scheme: 'http', host: '47.84.63.205', port: 80)
      .toString();
}
