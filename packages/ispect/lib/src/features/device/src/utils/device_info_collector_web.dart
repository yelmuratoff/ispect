import 'package:web/web.dart' as web;

Future<Map<String, dynamic>> collectPlatformDeviceInfo() async {
  final navigator = web.window.navigator;

  return <String, dynamic>{
    'platform': navigator.platform,
    'userAgent': navigator.userAgent,
    'language': navigator.language,
  };
}
