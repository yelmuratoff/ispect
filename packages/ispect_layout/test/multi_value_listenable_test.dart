import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/multi_value_listenable.dart';

void main() {
  group('MultiValueListenableBuilder', () {
    testWidgets('follows replaced listenables', (tester) async {
      final first = ValueNotifier<int>(0);
      final second = ValueNotifier<int>(0);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var builds = 0;

      Widget build(ValueNotifier<int> listenable) =>
          MultiValueListenableBuilder(
            valueListenables: [listenable],
            builder: (context) {
              builds++;
              return const SizedBox();
            },
          );

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));
      final buildsAfterSwap = builds;

      second.value++;
      await tester.pump();
      expect(builds, buildsAfterSwap + 1);

      first.value++;
      await tester.pump();
      expect(builds, buildsAfterSwap + 1);
    });
  });
}
