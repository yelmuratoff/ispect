import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/performance/src/builder.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  group('ISpectPerformanceOverlayBuilder', () {
    for (final enabled in [false, true]) {
      testWidgets(
        'keeps the host text direction when tracking enabled is $enabled',
        (tester) async {
          TextDirection? hostDirection;
          await tester.pumpWidget(
            appShell(
              Directionality(
                textDirection: TextDirection.rtl,
                child: ISpectPerformanceOverlayBuilder(
                  isPerformanceTrackingEnabled: enabled,
                  child: Builder(
                    builder: (context) {
                      hostDirection = Directionality.of(context);
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          );

          expect(hostDirection, TextDirection.rtl);
        },
      );
    }

    testWidgets('provides left-to-right when no direction is inherited', (
      tester,
    ) async {
      TextDirection? hostDirection;
      await tester.pumpWidget(
        ISpectScopeController(
          model: ISpectScopeModel(isISpectEnabled: true),
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: ISpectPerformanceOverlayBuilder(
              isPerformanceTrackingEnabled: true,
              child: Builder(
                builder: (context) {
                  hostDirection = Directionality.maybeOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(hostDirection, TextDirection.ltr);
    });
  });
}
