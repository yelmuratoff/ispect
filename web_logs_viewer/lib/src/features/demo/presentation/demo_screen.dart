import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ispect/ispect.dart';

import 'package:ispectify_dio/ispectify_dio.dart';

import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:web_logs_viewer/src/core/localization/generated/app_localizations.dart';
import 'package:web_logs_viewer/src/core/services/theme_manager.dart';
import 'package:web_logs_viewer/src/core/utils/load_file_example.dart';
import 'package:web_logs_viewer/src/features/demo/bloc/test_bloc.dart';
import 'package:ws/ws.dart';

final Dio dio = Dio(
  BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
);

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

final Dio dummyDio = Dio(BaseOptions(baseUrl: 'https://api.escuelajs.co'));

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => DemoScreenState();
}

typedef _ButtonConfig = ({String label, VoidCallback onPressed});

class DemoScreenState extends State<DemoScreen> {
  final TestBloc _testBloc = TestBloc();

  @override
  void dispose() {
    _testBloc.close();
    super.dispose();
  }

  List<_ButtonConfig> _buildButtonConfigs(
    BuildContext context,
    ISpectScopeModel iSpect,
  ) {
    return <_ButtonConfig>[
      (
        label: 'All logs',
        onPressed: () {
          ISpect.logger.critical('critical');
          ISpect.logger.debug('debug');
          ISpect.logger.error('error');
          ISpect.logger.good('good');
          ISpect.logger.handle(
            exception: Exception('exception'),
            stackTrace: StackTrace.current,
          );
          ISpect.logger.info('info');
          ISpect.logger.log('log');
          ISpect.logger.print('print');
          ISpect.logger.route('route');
          ISpect.logger.track('track');
          ISpect.logger.verbose('verbose');
          ISpect.logger.warning('warning');
        },
      ),
      (
        label: 'Show modal bottom sheet',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            builder: (context) => SizedBox(
              height: 300,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ),
            ),
          );
        },
      ),
      (
        label: 'Mock Nested Map with Depth IDs',
        onPressed: () {
          const int depth = 5000;
          Map<String, dynamic> nested = {'id': depth, 'value': 'Item $depth'};

          for (int i = depth - 1; i >= 0; i--) {
            nested = {'id': i, 'value': 'Item $i', 'nested': nested};
          }

          final Response<dynamic> response = Response(
            requestOptions: RequestOptions(path: '/mock-nested-id'),
            data: nested,
            statusCode: 200,
          );
          for (final Interceptor interceptor in dio.interceptors) {
            if (interceptor is ISpectDioInterceptor) {
              interceptor.onResponse(response, ResponseInterceptorHandler());
            }
          }
        },
      ),
      (
        label: 'Mock Nested List with Depth IDs',
        onPressed: () {
          const int depth = 10000;

          Map<String, dynamic> nested = {'id': depth, 'value': 'Item $depth'};

          for (int i = depth - 1; i >= 0; i--) {
            nested = {'id': i, 'value': 'Item $i', 'nested': nested};
          }

          final List<Map<String, dynamic>> largeList = List.generate(
            10000,
            (index) => {'id': index, 'value': 'Item $index'},
          );

          final Response<dynamic> response = Response(
            requestOptions: RequestOptions(path: '/mock-nested-id'),
            data: largeList,
            statusCode: 200,
          );

          for (final Interceptor interceptor in dio.interceptors) {
            if (interceptor is ISpectDioInterceptor) {
              interceptor.onResponse(response, ResponseInterceptorHandler());
            }
          }
        },
      ),
      (
        label: 'Connect to WebSocket',
        onPressed: () {
          // Using a non-existent WebSocket URL to trigger a connection error.
          const url = String.fromEnvironment(
            'URL',
            defaultValue: 'wss://echo.plugfox.dev:443/non-existent-path',
          );

          final interceptor = ISpectWSInterceptor(logger: ISpect.logger);

          final client = WebSocketClient(
            WebSocketOptions.common(
              connectionRetryInterval: (
                min: const Duration(milliseconds: 500),
                max: const Duration(seconds: 15),
              ),
              interceptors: [interceptor],
            ),
          );

          interceptor.setClient(client);

          client
            ..connect(url)
            ..add('Hello')
            ..add('world!');

          // Adding a client-side error by trying to send data after closing the connection.
          Timer(const Duration(seconds: 1), () async {
            await client.close();
            try {
              unawaited(client.add('This will fail'));
            } catch (e) {
              // This error will be caught by the interceptor.
            }
            ISpect.logger.info('Metrics:\n${client.metrics}');
            client.close();
          });
        },
      ),
      (
        label: 'Mock Large JSON Response',
        onPressed: () {
          final List<Map<String, dynamic>> largeList = List.generate(
            10000,
            (index) => {'id': index, 'value': 'Item $index'},
          );
          ISpect.logger.print(largeList.toString());
        },
      ),
      (
        label: 'Test Cubit',
        onPressed: () {
          _testBloc.load(data: 'Test data');
        },
      ),
      (
        label: 'All Bloc logs',
        onPressed: () async {
          final testCubit = TestBloc();
          testCubit.load(data: 'Test data');
          testCubit.loadWithError();
          await Future<void>.delayed(const Duration(seconds: 2));
          testCubit.close();
        },
      ),
      (
        label: 'Get last log',
        onPressed: () async {
          final lastLog = ISpect.logger.history.last;
          ISpect.logger.info('Last log: ${lastLog.toJson()}');
        },
      ),
      (
        label: 'Get first log',
        onPressed: () async {
          final firstLog = ISpect.logger.history.first;
          ISpect.logger.info('Last log: ${firstLog.toJson()}');
        },
      ),
      (
        label: 'Send HTTP request (http package)',
        onPressed: () async {
          await client.get(
            Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
          );
        },
      ),
      (
        label: 'Send error HTTP request (http package)',
        onPressed: () async {
          await client.get(
            Uri.parse('https://jsonplaceholder.typicode.com/po2323sts/1'),
          );
        },
      ),
      (
        label: 'Toggle theme',
        onPressed: () {
          ThemeProvider.toggleTheme(context);
        },
      ),
      (
        label: 'Toggle ISpect',
        onPressed: () {
          ISpect.logger.track(
            'Toggle',
            analytics: 'amplitude',
            event: 'ISpect',
            parameters: {'isISpectEnabled': iSpect.isISpectEnabled},
          );
          iSpect.toggleISpect();
        },
      ),
      (
        label: 'Send HTTP request',
        onPressed: () {
          dio.get<dynamic>('/posts/1');
        },
      ),
      (
        label: 'Send HTTP request with error',
        onPressed: () {
          dio.get<dynamic>('/post3s/1');
        },
      ),
      (
        label: 'Send HTTP request with Token',
        onPressed: () {
          dio.options.headers.addAll({
            'Authorization': '27349dnkwdjwidj4u49280dkdfjwdjw',
          });
          dio.get<dynamic>('/posts/1');
          dio.options.headers.remove('Authorization');
        },
      ),
      (
        label: 'Send HTTP request with Token (http)',
        onPressed: () async {
          await client.get(
            Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
            headers: {'Authorization': '27349dnkwdjwidj4u49280dkdfjwdjw'},
          );
        },
      ),
      (
        label: 'Upload file to dummy server',
        onPressed: () {
          final FormData formData = FormData();
          formData.files.add(
            MapEntry(
              'file',
              MultipartFile.fromBytes([1, 2, 3], filename: 'file.txt'),
            ),
          );

          dummyDio.post<dynamic>('/api/v1/files/upload', data: formData);
        },
      ),
      (
        label: 'Upload file to dummy server (http)',
        onPressed: () {
          final List<int> bytes = [1, 2, 3]; // File data as bytes
          const String filename = 'file.txt';

          final http_interceptor.MultipartRequest request =
              http_interceptor.MultipartRequest(
                'POST',
                Uri.parse('https://api.escuelajs.co/api/v1/files/upload'),
              );

          request.files.add(
            http_interceptor.MultipartFile.fromBytes(
              'file', // Field name
              bytes,
              filename: filename,
            ),
          );

          client.send(request);
        },
      ),
      (
        label: 'Throw exception',
        onPressed: () {
          throw Exception('Test exception');
        },
      ),

      (
        label: 'Log 10000 items',
        onPressed: () {
          for (int i = 0; i < 10000; i++) {
            ISpect.logger.info('Item $i');
          }
        },
      ),
      (
        label: 'Logs File',
        onPressed: () async {
          await LogsFileExample.createAndHandleLogsFile();
          await LogsFileExample.createMultipleLogsFiles();
          await LogsFileExample.demonstrateCleanup();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ISpectScopeModel iSpect = ISpect.read(context);
    final List<_ButtonConfig> buttonConfigs = _buildButtonConfigs(
      context,
      iSpect,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(ExampleGeneratedLocalization.of(context)!.app_title),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttonConfigs.expand((config) {
              final Widget button = FilledButton(
                onPressed: config.onPressed,
                child: Text(config.label),
              );
              if (config.label == 'Test Cubit') {
                return [
                  BlocBuilder<TestBloc, TestState>(
                    bloc: _testBloc,
                    builder: (context, state) => FilledButton(
                      onPressed: config.onPressed,
                      child: Text(config.label),
                    ),
                  ),
                  const SizedBox(height: 10),
                ];
              }
              return [button, const SizedBox(height: 10)];
            }).toList()..removeLast(),
          ),
        ),
      ),
    );
  }
}
