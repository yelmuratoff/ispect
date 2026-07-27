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
  printResponseHeaders: false,
  printResponseData: true,
  enableRedaction: true,
);
```

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

### Builder

```dart
final settings = ISpectDioInterceptorSettingsBuilder()
    .withoutResponses()
    .withRequestHeaders()
    .withResponseHeaders()
    .withoutRedaction() // not recommended, see "Data redaction" below.
    .build();
```

`logRequests` and `logResponses` decide whether routine records are retained.
Body and header capture is on by default and passes through the active
redaction policy. The `print*` fields can omit specific retained fields, while
the `metadataOnly()` preset opts into stronger data minimization without
disabling request/response visibility.
Concrete settings `copyWith` methods and builders expose the retention
controls. The shared base `configure` helper keeps its legacy-compatible field
set.

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
