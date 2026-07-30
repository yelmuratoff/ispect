import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  test('JsonTruncator honors a caller-supplied string limit', () {
    final value = '${'x' * 12000}TAIL';

    final output = JsonTruncator.pretty(
      {'value': value},
      maxStringLength: 20000,
    );

    expect(output, contains('TAIL'));
  });
}
