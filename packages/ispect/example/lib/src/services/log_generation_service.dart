import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/bloc/counter_bloc.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/riverpod/riverpod_logging.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ws/ws.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

class LogGenerationService {
  final Dio dio;
  final http_interceptor.InterceptedClient client;
  final Dio dummyDio;

  LogGenerationService({
    required this.dio,
    required this.client,
    required this.dummyDio,
  });

  Future<void> generateLogs({
    required int itemCount,
    required bool randomize,
    required int loopDelayMs,
    required bool useAuthHeader,
    required bool httpSendSuccess,
    required bool httpSendErrors,
  }) async {
    final now = DateTime.now().toIso8601String();
    ISpect.logger.good('Demo started at $now');
    ISpect.logger.info('Info: opening Home screen');
    ISpect.logger.debug({'cacheWarmup': true, 'durationMs': 7});
    ISpect.logger.verbose('Verbose log example');
    ISpect.logger.warning('Deprecated API used for demo purposes');
    ISpect.logger.critical('Critical path reached in demo');
    ISpect.logger.provider('Provider: settings updated');
    ISpect.logger.print('Print log example');
    ISpect.logger.route('Route: /demo');
    ISpect.logger.track(
      'Demo analytics',
      analytics: 'demo',
      event: 'open',
      parameters: {'source': 'all-logs', 'time': now},
    );
    ISpect.logger.db(
      source: 'shared_preference',
      operation: 'read',
      key: 'theme',
      value: 'dark',
    );
    ISpect.logger.dbTrace<List<Map<String, Object?>>>(
      source: 'sqflite',
      operation: 'query',
      statement: 'SELECT * FROM users WHERE id = ?',
      args: [3],
      table: 'users',
      run: () => Future<List<Map<String, Object?>>>.delayed(
        const Duration(milliseconds: 5),
        () => [
          {'id': 3, 'name': 'User 3', 'email': 'user3@example.com'},
        ],
      ),
      projectResult: (rows) => rows,
    );

    // Trigger real HTTP request/response and error
    await _triggerHttpLogs(
      randomize: randomize,
      useAuthHeader: useAuthHeader,
      httpSendSuccess: httpSendSuccess,
      httpSendErrors: httpSendErrors,
      now: now,
    );

    // Temporary Bloc
    final tempBloc = CounterBloc();
    tempBloc.add(const Increment());
    tempBloc.add(const Decrement());
    Timer(const Duration(milliseconds: 2), () => tempBloc.close());

    // Riverpod
    await generateRiverpod(itemCount: 1, loopDelayMs: loopDelayMs);
  }

  Future<void> _triggerHttpLogs({
    required bool randomize,
    required bool useAuthHeader,
    required bool httpSendSuccess,
    required bool httpSendErrors,
    required String now,
  }) async {
    final id = (randomize ? (now.hashCode % 10) + 1 : 1);
    final successPath = '/posts/$id';
    final errorPath = '/invalid-endpoint-$id';
    final headers = <String, String>{
      if (useAuthHeader) 'Authorization': 'Bearer demo-token',
    };
    dio.options.headers.addAll(headers);
    if (httpSendSuccess) {
      await dio.get<dynamic>(successPath);
    }
    if (httpSendErrors) {
      await dio.get<dynamic>(errorPath).catchError(
          (e) => Response(requestOptions: RequestOptions(path: errorPath)));
    }
    dio.options.headers.remove('Authorization');
  }

  Future<void> generateRiverpod({
    required int itemCount,
    required int loopDelayMs,
  }) async {
    final container = ProviderContainer(observers: [ISpectRiverpodObserver()]);
    for (int i = 0; i < itemCount; i++) {
      container.read(counterProvider.notifier).state++;
      container.read(counterNotifierProvider.notifier).increment();
      container.read(counterProvider);
      container.read(counterNotifierProvider);
      unawaited(
        container
            .read(failingFutureProvider.future)
            .catchError((e, st) => 'failed'),
      );
      if (loopDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: loopDelayMs));
      }
    }
    container.dispose();
  }

  Future<void> generateHttpRequests({
    required int requestCount,
    required String httpMethod,
    required bool randomize,
    required bool useAuthHeader,
    required bool httpSendSuccess,
    required bool httpSendErrors,
    required int payloadSize,
    required int loopDelayMs,
  }) async {
    for (int i = 0; i < requestCount; i++) {
      final id = (randomize ? (i % 10) + 1 : (i % 10) + 1);
      final successPath = '/posts/$id';
      final errorPath = '/invalid-endpoint-$id';
      final headers = <String, String>{
        if (useAuthHeader) 'Authorization': 'Bearer demo-token',
      };
      dio.options.headers.addAll(headers);

      final data = _mockBody(i, payloadSize);

      await _performHttpRequest(
        method: httpMethod,
        successPath: successPath,
        errorPath: errorPath,
        data: data,
        httpSendSuccess: httpSendSuccess,
        httpSendErrors: httpSendErrors,
      );

      if (loopDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: loopDelayMs));
      }
      dio.options.headers.remove('Authorization');
    }
  }

  Future<void> _performHttpRequest({
    required String method,
    required String successPath,
    required String errorPath,
    required Map<String, dynamic> data,
    required bool httpSendSuccess,
    required bool httpSendErrors,
  }) async {
    switch (method) {
      case 'GET':
        if (httpSendSuccess) await dio.get<dynamic>(successPath);
        if (httpSendErrors) {
          await dio.get<dynamic>(errorPath).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
        }
        break;
      case 'POST':
        if (httpSendSuccess) await dio.post<dynamic>(successPath, data: data);
        if (httpSendErrors) {
          await dio.post<dynamic>(errorPath, data: data).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
        }
        break;
      case 'PUT':
        if (httpSendSuccess) await dio.put<dynamic>(successPath, data: data);
        if (httpSendErrors) {
          await dio.put<dynamic>(errorPath, data: data).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
        }
        break;
      case 'DELETE':
        if (httpSendSuccess) await dio.delete<dynamic>(successPath);
        if (httpSendErrors) {
          await dio.delete<dynamic>(errorPath).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
        }
        break;
    }
  }

  Map<String, dynamic> _mockBody(int i, int payloadSize) {
    final size = payloadSize.clamp(0, 2048);
    final sb = StringBuffer();
    for (int c = 0; c < size; c++) {
      sb.write(String.fromCharCode(97 + (c % 26)));
    }
    return {
      'id': i,
      'payload': sb.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> generateWebSocketActions({
    required int itemCount,
    required int wsMessageSize,
    required bool randomize,
    required int loopDelayMs,
  }) async {
    const url = 'wss://echo.websocket.events';
    final interceptor = ISpectWSInterceptor(logger: ISpect.logger);
    final wsClient = WebSocketClient(
      WebSocketOptions.common(
        connectionRetryInterval: (
          min: const Duration(milliseconds: 500),
          max: const Duration(seconds: 15),
        ),
        interceptors: [interceptor],
      ),
    );
    interceptor.setClient(wsClient);
    await wsClient.connect(url);
    for (int i = 0; i < itemCount; i++) {
      final msg = _buildWsMessage(i, wsMessageSize, randomize);
      wsClient.add(msg);
      if (loopDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: loopDelayMs));
      }
    }
    Timer(const Duration(seconds: 2), () => wsClient.close());
  }

  String _buildWsMessage(int i, int wsMessageSize, bool randomize) {
    final len = wsMessageSize.clamp(1, 512);
    final base = 'Msg#$i-';
    final extraLen = math.max(0, len - base.length);
    final filler = List.generate(
      extraLen,
      (index) =>
          String.fromCharCode(65 + ((randomize ? (i + index) : index) % 26)),
    ).join();
    return '$base$filler';
  }

  Future<void> generateExceptions({
    required int requestCount,
  }) async {
    for (int i = 0; i < requestCount; i++) {
      try {
        throw Exception('Generated exception $i');
      } catch (e, st) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }
  }

  Future<void> generateFileUploads({
    required int requestCount,
  }) async {
    for (int i = 0; i < requestCount; i++) {
      final FormData formData = FormData();
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(
          List.generate(100, (index) => index % 256),
          filename: 'file_$i.txt',
        ),
      ));
      await dummyDio.post<dynamic>(
        '/api/v1/files/upload',
        data: formData,
      );
    }
  }

  Future<void> generateAnalytics({
    required int itemCount,
  }) async {
    for (int i = 0; i < itemCount; i++) {
      ISpect.logger.track(
        'Analytics event $i',
        analytics: 'demo_analytics',
        event: 'demo_event',
        parameters: {
          'item_id': i,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> generateBlocEvents({
    required int itemCount,
    required int loopDelayMs,
    required TestCubit testCubit,
    required CounterBloc counterBloc,
  }) async {
    for (int i = 0; i < itemCount; i++) {
      if (i % 2 == 0) {
        counterBloc.add(const Increment());
      } else {
        counterBloc.add(const Decrement());
      }
      testCubit.load(data: 'Bloc event data $i');
      if (loopDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: loopDelayMs));
      }
    }
  }

  Future<void> generateRoutes({
    required int requestCount,
  }) async {
    for (int i = 0; i < requestCount; i++) {
      ISpect.logger.route('Demo route $i');
    }
  }

  Future<void> generateRiverpodActions({
    required int itemCount,
    required int loopDelayMs,
  }) async {
    await generateRiverpod(itemCount: itemCount, loopDelayMs: loopDelayMs);
  }
}
