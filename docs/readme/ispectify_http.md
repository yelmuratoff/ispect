<!-- partial:header -->

`ispectify_http` is an [`http_interceptor`](https://pub.dev/packages/http_interceptor) interceptor for the [ISpect toolkit](#the-ispect-toolkit). It captures requests made through the `package:http` client, pairs them into transactions, and redacts sensitive data before logging.

- Request, response, and error capture with headers, body, status, and duration.
- Redaction of auth headers, tokens, PII, and financial data. On by default.
- Works with any `InterceptedClient` from `http_interceptor`.

## Install

```yaml
dependencies:
  http: ^1.0.0
  http_interceptor: ^2.0.0
  ispectify: ^{{version}}
  ispectify_http: ^{{version}}
```

## Quick start

```dart
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispect/ispect.dart';
import 'package:ispectify_http/ispectify_http.dart';

final client = http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(const MyApp()),
  logger: logger,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
        ),
      ),
    );
  },
);
```

## Settings

`ISpectHttpInterceptorSettings` mirrors the Dio version. Headers and body capture toggles, with `enableRedaction: true` by default.

```dart
const settings = ISpectHttpInterceptorSettings(
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: false,
  printResponseData: true,
  enableRedaction: true,
);
```

Preset factories and a builder are also available. See `ISpectHttpInterceptorSettingsBuilder` for the `development()`, `staging()`, and `production()` presets.

<!-- partial:redaction -->

Custom redactor:

```dart
ISpectHttpInterceptor(
  logger: logger,
  redactor: RedactionService(
    sensitiveKeys: {...defaultSensitiveKeys, 'x-internal-token'},
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
