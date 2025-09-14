import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/bloc/counter_bloc.dart';
import 'package:ispect_example/src/ui/cards/parameters_card.dart';
import 'package:ispect_example/src/ui/cards/network_card.dart';
import 'package:ispect_example/src/ui/cards/logging_card.dart';
import 'package:ispect_example/src/ui/cards/state_management_card.dart';
import 'package:ispect_example/src/ui/cards/error_card.dart';
import 'package:ispect_example/src/ui/cards/stream_card.dart';
import 'package:ispect_example/src/services/log_generation_service.dart';
import 'package:ispect_example/src/riverpod/demo_settings_provider.dart';
import 'package:ispect_example/src/riverpod/providers.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

final Dio dummyDio = Dio(
  BaseOptions(
    baseUrl: 'https://api.escuelajs.co',
  ),
);

void main() {
  ISpect.run(
    logger: ISpectifyFlutter.init(),
    () => runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('en', 'US'),
      localizationsDelegates: ISpectLocalizations.delegates(delegates: [
        ExampleGeneratedLocalization.delegate,
      ]),
      home: const Home(),
      builder: (context, child) {
        return ISpectBuilder(
          child: child!,
        );
      },
    );
  }
}

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(demoSettingsProvider);
    final logService = ref.watch(logGenerationServiceProvider);
    final testCubit = ref.watch(testCubitProvider);
    final counterBloc = ref.watch(counterBlocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISpect Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParametersCard(
              requestCount: settings.requestCount,
              itemCount: settings.itemCount,
              nestingDepth: settings.nestingDepth,
              payloadSize: settings.payloadSize,
              wsMessageSize: settings.wsMessageSize,
              loopDelayMs: settings.loopDelayMs,
              httpMethod: settings.httpMethod,
              preset: settings.preset,
              useAuthHeader: settings.useAuthHeader,
              randomize: settings.randomize,
              onRequestCountChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateRequestCount(value),
              onItemCountChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateItemCount(value),
              onNestingDepthChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateNestingDepth(value),
              onPayloadSizeChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updatePayloadSize(value),
              onWsMessageSizeChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateWsMessageSize(value),
              onLoopDelayMsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateLoopDelayMs(value),
              onHttpMethodChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateHttpMethod(value),
              onPresetChanged: (value) =>
                  ref.read(demoSettingsProvider.notifier).updatePreset(value),
              onUseAuthHeaderChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateUseAuthHeader(value),
              onRandomizeChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateRandomize(value),
            ),
            const SizedBox(height: 16),
            NetworkCard(
              enableHttp: settings.enableHttp,
              httpSendSuccess: settings.httpSendSuccess,
              httpSendErrors: settings.httpSendErrors,
              enableWs: settings.enableWs,
              enableFileUploads: settings.enableFileUploads,
              onEnableHttpChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableHttp(value),
              onHttpSendSuccessChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateHttpSendSuccess(value),
              onHttpSendErrorsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateHttpSendErrors(value),
              onEnableWsChanged: (value) =>
                  ref.read(demoSettingsProvider.notifier).updateEnableWs(value),
              onEnableFileUploadsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableFileUploads(value),
            ),
            const SizedBox(height: 16),
            LoggingCard(
              enableLogging: settings.enableLogging,
              enableAnalytics: settings.enableAnalytics,
              enableRoutes: settings.enableRoutes,
              onEnableLoggingChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableLogging(value),
              onEnableAnalyticsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableAnalytics(value),
              onEnableRoutesChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableRoutes(value),
            ),
            const SizedBox(height: 16),
            StateManagementCard(
              enableBlocEvents: settings.enableBlocEvents,
              enableRiverpod: settings.enableRiverpod,
              onEnableBlocEventsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableBlocEvents(value),
              onEnableRiverpodChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableRiverpod(value),
            ),
            const SizedBox(height: 16),
            ErrorCard(
              enableExceptions: settings.enableExceptions,
              onEnableExceptionsChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateEnableExceptions(value),
            ),
            const SizedBox(height: 16),
            StreamCard(
              streamMode: settings.streamMode,
              intervalMs: settings.streamIntervalMs,
              onStreamModeChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateStreamMode(value),
              onIntervalChanged: (value) => ref
                  .read(demoSettingsProvider.notifier)
                  .updateStreamIntervalMs(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _executeActions(
                  context, ref, logService, testCubit, counterBloc),
              child: const Text('Execute Actions'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings dialog placeholder'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeActions(
    BuildContext context,
    WidgetRef ref,
    LogGenerationService logService,
    TestCubit testCubit,
    CounterBloc counterBloc,
  ) async {
    final settings = ref.read(demoSettingsProvider);

    if (settings.enableHttp) {
      await logService.generateHttpRequests(
        requestCount: settings.requestCount,
        httpMethod: settings.httpMethod,
        randomize: settings.randomize,
        useAuthHeader: settings.useAuthHeader,
        httpSendSuccess: settings.httpSendSuccess,
        httpSendErrors: settings.httpSendErrors,
        payloadSize: settings.payloadSize,
        loopDelayMs: settings.loopDelayMs,
      );
    }

    if (settings.enableWs) {
      await logService.generateWebSocketActions(
        itemCount: settings.itemCount,
        wsMessageSize: settings.wsMessageSize,
        randomize: settings.randomize,
        loopDelayMs: settings.loopDelayMs,
      );
    }

    if (settings.enableLogging) {
      await logService.generateLogs(
        itemCount: settings.itemCount,
        randomize: settings.randomize,
        loopDelayMs: settings.loopDelayMs,
        useAuthHeader: settings.useAuthHeader,
        httpSendSuccess: settings.httpSendSuccess,
        httpSendErrors: settings.httpSendErrors,
      );
    }

    if (settings.enableExceptions) {
      await logService.generateExceptions(
        requestCount: settings.requestCount,
      );
    }

    if (settings.enableFileUploads) {
      await logService.generateFileUploads(
        requestCount: settings.requestCount,
      );
    }

    if (settings.enableAnalytics) {
      await logService.generateAnalytics(
        itemCount: settings.itemCount,
      );
    }

    if (settings.enableRoutes) {
      await logService.generateRoutes(
        requestCount: settings.requestCount,
      );
    }

    if (settings.enableBlocEvents) {
      await logService.generateBlocEvents(
        itemCount: settings.itemCount,
        loopDelayMs: settings.loopDelayMs,
        testCubit: testCubit,
        counterBloc: counterBloc,
      );
    }

    if (settings.enableRiverpod) {
      await logService.generateRiverpodActions(
        itemCount: settings.itemCount,
        loopDelayMs: settings.loopDelayMs,
      );
    }
  }
}
