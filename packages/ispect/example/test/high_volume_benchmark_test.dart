import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

import '../integration_test/support/high_volume_benchmark.dart';

void main() {
  testWidgets(
    'renders and filters 2000 logs through the ISpect viewer pipeline',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final benchmarkKey = GlobalKey<HighVolumeBenchmarkState>();
      await tester.pumpWidget(
        HighVolumeBenchmarkApp(key: benchmarkKey),
      );

      final state = benchmarkKey.currentState!;
      expect(state.totalLogCount, 0);
      expect(state.visibleLogCount, 0);

      state.seedEvents();
      await tester.pumpAndSettle();

      expect(state.totalLogCount, highVolumeEventCount);
      expect(state.visibleLogCount, highVolumeEventCount);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(state.seedEvents, throwsStateError);

      state.showErrorsOnly();
      await tester.pumpAndSettle();

      expect(state.visibleLogCount, highVolumeErrorCount);
      expect(
        state.activeLogTypeKeys,
        <String>{ISpectLogType.error.key},
      );

      state.showAllLogs();
      await tester.pumpAndSettle();

      expect(state.visibleLogCount, highVolumeEventCount);
      expect(state.activeLogTypeKeys, isEmpty);
    },
  );
}
