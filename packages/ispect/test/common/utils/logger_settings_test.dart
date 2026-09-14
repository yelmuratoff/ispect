import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/logger_settings.dart';

void main() {
  group('applySettingsToLogger', () {
    late ISpectLogger logger;

    ISpectSettingsState settingsWith(Set<String> disabled) =>
        ISpectSettingsState(
          enabled: true,
          useConsoleLogs: false,
          useHistory: true,
          disabledLogTypes: disabled,
        );

    Set<String?> capturedKeys() => logger.history.map((e) => e.key).toSet();

    setUp(() {
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      addTearDown(logger.dispose);
    });

    test('drops a disabled log type and keeps the rest', () {
      applySettingsToLogger(logger, settingsWith({'riverpod-add'}));

      logger
        ..logData(ISpectLogData('added', key: 'riverpod-add'))
        ..logData(ISpectLogData('changed', key: 'riverpod-update'));

      expect(capturedKeys(), {'riverpod-update'});
    });

    test('keeps capturing log types the settings never listed', () {
      applySettingsToLogger(logger, settingsWith({'riverpod-add'}));

      logger.logData(ISpectLogData('custom event', key: 'my-custom'));

      expect(capturedKeys(), contains('my-custom'));
    });

    test('re-enabling every type clears a previously applied filter', () {
      applySettingsToLogger(logger, settingsWith({'riverpod-add'}));
      applySettingsToLogger(logger, settingsWith(const {}));

      logger.logData(ISpectLogData('added', key: 'riverpod-add'));

      expect(capturedKeys(), {'riverpod-add'});
    });

    test('disabling every displayed type blocks all of them', () {
      final allKeys = ISpectLogType.builtIn.map((e) => e.key).toSet();
      applySettingsToLogger(logger, settingsWith(allKeys));

      logger
        ..logData(ISpectLogData('added', key: 'riverpod-add'))
        ..logData(ISpectLogData('request', key: 'http-request'))
        ..logData(ISpectLogData('info', key: 'info'));

      expect(logger.history, isEmpty);
    });

    test('leaves a host-configured filter alone when nothing is disabled', () {
      final hosted = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
        filter: ISpectFilter(logTypeKeys: const ['info']),
      );
      addTearDown(hosted.dispose);

      applySettingsToLogger(hosted, settingsWith(const {}));

      hosted
        ..logData(ISpectLogData('kept', key: 'info'))
        ..logData(ISpectLogData('dropped', key: 'debug'));

      expect(hosted.history.map((e) => e.key), ['info']);
    });

    test('clears only its own veto once every type is re-enabled', () {
      applySettingsToLogger(logger, settingsWith({'info'}));
      applySettingsToLogger(logger, settingsWith(const {}));

      logger
        ..logData(ISpectLogData('info', key: 'info'))
        ..logData(ISpectLogData('debug', key: 'debug'));

      expect(capturedKeys(), {'info', 'debug'});
    });

    test('carries the diagnostic policy profiles onto the logger', () {
      applySettingsToLogger(
        logger,
        const ISpectSettingsState(
          enabled: true,
          useConsoleLogs: false,
          useHistory: true,
          captureMode: DiagnosticCaptureMode.strict,
          resourceLimits: DiagnosticResourceLimits.constrained,
          processingPolicy: DiagnosticProcessingPolicy.responsive,
        ),
      );

      expect(logger.options.captureMode, DiagnosticCaptureMode.strict);
      expect(
        logger.options.resourceLimits,
        DiagnosticResourceLimits.constrained,
      );
      expect(
        logger.options.processingPolicy,
        DiagnosticProcessingPolicy.responsive,
      );
    });
  });
}
