import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _Settings extends BaseNetworkInterceptorSettings {
  const _Settings({
    super.enabled,
    super.enableRedaction,
    super.captureMode,
    super.resourceLimits,
    super.printRequestData,
    super.printResponseHeaders,
    super.printErrorMessage,
  });

  @override
  BaseNetworkInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    DiagnosticCaptureMode? captureMode,
    DiagnosticResourceLimits? resourceLimits,
    bool inheritResourceLimits = false,
    bool? logRequests,
    bool? logResponses,
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
  }) =>
      throw UnimplementedError();
}

final class _Interceptor
    with NetworkLoggerMixin, NetworkRedactionMixin, NetworkCapturePolicyMixin {
  _Interceptor(this.logger, this.settings);

  @override
  final ISpectLogger logger;

  @override
  final BaseNetworkInterceptorSettings settings;

  @override
  RedactionService get redactor => ISpectRedaction.service;
}

void main() {
  group('NetworkCapturePolicyMixin', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
          resourceLimits: DiagnosticResourceLimits.extended,
        ),
      );
    });

    test('inherits the logger limits when settings leave them unset', () {
      final interceptor = _Interceptor(logger, const _Settings());

      expect(
        interceptor.resourceLimits,
        same(DiagnosticResourceLimits.extended),
      );
    });

    test('prefers limits set on the settings', () {
      final interceptor = _Interceptor(
        logger,
        const _Settings(resourceLimits: DiagnosticResourceLimits.constrained),
      );

      expect(
        interceptor.resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
    });

    test('reads redaction and capture mode from the settings', () {
      final interceptor = _Interceptor(
        logger,
        const _Settings(
          enableRedaction: false,
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );

      expect(interceptor.enableRedaction, isFalse);
      expect(interceptor.captureMode, DiagnosticCaptureMode.strict);
    });

    test('captures only with an active consumer and enabled settings', () {
      expect(
        _Interceptor(logger, const _Settings()).captureEnabled,
        logger.hasActiveConsumers,
      );
      expect(
        _Interceptor(logger, const _Settings(enabled: false)).captureEnabled,
        isFalse,
      );
    });

    test('trace config skips trace redaction and keeps the resolved limits',
        () {
      final config = _Interceptor(
        logger,
        const _Settings(resourceLimits: DiagnosticResourceLimits.constrained),
      ).capturedTraceConfig;

      expect(config.redact, isFalse);
      expect(config.resourceLimits, same(DiagnosticResourceLimits.constrained));
    });
  });

  group('render hints', () {
    const settings = _Settings(
      printRequestData: false,
      printResponseHeaders: false,
      printErrorMessage: false,
    );

    test('request hints carry body and headers only', () {
      expect(settings.requestRenderHints, {
        NetworkLogRenderer.hintPrintBody: false,
        NetworkLogRenderer.hintPrintHeaders: true,
      });
    });

    test('response hints follow the response toggles', () {
      expect(settings.responseRenderHints, {
        NetworkLogRenderer.hintPrintBody: true,
        NetworkLogRenderer.hintPrintHeaders: false,
        NetworkLogRenderer.hintPrintMessage: true,
      });
    });

    test('error hints follow the error toggles', () {
      expect(settings.errorRenderHints, {
        NetworkLogRenderer.hintPrintBody: true,
        NetworkLogRenderer.hintPrintHeaders: true,
        NetworkLogRenderer.hintPrintMessage: false,
      });
    });

    test('hintsFor omits unset hints', () {
      expect(
        NetworkLogRenderer.hintsFor(printBody: true),
        {NetworkLogRenderer.hintPrintBody: true},
      );
    });
  });
}
