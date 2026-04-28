## Production safety

ISpect is flag-gated. When `ISPECT_ENABLED` is not defined at compile time, `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` become `const`-guarded no-ops. Because the disabled path is known at compile time, release builds are eligible for Dart's tree-shaker to remove the inactive toolkit code.

`ISPECT_ENABLED` is a build-time decision, not a runtime toggle. ISpect does not enable itself in production; release pipelines opt in only if they explicitly pass `--dart-define=ISPECT_ENABLED=true`.

```bash
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — omit the flag so ISpect stays inactive.
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

Release checklist:

- keep production release jobs free of `--dart-define=ISPECT_ENABLED=true`;
- keep debug-only setup inside `ISpect.run(...)` / `ISpectBuilder.wrap(...)` entry points;
- prefer environment-aware guards such as `ENVIRONMENT != 'production'` for internal staging builds;
- verify generated artifacts if your compliance process requires binary evidence.

Measured impact on an obfuscated release APK (no `--dart-define=ISPECT_ENABLED`): 6 residual `"ispect"` strings vs. 276 in a development build. Treat this as a release-footprint check, not a promise that every textual reference disappears from the binary.
