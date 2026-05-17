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
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestData: true,
          printResponseData: true,
        ),
      ),
    );
  },
);
```

## Settings

`ISpectDioInterceptorSettings` controls which parts of each call are captured and whether they are redacted before logging. `enableRedaction` defaults to `true` on every constructor.

```dart
const settings = ISpectDioInterceptorSettings(
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: false,
  printResponseData: true,
  enableRedaction: true,
);
```

### Preset factories

```dart
// Verbose. Full payloads, no redaction. Only for local development.
final dev = ISpectDioInterceptorSettingsBuilder.development().build();

// Redacted. Conservative defaults, body capture off.
final prod = ISpectDioInterceptorSettingsBuilder.production().build();

// Middle ground for staging environments.
final staging = ISpectDioInterceptorSettingsBuilder.staging().build();
```

### Builder

```dart
final settings = ISpectDioInterceptorSettingsBuilder()
    .withRequestHeaders()
    .withResponseHeaders()
    .withoutRedaction() // not recommended, see "Data redaction" below.
    .build();
```

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
    sensitiveKeys: {...defaultSensitiveKeys, 'x-tenant-token'},
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
