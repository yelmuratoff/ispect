---
name: ispectify-http-setup
description: >-
  Attach or troubleshoot ispectify_http diagnostics with http_interceptor, including request correlation, capture settings, and redaction.
---

# HTTP diagnostics setup

Add `http`, `http_interceptor`, `ispectify`, and `ispectify_http`.
`ISpectHttpInterceptor` implements `http_interceptor`'s API; it is not an
`http.Client` by itself.

## Integration

- Register `ISpectHttpInterceptor` last in `InterceptedClient.build`'s list.
  Correlation uses the final `BaseRequest` instance; a later interceptor
  replacing it leaves responses unpaired.
- Preserve existing interceptors and share the application logger.
- Defaults capture bounded, redacted headers/bodies. Use metadata-only settings
  when payloads are unnecessary. Close an owned client at lifecycle end.

```dart
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';

InterceptedClient createClient(ISpectLogger logger) => InterceptedClient.build(
      interceptors: [
        if (kISpectEnabled)
          ISpectHttpInterceptor(
            logger: logger,
            settings:
                ISpectHttpInterceptorSettingsBuilder.metadataOnly().build(),
          ),
      ],
    );
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds. The `production()` preset keeps redacted errors only; it does not
replace the compile-time gate.

Keep redaction enabled. Extend keys with `ISpectRedaction` or the interceptor's
`redactor` argument. Metadata-only and production presets use strict capture;
balanced may invoke guarded app formatters. Use `configure(...)` to update an
attached interceptor and `inheritResourceLimits: true` to resume logger budgets.

Verify successful and failing calls using `MockClient` from
`package:http/testing.dart`. Check pairing and masked captured secrets. For
pending responses, check interceptor order first. Verify no capture without
the define.
