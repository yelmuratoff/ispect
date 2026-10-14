import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ispect/ispect.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

final _productionSafetyProvider = Provider<int>(
  (ref) => 1,
  name: 'production-safety-provider',
);

void main() {
  _exerciseDiagnosticsApis();
  ISpect.run(
    () => runApp(const _ProductionSafetyProbe()),
  );
}

void _exerciseDiagnosticsApis() {
  final logger = ISpectLogger(
    options: ISpectLoggerOptions(
      useConsoleLogs: false,
      maxHistoryItems: 20,
    ),
  );

  logger
    ..db(
      source: 'release-probe',
      operation: 'read',
      statement: 'SELECT 1',
    )
    ..dbEnd(logger.dbStart(source: 'release-probe', statement: 'SELECT 2'));
  unawaited(
    logger.dbTransaction(
      run: () => logger.dbTrace(
        source: 'release-probe',
        operation: 'write',
        statement: 'UPDATE t SET a = 1',
        run: () async => 1,
      ),
    ),
  );

  final options = RequestOptions(path: 'https://example.invalid/release-probe');
  ISpectDioInterceptor(logger: logger)
    ..onRequest(options, RequestInterceptorHandler())
    ..onResponse(
      Response<Object?>(requestOptions: options, statusCode: 200),
      ResponseInterceptorHandler(),
    )
    ..onError(
      DioException(requestOptions: options),
      ErrorInterceptorHandler(),
    );

  final request = http.Request(
    'GET',
    Uri.parse('https://example.invalid/release-probe'),
  );
  final httpInterceptor = ISpectHttpInterceptor(logger: logger);
  unawaited(httpInterceptor.interceptRequest(request: request));
  unawaited(
    httpInterceptor.interceptResponse(
      response: http.StreamedResponse(
        Stream.value(const [1]),
        200,
        contentLength: 1,
        request: request,
      ),
    ),
  );

  const wsUrl = 'wss://example.invalid/release-probe';
  WsDiagnostics(logger: logger)
    ..newConnection()
    ..onStateChanged(WsConnectionState.open, url: wsUrl)
    ..onSent(
      'release-probe-frame',
      url: wsUrl,
      metrics: const <String, Object?>{'latencyMs': 1},
    )
    ..onReceived('release-probe-frame', url: wsUrl)
    ..onError(StateError('release-probe'), StackTrace.empty, url: wsUrl);

  final bloc = _ProductionSafetyBloc();
  ISpectBlocObserver(logger: logger)
    ..onCreate(bloc)
    ..onEvent(bloc, 1)
    ..onTransition(
      bloc,
      const Transition(currentState: 0, event: 1, nextState: 1),
    )
    ..onChange(bloc, const Change(currentState: 0, nextState: 1))
    ..onError(bloc, StateError('release-probe'), StackTrace.empty)
    ..onDone(bloc, 1)
    ..onClose(bloc);
  unawaited(bloc.close());

  final container = ProviderContainer();
  ISpectRiverpodObserver(logger: logger)
    ..didAddProvider(_productionSafetyProvider, 1, container)
    ..didUpdateProvider(_productionSafetyProvider, 1, 2, container)
    ..providerDidFail(
      _productionSafetyProvider,
      StateError('release-probe'),
      StackTrace.empty,
      container,
    )
    ..didDisposeProvider(_productionSafetyProvider, container);
  container.dispose();
}

final class _ProductionSafetyBloc extends Bloc<int, int> {
  _ProductionSafetyBloc() : super(0);
}

final class _ProductionSafetyProbe extends StatelessWidget {
  const _ProductionSafetyProbe();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SizedBox.shrink(),
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        final diagnostics = ISpectBuilder.wrap(child: app);
        return Inspector(
          isEnabled: true,
          child: diagnostics,
        );
      },
    );
  }
}
