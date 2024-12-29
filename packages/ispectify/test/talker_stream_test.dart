import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('TalkerStream', () {
    final iSpectify = ISpectiy();

    test('handle', () async {
      iSpectify.error('Test message');
      iSpectify.stream.listen((log) => expectAsync1((event) => event is ISpectifyLog));
    });
  });
}
