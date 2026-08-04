import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectWSInterceptorSettings', () {
    test('defaults to full redacted frame diagnostics', () {
      const settings = ISpectWSInterceptorSettings();

      expect(settings.enableRedaction, isTrue);
      expect(settings.captureMode, DiagnosticCaptureMode.balanced);
      expect(
        settings.printSentData,
        NetworkInterceptorDefaults.printRequestData,
      );
      expect(
        settings.printReceivedData,
        NetworkInterceptorDefaults.printResponseData,
      );
      expect(
        settings.printStateData,
        ISpectWSInterceptorDefaults.printStateData,
      );
      expect(
        settings.printErrorData,
        NetworkInterceptorDefaults.printErrorData,
      );
      expect(
        settings.printSentHeaders,
        NetworkInterceptorDefaults.printRequestHeaders,
      );
      expect(
        settings.printReceivedHeaders,
        NetworkInterceptorDefaults.printResponseHeaders,
      );
      expect(
        settings.printErrorHeaders,
        ISpectWSInterceptorDefaults.printErrorHeaders,
      );

      final built = ISpectWSInterceptorSettingsBuilder().build();
      expect(built.printStateData, settings.printStateData);
      expect(built.printErrorHeaders, settings.printErrorHeaders);
    });

    test('copyWith exposes and preserves frame capture controls', () {
      const original = ISpectWSInterceptorSettings(logRequests: false);

      final updated = original.copyWith(logResponses: false);

      expect(updated.logRequests, isFalse);
      expect(updated.logResponses, isFalse);
    });

    test('builder exposes frame capture controls', () {
      final settings = ISpectWSInterceptorSettingsBuilder()
          .withoutRequests()
          .withoutResponses()
          .build();

      expect(settings.logRequests, isFalse);
      expect(settings.logResponses, isFalse);
    });

    test('resource limits support direct, copied, and builder overrides', () {
      const direct = ISpectWSInterceptorSettings(
        resourceLimits: DiagnosticResourceLimits.constrained,
      );
      final copied = direct.copyWith(
        resourceLimits: DiagnosticResourceLimits.extended,
      );
      final built = ISpectWSInterceptorSettingsBuilder()
          .withResourceLimits(DiagnosticResourceLimits.constrained)
          .build();

      expect(direct.resourceLimits, same(DiagnosticResourceLimits.constrained));
      expect(copied.resourceLimits, same(DiagnosticResourceLimits.extended));
      expect(built.resourceLimits, same(DiagnosticResourceLimits.constrained));
      expect(
        direct
            .copyWith(
              resourceLimits: DiagnosticResourceLimits.extended,
              inheritResourceLimits: true,
            )
            .resourceLimits,
        isNull,
      );
    });

    test('builder can omit every optional payload field', () {
      final settings = ISpectWSInterceptorSettingsBuilder()
          .withoutRequestData()
          .withoutRequestHeaders()
          .withoutResponseData()
          .withoutResponseHeaders()
          .withoutResponseMessage()
          .withoutErrorData()
          .withoutErrorMessage()
          .build();

      expect(settings.printSentData, isFalse);
      expect(settings.printSentHeaders, isFalse);
      expect(settings.printReceivedData, isFalse);
      expect(settings.printReceivedHeaders, isFalse);
      expect(settings.printReceivedMessage, isFalse);
      expect(settings.printErrorData, isFalse);
      expect(settings.printErrorMessage, isFalse);
    });

    test('presets apply the intended frame capture policy', () {
      final development =
          ISpectWSInterceptorSettingsBuilder.development().build();
      final staging = ISpectWSInterceptorSettingsBuilder.staging().build();
      final production =
          ISpectWSInterceptorSettingsBuilder.production().build();
      final metadataOnly =
          ISpectWSInterceptorSettingsBuilder.metadataOnly().build();

      expect(development.logRequests, isTrue);
      expect(development.logResponses, isTrue);
      expect(development.printSentData, isTrue);
      expect(development.printReceivedData, isTrue);
      expect(development.printStateData, isTrue);
      expect(development.printErrorData, isTrue);
      expect(development.printSentHeaders, isTrue);
      expect(development.printReceivedHeaders, isTrue);
      expect(development.printErrorHeaders, isFalse);
      expect(development.captureMode, DiagnosticCaptureMode.balanced);
      expect(staging.logRequests, isTrue);
      expect(staging.logResponses, isFalse);
      expect(staging.printStateData, isFalse);
      expect(production.logRequests, isFalse);
      expect(production.logResponses, isFalse);
      expect(production.printStateData, isFalse);
      expect(production.captureMode, DiagnosticCaptureMode.strict);
      expect(metadataOnly.logRequests, isTrue);
      expect(metadataOnly.logResponses, isTrue);
      expect(metadataOnly.printSentData, isFalse);
      expect(metadataOnly.printReceivedData, isFalse);
      expect(metadataOnly.printSentHeaders, isFalse);
      expect(metadataOnly.printReceivedHeaders, isFalse);
      expect(metadataOnly.printStateData, isFalse);
      expect(metadataOnly.printErrorData, isFalse);
      expect(metadataOnly.captureMode, DiagnosticCaptureMode.strict);
    });
  });
}
