import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/search_highlight_controller.dart';

void main() {
  group('SearchHighlightController.needsMatchUpdate', () {
    late SearchHighlightController controller;
    late int notifications;

    setUp(() {
      controller = SearchHighlightController(filterManager: FilterManager());
      notifications = 0;
      controller.addListener(() => notifications++);
    });

    tearDown(() => controller.dispose());

    test('needs the first match list', () {
      expect(controller.needsMatchUpdate(const []), isTrue);
    });

    test('skips a match list it already applied', () {
      const empty = <ISpectLogData>[];
      controller.updateSearchMatches(empty);

      expect(controller.needsMatchUpdate(empty), isFalse);
      expect(notifications, 0);
    });

    test('needs a new match list', () {
      controller.updateSearchMatches(const []);

      expect(
        controller.needsMatchUpdate([ISpectLogData('m', id: 'm')]),
        isTrue,
      );
    });

    test('needs the applied list again after the search mode resets', () {
      final matches = [ISpectLogData('m', id: 'm')];
      controller
        ..updateSearchMatches(matches)
        ..searchMode = SearchMode.filter
        ..searchMode = SearchMode.highlight;

      expect(controller.needsMatchUpdate(matches), isTrue);
    });
  });
}
