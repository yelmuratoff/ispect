---
name: ispectify-dio-setup
description: >-
  Attach or configure ispectify_dio diagnostics on a consumer application's Dio client, including redacted request, response, and error capture.
---

# Dio diagnostics setup

Add `dio`, `ispectify`, and `ispectify_dio`. The Flutter panel is optional.

## Integration

- Attach one `ISpectDioInterceptor` to the existing `Dio` instance using the
  application's shared logger and resource policy.
- Preserve authentication, retry, and error interceptors. Choose diagnostic
  interceptor order according to which prepared request/response values need
  observing; avoid duplicate registration.
- Defaults capture bounded, redacted headers and bodies. Use metadata-only
  settings when timing, status, and transaction metadata are sufficient.

```dart
import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

void attachDiagnostics(Dio dio, ISpectLogger logger) {
  if (!kISpectEnabled) return;
  dio.interceptors.add(
    ISpectDioInterceptor(
      logger: logger,
      settings: ISpectDioInterceptorSettingsBuilder.metadataOnly().build(),
    ),
  );
}
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds. The `production()` settings preset keeps redacted errors only; it does
not authorize enabling diagnostics in public builds.

Keep `enableRedaction: true`. Extend sensitive keys through `ISpectRedaction`
or the interceptor's `redactor` override. Do not use `withoutRedaction()` to fix
missing data. Metadata-only and production presets use strict capture;
default/development capture is balanced and may invoke guarded app formatters.

Use `configure(...)` on an attached interceptor instead of adding another.
Clear local budgets with `inheritResourceLimits: true`, or use
`withInheritedResourceLimits()` on the settings builder.

Verify request, response, and error paths using a test-local `HttpClientAdapter`.
Check correlation, masked captured secrets, unchanged app response/error
behavior, and no capture without the define.
