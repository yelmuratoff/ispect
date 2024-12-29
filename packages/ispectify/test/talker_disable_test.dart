import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  final iSpectify = ISpectiy(settings: ISpectifyOptions(useConsoleLogs: false));
  setUp(() {
    iSpectify.clearHistory();
  });

  group('Talker_toggle_enabled', () {
    group(
      'history',
      () {
        test('disable', () {
          iSpectify.disable();
          iSpectify.error('Test disabled log');

          expect(iSpectify.history, isEmpty);
        });

        test('disable and enable', () {
          iSpectify.disable();
          iSpectify.error('Test disabled log');

          expect(iSpectify.history, isEmpty);

          iSpectify.enable();
          iSpectify.error('Test disabled log');

          expect(iSpectify.history, isNotEmpty);
        });
      },
    );
  });
}
