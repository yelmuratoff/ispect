## Production safety

ISpect is flag-gated — with zero footprint in release builds when `ISPECT_ENABLED` is not defined at compile time. `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` become `const`-guarded no-ops and Dart's tree-shaker eliminates the entire toolkit.

```bash
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — toolkit removed by the tree-shaker.
flutter build apk
```

For environment-aware control:

```dart
import 'package:flutter/foundation.dart';

class ISpectConfig {
  static const bool isEnabled = bool.fromEnvironment(
    'ISPECT_ENABLED',
    defaultValue: kDebugMode,
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get shouldInitialize => isEnabled && environment != 'production';
}
```

Measured impact on an obfuscated release APK (no `--dart-define=ISPECT_ENABLED`): 6 residual `"ispect"` strings vs. 276 in a development build. See [ispect on pub.dev](https://pub.dev/packages/ispect) for the full production-safety guide.
