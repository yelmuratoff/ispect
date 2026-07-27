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

  logger.db(
    source: 'release-probe',
    operation: 'read',
    statement: 'SELECT 1',
  );

  ISpectDioInterceptor(logger: logger).onRequest(
    RequestOptions(path: 'https://example.invalid/release-probe'),
    RequestInterceptorHandler(),
  );

  final request = http.Request(
    'GET',
    Uri.parse('https://example.invalid/release-probe'),
  );
  unawaited(
    ISpectHttpInterceptor(logger: logger).interceptRequest(request: request),
  );

  WsDiagnostics(logger: logger).onSent(
    'release-probe-frame',
    url: 'wss://example.invalid/release-probe',
    metrics: const <String, Object?>{'latencyMs': 1},
  );

  final bloc = _ProductionSafetyBloc();
  ISpectBlocObserver(logger: logger).onEvent(bloc, 1);
  unawaited(bloc.close());

  final container = ProviderContainer();
  ISpectRiverpodObserver(logger: logger).didAddProvider(
    _productionSafetyProvider,
    1,
    container,
  );
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
