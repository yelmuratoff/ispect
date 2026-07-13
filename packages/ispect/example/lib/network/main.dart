import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_http/ispectify_http.dart';

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();
  final dio = Dio()..interceptors.add(ISpectDioInterceptor(logger: logger));
  final client = http_interceptor.InterceptedClient.build(
    interceptors: [ISpectHttpInterceptor(logger: logger)],
  );

  ISpect.run(
    () => runApp(
      buildExampleApp(
        title: 'ISpect network example',
        observer: navigatorObserver,
        home: _NetworkPage(dio: dio, client: client),
      ),
    ),
    logger: logger,
  );
}

final class _NetworkPage extends StatelessWidget {
  const _NetworkPage({required this.dio, required this.client});

  final Dio dio;
  final http_interceptor.InterceptedClient client;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dio and http')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => dio.get<void>('https://example.com'),
                child: const Text('Send a Dio request'),
              ),
              ElevatedButton(
                onPressed: () => client.get(Uri.https('example.com', '/')),
                child: const Text('Send an http request'),
              ),
            ],
          ),
        ),
      );
}
