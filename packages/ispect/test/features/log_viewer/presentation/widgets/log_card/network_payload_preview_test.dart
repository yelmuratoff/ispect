import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_payload_preview.dart';
import 'package:ispectify/ispectify.dart';

import '../../../../../helpers/pump_ispect.dart';

void main() {
  testWidgets('body and headers use card-level squircle roundness', (
    tester,
  ) async {
    await tester.pumpWidget(
      appShell(
        NetworkPayloadPreview(
          payload: NetworkLogPayload(
            body: const {'name': 'Ada'},
            headers: const {'content-type': 'application/json'},
          ),
          color: Colors.green,
          maxStringLength: 1024,
        ),
      ),
    );

    final preview = find.byType(NetworkPayloadPreview);
    final surfaces = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: preview, matching: find.byType(DecoratedBox)),
        )
        .toList();

    expect(surfaces, hasLength(2));
    for (final surface in surfaces) {
      expect(surface.decoration, isA<ShapeDecoration>());
      final shape = (surface.decoration as ShapeDecoration).shape;
      expect(shape, isA<RoundedSuperellipseBorder>());
      expect(
        (shape as RoundedSuperellipseBorder).borderRadius,
        ISpectSquircle.border().borderRadius,
      );
    }
  });

  testWidgets('headers disclosure uses a visible Material ripple', (
    tester,
  ) async {
    await tester.pumpWidget(
      appShell(
        NetworkPayloadPreview(
          payload: NetworkLogPayload(
            headers: const {'content-type': 'application/json'},
          ),
          color: Colors.green,
          maxStringLength: 1024,
        ),
      ),
    );

    final preview = find.byType(NetworkPayloadPreview);
    expect(
      find.descendant(of: preview, matching: find.byType(Material)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.byType(InkWell)),
      findsOneWidget,
    );
  });
}
