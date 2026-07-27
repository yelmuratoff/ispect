import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/models/export_format.dart';

final class _ExportFailure implements Exception {
  const _ExportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class _ThrowingExportFailure implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('EXPORT_TOSTRING_SECRET');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    ISpect.initialize(logger, force: true);
  });

  tearDown(ISpect.dispose);

  Future<String> failWith(
    Object error,
    ExportFormat _, {
    required ExportAction action,
    Set<String>? redactKeys,
  }) =>
      Future<String>.error(error);

  test('snapshots export exceptions without retaining their text', () async {
    final controller = ExportController(
      availableFormats: const [ExportFormat.json],
      onShare: (_) async {},
    );
    addTearDown(controller.dispose);

    await controller.share(
      (format, {required action, redactKeys}) => failWith(
        const _ExportFailure(
          'https://example.test/export?token=EXPORT_FAILURE_SECRET',
        ),
        format,
        action: action,
        redactKeys: redactKeys,
      ),
    );

    final failure = logger.history.last;
    expect(failure.message, isNot(contains('EXPORT_FAILURE_SECRET')));
    expect(failure.message, contains('Exception'));
  });

  test('does not execute an export exception formatter', () async {
    final controller = ExportController(
      availableFormats: const [ExportFormat.json],
      onShare: (_) async {},
    );
    addTearDown(controller.dispose);
    final failure = _ThrowingExportFailure();

    await expectLater(
      controller.share(
        (format, {required action, redactKeys}) => failWith(
          failure,
          format,
          action: action,
          redactKeys: redactKeys,
        ),
      ),
      completes,
    );

    expect(
      logger.history.last.message,
      contains('Exception'),
    );
    expect(
      logger.history.last.message,
      isNot(contains('EXPORT_TOSTRING_SECRET')),
    );
    expect(failure.calls, 0);
  });

  test('bounds generic builder output before file egress', () async {
    final testRoot =
        await Directory.systemTemp.createTemp('ispect_export_controller_');
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => testRoot.path);
    addTearDown(
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProvider, null);
        if (await testRoot.exists()) {
          await testRoot.delete(recursive: true);
        }
      },
    );
    final controller = ExportController(
      availableFormats: const [ExportFormat.json],
    );
    addTearDown(controller.dispose);

    await controller.download(
      (_, {required action, redactKeys}) async => 'a'.padRight(
        LogExportOutput.maxDocumentBytes + 1,
        'a',
      ),
    );

    final content = await File(controller.resultPath).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    expect(decoded['message'], LogExportOutput.truncatedMarker);
    expect(
      LogExportOutput.utf8Length(content),
      lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
    );
  });
}
