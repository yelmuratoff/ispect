import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/core/res/json_color.dart';

void main() {
  group('JsonColors.statusCodeColors', () {
    test('2xx maps to the success pair', () {
      expect(
        JsonColors.statusCodeColors(200),
        (JsonColors.statusSuccess, JsonColors.statusSuccessDark),
      );
      expect(
        JsonColors.statusCodeColors(299),
        (JsonColors.statusSuccess, JsonColors.statusSuccessDark),
      );
    });

    test('3xx maps to the warning pair (boundary at 300)', () {
      expect(
        JsonColors.statusCodeColors(300),
        (JsonColors.statusWarning, JsonColors.statusWarningDark),
      );
      expect(
        JsonColors.statusCodeColors(399),
        (JsonColors.statusWarning, JsonColors.statusWarningDark),
      );
    });

    test('4xx and 5xx map to the error pair (boundary at 400)', () {
      expect(
        JsonColors.statusCodeColors(400),
        (JsonColors.statusError, JsonColors.statusErrorDark),
      );
      expect(
        JsonColors.statusCodeColors(503),
        (JsonColors.statusError, JsonColors.statusErrorDark),
      );
    });
  });
}
