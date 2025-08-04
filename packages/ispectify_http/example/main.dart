import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify_http/ispectify_http.dart';

void main(List<String> args) async {
  final client = InterceptedClient.build(
    interceptors: [
      ISpectHttpInterceptor(),
    ],
  );

  await client.get('https://google.com'.toUri());
}
