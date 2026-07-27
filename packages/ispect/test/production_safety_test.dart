// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/observers/transition.dart';

final class _ProductionSafetyPlugin extends InspectorPlugin {
  int initCalls = 0;

  @override
  String get id => 'production-safety';

  @override
  String get title => 'Production safety';

  @override
  IconData get icon => Icons.security;

  @override
  Widget buildScreen(BuildContext context) => const SizedBox.shrink();

  @override
  void onInit() {
    initCalls++;
  }
}

final class _ProductionSafetySender implements NetworkRequestSender {
  @override
  String get id => 'production-safety';

  @override
  String get label => 'Production safety';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

final class _TrackingBaseLogger extends ISpectBaseLogger {
  int copyCalls = 0;

  @override
  ISpectBaseLogger copyWith({
    ConsoleSettings? settings,
    ILoggerFormatter? formatter,
    ILoggerFilter? filter,
    LoggerOutput? output,
  }) {
    copyCalls++;
    return super.copyWith(
      settings: settings,
      formatter: formatter,
      filter: filter,
      output: output,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'direct Flutter initialization and builder stay inert without the flag',
    (tester) async {
      expect(kISpectEnabled, isFalse);
      addTearDown(ISpect.dispose);

      final baseLogger = _TrackingBaseLogger();
      final directLogger = ISpectFlutter.init(
        logger: baseLogger,
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
        ),
        fileHistory: const FileLogHistoryOptions(),
      );
      addTearDown(directLogger.dispose);
      directLogger.info('synthetic direct Flutter diagnostic');

      final plugin = _ProductionSafetyPlugin();
      final originalErrorBuilder = ErrorWidget.builder;
      await tester.pumpWidget(
        MaterialApp(
          home: ISpectBuilder(
            options: ISpectOptions(
              plugins: [plugin],
              initialSettings: const ISpectSettingsState(
                enabled: true,
                useConsoleLogs: false,
                useHistory: true,
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      ISpect.logger.info('synthetic builder diagnostic');
      ISpect.registerSender(_ProductionSafetySender());
      var routeCallbackCount = 0;
      final routeObserver = ISpectNavigatorObserver(
        isLogGestures: true,
        onPush: (_, __) => routeCallbackCount++,
        onReplace: ({newRoute, oldRoute}) => routeCallbackCount++,
        onPop: (_, __) => routeCallbackCount++,
        onRemove: (_, __) => routeCallbackCount++,
        onStartUserGesture: (_, __) => routeCallbackCount++,
        onStopUserGesture: () => routeCallbackCount++,
      )..addTransition(
          RouteTransition(
            id: 'synthetic-transition',
            from: null,
            to: null,
            type: TransitionType.push,
            timestamp: DateTime(2026),
            arguments: const {'token': 'synthetic-route-secret'},
          ),
        );
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: '/production-safety',
          arguments: {'token': 'synthetic-route-secret'},
        ),
        builder: (_) => const SizedBox.shrink(),
      );
      routeObserver
        ..didPush(route, null)
        ..didReplace(newRoute: route)
        ..didPop(route, null)
        ..didRemove(route, null)
        ..didStartUserGesture(route, null)
        ..didStopUserGesture();

      expect(directLogger.options.enabled, isFalse);
      expect(directLogger.history, isEmpty);
      expect(directLogger.fileLogHistory, isNull);
      expect(baseLogger.copyCalls, 0);
      expect(plugin.initCalls, 0);
      expect(ErrorWidget.builder, same(originalErrorBuilder));
      expect(ISpect.logger.options.enabled, isFalse);
      expect(ISpect.logger.history, isEmpty);
      expect(ISpect.senders, isEmpty);
      expect(routeCallbackCount, 0);
      expect(routeObserver.transitions, isEmpty);
      expect(
        ISpectNavigatorObserver.observers(observer: routeObserver),
        isEmpty,
      );
      expect(ISpectNavigatorObserver.current, isNull);
    },
    skip: kISpectEnabled,
  );

  test(
    'disabled initialization creates no native share-cleanup state',
    () async {
      final cache =
          await Directory.systemTemp.createTemp('ispect_disabled_cleanup_');
      addTearDown(() async {
        await ISpect.dispose();
        if (await cache.exists()) await cache.delete(recursive: true);
      });
      var pathProviderCalls = 0;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        pathProviderCalls++;
        return cache.path;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final lazyLogger = ISpect.logger;
      expect(ISpect.initialize(lazyLogger), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final shareRoot = Directory(
        '${cache.path}${Platform.pathSeparator}ispect_share',
      );
      expect(pathProviderCalls, 0);
      expect(
        await FileSystemEntity.type(shareRoot.path, followLinks: false),
        FileSystemEntityType.notFound,
      );
    },
    skip: kISpectEnabled,
  );

  test(
    'disabled run leaves the host redaction policy untouched',
    () {
      final hostService = RedactionService(
        sensitiveKeys: const {'host_field'},
        placeholder: '<host>',
      );
      final ignoredService = RedactionService(
        sensitiveKeys: const {'ignored_field'},
        placeholder: '<ignored>',
      );
      ISpectRedaction.configure(enabled: true, service: hostService);
      addTearDown(ISpectRedaction.reset);
      var callbackCalls = 0;

      ISpect.run(
        () => callbackCalls++,
        redactionEnabled: false,
        redactionService: ignoredService,
      );

      expect(callbackCalls, 1);
      expect(ISpectRedaction.enabled, isTrue);
      expect(ISpectRedaction.service, same(hostService));
    },
    skip: kISpectEnabled,
  );
}
