import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/zoomable_color_picker/zoomable_color_picker.dart';

void main() {
  group('ZoomableColorPickerStyle HUD gaps', () {
    test('clear the default ring stack', () {
      const style = ZoomableColorPickerStyle.defaults;

      expect(style.ringStackWidth, 20);
      expect(style.hudAxialGap, 36);
      expect(style.hudLateralGap, 32);
    });

    test('grow with wider rings', () {
      const style = ZoomableColorPickerStyle(colorRingWidth: 26);

      expect(style.hudAxialGap, 46);
      expect(style.hudLateralGap, 42);
    });
  });
}
