<!-- partial:header -->

`ispectify_dio` is a [Dio](https://pub.dev/packages/dio) interceptor for the [ISpect toolkit](#the-ispect-toolkit). It captures requests and responses, pairs them into correlated transactions by a request ID, and redacts sensitive data before logging.

- Request, response, and error capture with headers, body, status, and duration.
- Per-call redaction of auth headers, tokens, PII, and credit-card data. On by default.
- Builder and factory presets for development, staging, and production setups.
- Works with any `Dio` instance. Attach the interceptor and the rest is automatic.

## Install

```yaml
dependencies:
  dio: ^5.0.0
  ispectify: ^{{version}}
  ispectify_dio: ^{{version}}
```

## Quick start

```dart
import 'package:dio/dio.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

ISpect.run(
  () => runApp(const MyApp()),
  logger: logger,
  onInit: () {
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: logger,
      ),
    );
  },
);
```

## Settings

`ISpectDioInterceptorSettings` captures headers, bodies, messages, and errors by default so the first diagnostic session is useful without extra configuration. Captured values are bounded and redacted before logging; `enableRedaction` defaults to `true` on every constructor.

```dart
const settings = ISpectDioInterceptorSettings(
  logRequests: true,
  logResponses: true,
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: true,
  printResponseData: true,
  enableRedaction: true,
  captureMode: DiagnosticCaptureMode.balanced,
  resourceLimits: DiagnosticResourceLimits.constrained,
);
```

Balanced capture lets typed request and response values contribute a guarded,
bounded `toJson()` snapshot before redaction. Set
`captureMode: DiagnosticCaptureMode.strict` when application-defined
formatters must never run.

### Preset factories

```dart
// Verbose payload capture with redaction still enabled.
final dev = ISpectDioInterceptorSettingsBuilder.development().build();

final hardened =
    ISpectDioInterceptorSettingsBuilder.metadataOnly().build();

// Redacted errors only. Routine request/response records are not retained.
final prod = ISpectDioInterceptorSettingsBuilder.production().build();

// Middle ground for staging environments.
final staging = ISpectDioInterceptorSettingsBuilder.staging().build();
```

`metadataOnly()` and `production()` select strict capture. `development()` and
`staging()` keep balanced capture. A custom builder can switch explicitly with
`withStrictCapture()` or `withBalancedCapture()`.
Use `withResourceLimits(...)` for an interceptor-local budget, or
`withInheritedResourceLimits()` to return to the logger policy.
`NetworkInterceptorDefaults` is the shared source of truth used by direct
settings construction and every network settings builder.

### Builder

```dart
final settings = ISpectDioInterceptorSettingsBuilder()
    .withoutResponses()
    .withoutRequestHeaders()
    .withoutRequestData()
    .withoutRedaction() // not recommended, see "Data redaction" below.
    .build();
```

`logRequests` and `logResponses` decide whether routine records are retained.
Body and header capture is on by default and passes through the active
redaction policy. The `print*` fields can omit specific retained fields, while
the `metadataOnly()` preset opts into stronger data minimization without
disabling request/response visibility.
Concrete settings `copyWith` methods and builders expose the retention
controls. Pass `inheritResourceLimits: true` to `copyWith` to clear a local
budget. An attached Dio interceptor can update the same shared fields at
runtime with `configure(...)`, including `enabled`, retention, capture mode,
resource limits, and individual payload fields.

<!-- partial:redaction -->

Disable redaction on a single interceptor instance (only for deterministic replay in test environments):

```dart
ISpectDioInterceptor(
  logger: logger,
  settings: const ISpectDioInterceptorSettings(enableRedaction: false),
);
```

Supply a custom `RedactionService`:

```dart
ISpectDioInterceptor(
  logger: logger,
  redactor: RedactionService(
    additionalSensitiveKeys: {'x-tenant-token'},
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
