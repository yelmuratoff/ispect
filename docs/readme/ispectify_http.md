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
      ),
    );
  },
);
```

> Register `ISpectHttpInterceptor` **last** in the `interceptors` list. Request/response correlation is keyed on the `BaseRequest` instance, and `http_interceptor` lets each interceptor return a new request object. If an interceptor registered after it rebuilds the request, the response can't be matched and stays "Pending".

## Settings

`ISpectHttpInterceptorSettings` mirrors the Dio version. Headers and bodies are
captured and redacted by default, and `enableRedaction` defaults to `true`.

```dart
const settings = ISpectHttpInterceptorSettings(
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

Balanced capture keeps ordinary URLs and prepared typed values useful through
guarded, bounded formatting before redaction. Set
`captureMode: DiagnosticCaptureMode.strict` when application-defined
formatters must never run.

Preset factories and a builder are also available. Use
`ISpectHttpInterceptorSettingsBuilder.metadataOnly()` to retain request and
response metadata while omitting bodies and headers. The `development()`,
`staging()`, and `production()` presets remain available for environment-based
policies.

`metadataOnly()` and `production()` select strict capture. `development()` and
`staging()` keep balanced capture. Builders also expose
`withStrictCapture()` and `withBalancedCapture()`.
Use `withResourceLimits(...)` for an interceptor-local budget, or
`withInheritedResourceLimits()` to return to the logger policy.
`NetworkInterceptorDefaults` is the shared source of truth used by direct
settings construction and every network settings builder.

`logRequests` and `logResponses` control whether routine records are retained;
the production preset disables both and keeps redacted errors. The `print*`
flags can omit bodies, headers, or messages from retained console and metadata
fields. Full capture is the default and keeps redaction on; individual flags
and the `metadataOnly()` preset provide opt-in minimization. Use the
concrete settings `copyWith` or builder for these retention controls; the
attached interceptor's `configure(...)` method exposes the same shared capture
fields at runtime. Pass `inheritResourceLimits: true` to either `copyWith` or
`configure` to return resource-budget ownership to the logger.

<!-- partial:redaction -->

Custom redactor:

```dart
ISpectHttpInterceptor(
  logger: logger,
  redactor: RedactionService(
    additionalSensitiveKeys: {'x-internal-token'},
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
