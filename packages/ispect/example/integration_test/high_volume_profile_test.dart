import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ispect/ispect.dart';

import 'support/high_volume_benchmark.dart';

const _scrollOffset = Offset(0, -1200);
const _scrollDuration = Duration(milliseconds: 1500);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'profiles the ISpect log viewer with filters off and on',
    (tester) async {
      expect(
        kISpectEnabled,
        isTrue,
        reason: 'Run with --dart-define=ISPECT_ENABLED=true',
      );

      final benchmarkKey = GlobalKey<HighVolumeBenchmarkState>();
      await tester.pumpWidget(
        HighVolumeBenchmarkApp(key: benchmarkKey),
      );
      await tester.pumpAndSettle();

      final state = benchmarkKey.currentState!;
      state.seedEvents();
      await tester.pumpAndSettle();
      expect(state.totalLogCount, highVolumeEventCount);

      state.showAllLogs();
      await _warmUp(tester, state);
      await binding.watchPerformance(
        () => _exerciseScroll(tester),
        reportKey: 'high-volume-filters-off',
      );

      state.showErrorsOnly();
      await tester.pumpAndSettle();
      expect(state.visibleLogCount, highVolumeErrorCount);
      await _warmUp(tester, state);
      await binding.watchPerformance(
        () => _exerciseScroll(tester),
        reportKey: 'high-volume-filters-on',
      );

      final physicalSize = state.physicalSize;
      final devicePixelRatio = state.devicePixelRatio;
      final reportData = binding.reportData ?? <String, dynamic>{};
      reportData['high-volume-metadata'] = <String, Object>{
        'event-count': highVolumeEventCount,
        'filtered-event-count': highVolumeErrorCount,
        'refresh-rate-hz': state.refreshRate,
        'physical-width': physicalSize.width,
        'physical-height': physicalSize.height,
        'device-pixel-ratio': devicePixelRatio,
        'logical-width': physicalSize.width / devicePixelRatio,
        'logical-height': physicalSize.height / devicePixelRatio,
      };
      binding.reportData = reportData;
    },
    skip: !kProfileMode,
  );
}

Future<void> _warmUp(
  WidgetTester tester,
  HighVolumeBenchmarkState state,
) async {
  state.resetScrollPosition();
  await tester.pumpAndSettle();
  await _exerciseScroll(tester);
  state.resetScrollPosition();
  await tester.pumpAndSettle();
}

Future<void> _exerciseScroll(WidgetTester tester) async {
  final scrollView = find.byType(CustomScrollView);
  expect(scrollView, findsOneWidget);

  await tester.timedDrag(
    scrollView,
    _scrollOffset,
    _scrollDuration,
  );
  await tester.timedDrag(
    scrollView,
    -_scrollOffset,
    _scrollDuration,
  );
}
