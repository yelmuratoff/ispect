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

CI verifies both behavior and release reachability:

- The disabled API matrix calls public entry points directly in `ispectify`,
  `ispectify_db`, `ispectify_riverpod`, `ispect`, `ispect_layout`,
  `ispectify_bloc`, `ispectify_dio`, `ispectify_http`, and `ispectify_ws`
  without defining `ISPECT_ENABLED`.
- The release job builds the same arm64 probe twice: once with the flag omitted
  and once with it enabled as a positive control. The probe calls the UI, layout,
  database, Dio, HTTP, WebSocket, BLoC, and Riverpod APIs without an outer flag
  branch.
- Exact implementation sentinels must be absent from disabled extracted AOT and
  present in the enabled control: `ISpect Log Screen`,
  `ISpectScopeNotFoundError`, `[ISpect] Console logging failed safely.`,
  `Select a widget first, then press Compare.`, `statementDigest`,
  `_ispect_started_at`, `ispect_sw`,
  `ISpect WebSocket frame capture failed safely.`, `bloc_event_ids`, and
  `provider-name`.

Raw occurrences of the package name are reported only as diagnostic context;
they are not used as a security threshold because compiler and dependency
metadata can change independently of reachable diagnostics implementations.
