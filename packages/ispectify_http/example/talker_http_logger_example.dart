import 'package:http_interceptor/http_interceptor.dart';
import '../lib/ispectify_http.dart';

void main(List<String> args) async {
  final client = InterceptedClient.build(interceptors: [
    ISpectifyHttpLogger(),
  ]);

  await client.get("https://google.com".toUri());
}
