@TestOn('vm')
library;

import 'dart:async';
import 'dart:isolate';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/ispectify_isolate.dart';
import 'package:test/test.dart';

Future<void> _failingUploadJob(SendPort sendPort) async {
  final logger = ISpectLogger(
    options: ISpectLoggerOptions(useConsoleLogs: false),
  )
    ..addObserver(ISpectIsolateLogForwarder(sendPort))
    ..error(
      'upload job failed',
      additionalData: {'job': 'upload-42', 'password': 'hunter2'},
    );
  await logger.dispose();
}

void main() {
  group(
    'ISpect isolate log bridge',
    () {
      late ISpectLogger mainLogger;
      late ISpectIsolateLogReceiver receiver;

      setUp(() {
        mainLogger = ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        );
        receiver = ISpectIsolateLogReceiver.open(mainLogger)!;
      });
      tearDown(() async {
        receiver.close();
        await mainLogger.dispose();
      });

      Future<ISpectLogData> nextLog() =>
          mainLogger.stream.first.timeout(const Duration(seconds: 5));

      test('a log from a background isolate reaches the main logger', () async {
        final received = nextLog();

        await Isolate.spawn(_failingUploadJob, receiver.sendPort);

        final log = await received;
        expect(log.message, 'upload job failed');
        expect(log.logLevel, LogLevel.error);
        expect(log.isError, isTrue);
        expect(log.additionalData?['job'], 'upload-42');
        expect(log.additionalData?['password'], isNot('hunter2'));
      });

      test('the forwarder masks secrets before they cross the boundary',
          () async {
        final port = ReceivePort();
        addTearDown(port.close);

        ISpectIsolateLogForwarder(port.sendPort).onError(
          ISpectLogData(
            'upload job failed',
            logLevel: LogLevel.error,
            additionalData: const {'password': 'hunter2'},
          ),
        );

        final sent = await port.first.timeout(const Duration(seconds: 5));
        expect(sent, isA<String>());
        expect(sent, contains('upload job failed'));
        expect(sent, isNot(contains('hunter2')));
      });

      Future<ISpectLogData> logNamed(String message) => mainLogger.stream
          .firstWhere((log) => log.message == message)
          .timeout(const Duration(seconds: 5));

      test('messages that are not log records are dropped with a warning',
          () async {
        final real = logNamed('real');
        receiver.sendPort
          ..send(42)
          ..send('not json')
          ..send('[1, 2]')
          ..send('{"message": "real", "time": "2026-03-02T09:00:00"}');
        await real;

        expect(mainLogger.history.map((l) => l.message), [
          'ISpect isolate bridge dropped a non-text message',
          'ISpect isolate bridge dropped an unreadable log',
          'ISpect isolate bridge dropped an unreadable log',
          'real',
        ]);
        expect(
          mainLogger.history.take(3).map((l) => l.logLevel),
          everyElement(LogLevel.warning),
        );
      });

      test('a message over maxImportCharacters is dropped with a warning',
          () async {
        final small = ISpectIsolateLogReceiver.open(
          mainLogger,
          resourceLimits: const DiagnosticResourceLimits(
            maxImportCharacters: 64,
          ),
        )!;
        addTearDown(small.close);
        final warning = logNamed(
          'ISpect isolate bridge dropped a log over maxImportCharacters',
        );

        small.sendPort.send(
          '{"message": "${'x' * 100}", "time": "2026-03-02T09:00:00"}',
        );

        expect((await warning).logLevel, LogLevel.warning);
        expect(
          mainLogger.history.where((l) => l.message!.startsWith('xxx')),
          isEmpty,
        );
      });

      test('a closed receiver drops what is sent afterwards', () async {
        final other = ISpectIsolateLogReceiver.open(mainLogger)!;
        addTearDown(other.close);
        final closedPort = receiver.sendPort;
        receiver.close();
        final marker = logNamed('marker');

        closedPort.send('{"message": "late", "time": "2026-03-02T09:00:00"}');
        other.sendPort
            .send('{"message": "marker", "time": "2026-03-02T09:00:01"}');
        await marker;

        expect(mainLogger.history.map((l) => l.message), ['marker']);
      });
    },
    skip: !kISpectEnabled,
  );
}
