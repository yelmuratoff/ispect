import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_layout/ispect_layout.dart';

import 'production_safety_diagnostics.dart' show exerciseDiagnosticsApis;

void main() {
  exerciseDiagnosticsApis();
  ISpect.run(
    () => runApp(const _ProductionSafetyProbe()),
  );
}

final class _ProductionSafetyProbe extends StatelessWidget {
  const _ProductionSafetyProbe();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SizedBox.shrink(),
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        final diagnostics = ISpectBuilder.wrap(child: app);
        return Inspector(
          isEnabled: true,
          child: diagnostics,
        );
      },
    );
  }
}
