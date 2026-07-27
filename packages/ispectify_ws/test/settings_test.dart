import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectWSInterceptorSettings', () {
    test('defaults to full redacted frame diagnostics', () {
      const settings = ISpectWSInterceptorSettings();

      expect(settings.enableRedaction, isTrue);
      expect(settings.printSentData, isTrue);
      expect(settings.printReceivedData, isTrue);
      expect(settings.printStateData, isTrue);
      expect(settings.printErrorData, isTrue);
      expect(settings.printSentHeaders, isTrue);
      expect(settings.printReceivedHeaders, isTrue);
      expect(settings.printErrorHeaders, isFalse);
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
      expect(staging.logRequests, isTrue);
      expect(staging.logResponses, isFalse);
      expect(staging.printStateData, isFalse);
      expect(production.logRequests, isFalse);
      expect(production.logResponses, isFalse);
      expect(production.printStateData, isFalse);
      expect(metadataOnly.logRequests, isTrue);
      expect(metadataOnly.logResponses, isTrue);
      expect(metadataOnly.printSentData, isFalse);
      expect(metadataOnly.printReceivedData, isFalse);
      expect(metadataOnly.printSentHeaders, isFalse);
      expect(metadataOnly.printReceivedHeaders, isFalse);
      expect(metadataOnly.printStateData, isFalse);
      expect(metadataOnly.printErrorData, isFalse);
    });
  });
}
