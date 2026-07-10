import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/history/flutter_file_log_history_factory.dart';

void main() {
  test('disabled factory does not call the directory provider', () {
    var called = false;

    final history = createFlutterFileLogHistory(
      loggerOptions: ISpectLoggerOptions(),
      fileHistoryOptions: const FileLogHistoryOptions(),
      directoryProvider: () async {
        called = true;
        return '/unused';
      },
    );

    expect(history, isNull);
    expect(called, isFalse);
  });

  test('web factory falls back without calling the directory provider', () {
    var called = false;

    final history = createFlutterFileLogHistory(
      loggerOptions: ISpectLoggerOptions(),
      fileHistoryOptions: const FileLogHistoryOptions(),
      isEnabled: true,
      isWeb: true,
      directoryProvider: () async {
        called = true;
        return '/unused';
      },
    );

    expect(history, isNull);
    expect(called, isFalse);
  });

  test('enabled IO factory creates history without resolving eagerly', () {
    var called = false;

    final history = createFlutterFileLogHistory(
      loggerOptions: ISpectLoggerOptions(),
      fileHistoryOptions: const FileLogHistoryOptions(),
      isEnabled: true,
      isWeb: false,
      directoryProvider: () async {
        called = true;
        return '/unused';
      },
    );

    expect(history, isA<RollingFileLogHistory>());
    expect(called, isFalse);
  });

  test('init rejects custom and first-party history together', () {
    expect(
      () => ISpectFlutter.init(
        history: DefaultISpectLoggerHistory(ISpectLoggerOptions()),
        fileHistory: const FileLogHistoryOptions(),
      ),
      throwsArgumentError,
    );
  });

  test('disabled init keeps file history hidden', () {
    final logger = ISpectFlutter.init(
      fileHistory: const FileLogHistoryOptions(),
    );

    expect(logger.fileLogHistory, isNull);
  });
}
