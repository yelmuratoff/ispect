## Production safety

ISpect is flag-gated at compile time. When `ISPECT_ENABLED` is not defined, `ISpect.run()`, `ISpectBuilder.wrap(...)`, and `ISpectLocalizations.delegate()` resolve to `const`-guarded no-ops. Because the disabled path is a compile-time constant, release builds let Dart's tree-shaker drop the inactive toolkit code.

The flag is a build-time decision, not a runtime toggle. ISpect does not enable itself in production. A release pipeline opts in only if it explicitly passes `--dart-define=ISPECT_ENABLED=true`.

```bash
# Internal build, toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release build, toolkit inactive.
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

- Keep production jobs free of `--dart-define=ISPECT_ENABLED=true`.
- Keep debug-only setup inside `ISpect.run(...)` and `ISpectBuilder.wrap(...)` entry points.
- Add an environment guard (`ENVIRONMENT != 'production'`) for internal staging builds that share the same pipeline as production.
- Check the generated artifact if your compliance process needs binary evidence.

Measured footprint on an obfuscated release APK built without `--dart-define=ISPECT_ENABLED`: 6 residual `"ispect"` strings, compared to 276 in a development build. Treat the number as a release-footprint sanity check, not a guarantee that every textual reference disappears from the binary.
