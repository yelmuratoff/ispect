---
name: new-network-package
description: Scaffold a new network interceptor package (e.g. Chopper, Retrofit) using the shared ispectify base. Trigger on "/new-network-package" or when the user asks to add support for a new HTTP client.
---

# New Network Package Skill

Scaffold and implement a new `ispectify_<client>` package that integrates a third-party HTTP client with the ISpect logging toolkit. `packages/ispectify_dio` and `packages/ispectify_http` are the reference adapters - open both before writing code and copy their shape, not this summary.

## When to Use

- User asks to add support for a new HTTP client (Chopper, Retrofit, etc.)
- User says "/new-network-package"
- Not for WebSocket or database capture: those belong to `ispectify_ws` and `ispectify_db`.

## Package Layout

Mirror the reference adapters:

```
packages/ispectify_<client>/
  lib/
    ispectify_<client>.dart            # Explicit exports of the public API
    src/
      interceptor.dart                 # ISpect<Client>Interceptor
      settings.dart                    # ISpect<Client>InterceptorSettings
      settings_builder.dart            # ISpect<Client>InterceptorSettingsBuilder
      data/
        _data.dart                     # Exports request/response(/error) data
        request.dart                   # <Client>RequestData
        response.dart                  # <Client>ResponseData
        error.dart                     # <Client>ErrorData, only if the client has an error type
      replay/<client>_request_sender.dart  # Optional NetworkRequestSender
      utils/                           # Optional serializers (form data, multipart)
  test/
    production_safety_test.dart        # Required
    ...                                # See Step 5
  example/                             # Minimal usage
  pubspec.yaml
  analysis_options.yaml
  CHANGELOG.md
  README.md                            # Generated - see Step 6
  LICENSE
```

## Shared Base in ispectify

Import these from `package:ispectify/ispectify.dart`; never reimplement them:

| API | Source | Use |
| --- | --- | --- |
| `NetworkLoggerMixin`, `NetworkRedactionMixin`, `NetworkConfigurationMixin`, `BaseNetworkInterceptor` | `lib/src/network/*_mixin.dart`, `base_interceptor.dart` | Interceptor mixins; `BaseNetworkInterceptor` is `on` the other three |
| `BaseNetworkInterceptorSettings` | `network_interceptor_settings.dart` | Shared flags, `isRedactionActive`, abstract `copyWith` |
| `BaseNetworkInterceptorSettingsBuilder<B, TReq, TRes, TErr>` | `network_interceptor_settings_builder.dart` | Fluent `with*`/`without*` methods and `apply*Defaults()` preset helpers |
| `NetworkFilterChain<T>`, `NetworkFilter<T>` | `lib/src/network/filter/` | Request/response/error filtering |
| `NetworkJsonKeys` | `network_json_keys.dart` | Every metadata key |
| `NetworkMapRedactor` | `network_map_redactor.dart` | Static in-place redaction (`redactUrl`, `redactHeaders`, `redactData`, `redactMapField`, `redactPathFields`, `redactMethod`, `redactFreeText`, `redactFreeTextValue`, `redactRedirects`, `redactMultipart`) |
| `NetworkPayloadSanitizer`, `NetworkUriSnapshot` | `network_payload_sanitizer.dart`, `network_uri_snapshot.dart` | Bounded body/header normalization and URL capture |
| `NetworkLogRenderer` | `network_log_renderer.dart` | `renderHintsKey` and `hint*` keys in log meta |
| `NetworkRequestSender` | `lib/src/network/replay/` | Optional replay integration |
| `ISpectLoggerNetwork` (`httpRequest`, `httpResponse`, `httpError`) | `lib/src/trace/extensions/network.dart` | The only log calls an adapter makes |
| `guardDiagnostics`, `generateTraceId` | `lib/src/trace/trace_helpers.dart`, `lib/src/utils/common_utils.dart` | Failure isolation and correlation IDs |

If the adapter needs something reusable that is missing here, add it to `ispectify` with tests rather than to the new package.

## Steps

### Step 1: Scaffold

1. Copy `packages/ispectify_dio/pubspec.yaml` and adapt it:
   - `name`, `description`, homepage/repository/issue_tracker as in the siblings.
   - `environment: sdk: ">=3.6.0 <4.0.0"`.
   - `dependencies`: `ispectify` plus the client package, with real constraints (no `any`).
   - `dependency_overrides: ispectify: path: ../ispectify`.
   - `dev_dependencies`: `lints` and `test` with the siblings' constraints.
   - Copy `version:` and the `ispectify` constraint from a sibling, then run `dart run tool/bin/ispect_tool.dart sync --dry-run` and `sync`; `version_sync.dart` discovers every directory under `packages/`, and `version.config` stays the source of truth.
2. Copy `packages/ispectify_dio/analysis_options.yaml` verbatim - each package carries its own full config; there is no root include.
3. Copy `LICENSE` and `.gitignore` from a sibling; create `CHANGELOG.md` (`ispect_tool changelog` skips packages without one).
4. `cd packages/ispectify_<client> && dart pub get`.

### Step 2: Settings

`settings.dart` - `class ISpect<Client>InterceptorSettings extends BaseNetworkInterceptorSettings`:

- `const` constructor forwarding every base field as `super.*` (`enabled`, `enableRedaction`, `captureMode`, `resourceLimits`, `logRequests`, `logResponses`, `print*`, `*Pen`).
- Filter fields as `NetworkFilterChain<TReq>? requestChain`, `NetworkFilterChain<TRes>? responseChain`, `NetworkFilterChain<TErr>? errorChain`. Skip the deprecated `requestFilter`/`responseFilter`/`errorFilter` callbacks the older adapters still carry for compatibility.
- Named predicates `bool shouldProcessRequest(TReq)`, `shouldProcessResponse(TRes)`, `shouldProcessError(TErr)` that return `chain?.apply(value) ?? true`.
- `@override copyWith(...)` covering every base parameter (including `inheritResourceLimits`) plus the chains, returning the concrete type.

### Step 3: Settings builder

`settings_builder.dart`:

```dart
class ISpect<Client>InterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpect<Client>InterceptorSettingsBuilder, TReq, TRes, TErr> {
  ISpect<Client>InterceptorSettingsBuilder();

  factory ISpect<Client>InterceptorSettingsBuilder.metadataOnly() =>
      ISpect<Client>InterceptorSettingsBuilder()..applyMetadataOnlyDefaults();
  // .development(), .production(), .staging() call the matching apply*Defaults();
  // .disabled() sets `..enabled = false`.

  @override
  ISpect<Client>InterceptorSettings build() => ISpect<Client>InterceptorSettings(/* every field */);
}
```

Presets live on the concrete builder as factories; the base class only provides the `apply*Defaults()` helpers.

### Step 4: Data classes and interceptor

Data classes (`data/*.dart`), following `DioRequestData`/`HttpRequestData`:

- Constructor takes the client object plus `DiagnosticResourceLimits`; build a `NetworkUriSnapshot` for the URL.
- `Map<String, dynamic> toJson({bool includeData, bool includeHeaders, bool redactionActive, DiagnosticCaptureMode captureMode, ...})` returns raw, bounded metadata keyed by `NetworkJsonKeys`. Response data nests the request map under `NetworkJsonKeys.request`; error data nests the response map under `NetworkJsonKeys.response`.
- `static void redact(Map<String, dynamic> map, RedactionService redactor, {Set<String>? ignoredValues, Set<String>? ignoredKeys, DiagnosticResourceLimits resourceLimits})` applies `NetworkMapRedactor.*` in place.

Interceptor (`interceptor.dart`):

```dart
class ISpect<Client>Interceptor /* extends or implements the client's hook */
    with
        NetworkLoggerMixin,
        NetworkRedactionMixin,
        NetworkConfigurationMixin,
        BaseNetworkInterceptor {
  ISpect<Client>Interceptor({
    ISpectLogger? logger,
    ISpect<Client>InterceptorSettings settings = const ISpect<Client>InterceptorSettings(),
    RedactionService? redactor,
  });
}
```

Implement the mixin contract as both references do:

- `ISpectLogger get logger`, `bool get enableRedaction`, `DiagnosticCaptureMode get captureMode`, `DiagnosticResourceLimits get resourceLimits` (`settings.resourceLimits ?? logger.options.resourceLimits`).
- `RedactionService get redactor => ISpectRedaction.resolveService(service: _explicitRedactor)` - resolve on every access so global redaction changes apply.
- `configurableSettings` and `applyConfigurableSettings` so the inherited `configure(...)` works; call `resourceLimits?.validate()` in the constructor and on apply.

Each hook (request, response, error):

1. Forward to the client first or last exactly as its pipeline requires, and wrap capture in `guardDiagnostics(_logger, () => _captureX(value), what: '<Client> request capture')`.
2. Gate on `_logger.hasActiveConsumers && settings.enabled` (plus `logRequests`/`logResponses`) before any inspection, then on `settings.shouldProcess*`; re-check the gate before each expensive step.
3. Correlate request and response with `generateTraceId()`, stored where the client carries it (Dio `options.extra[NetworkJsonKeys.ispectRequestId]`, http an `Expando`), and time with a monotonic `Stopwatch`.
4. Use `settings.isRedactionActive`; redact the method with `redactDiagnosticText`, the URL with `redactUrl` only when the snapshot `isTrusted`, and payload maps with `<Client>*Data.redact`. Redact error objects and stack traces with `NetworkMapRedactor.redactFreeTextValue`.
5. Log through the trace extension only:

```dart
_logger.httpRequest(
  source: '<client>',
  operation: operation,
  target: url,
  correlationId: requestId,
  config: ISpectTraceConfig(redact: false, resourceLimits: resourceLimits),
  meta: {
    NetworkJsonKeys.requestId: requestId,
    NetworkJsonKeys.requestData: requestDataJson,
    NetworkLogRenderer.renderHintsKey: {
      NetworkLogRenderer.hintPrintBody: settings.printRequestData,
      NetworkLogRenderer.hintPrintHeaders: settings.printRequestHeaders,
    },
  },
);
```

`httpResponse` adds `duration` and `NetworkJsonKeys.statusCode`/`responseData`; `httpError` adds `error`, `errorStackTrace`, and `NetworkJsonKeys.errorData`. Keep the `http-request`/`http-response`/`http-error` keys - add no new log type.

Export `interceptor.dart`, `settings.dart`, `settings_builder.dart` (and the replay sender or data classes only if consumers need them) from `lib/ispectify_<client>.dart`.

### Step 5: Tests

Use `package:test`, a real `ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false))`, and assertions on `logger.history`. Fake the client at its own transport seam (as `HttpClientAdapter` for Dio, `MockClient` for http) - no network, no mocking package. Match the reference test files:

- `production_safety_test.dart` - with `skip: kISpectEnabled ? '...' : false`, proves the omitted flag bypasses capture, filters, and redaction.
- `logger_test.dart` / `<client>_logging_test.dart` - request, response, error metadata and correlation.
- `logger_disabled_test.dart` - disabled settings, disabled/disposed logger, no consumers.
- `interceptor_guard_test.dart` - a throwing filter or redactor never breaks the host request.
- `redaction_policy_test.dart`, `security_regression_test.dart` - default redaction, explicit and global redactor, opt-out.
- `settings_test.dart`, `settings_builder_test.dart` - `copyWith`, presets, chains.
- `integration_test.dart`, plus `replay/` if a sender exists.

### Step 6: Integration

1. CI: add the package to the `test-flutter` matrix in `.github/workflows/test.yml` (where the adapters run) and to the `disabled-api-behavior` matrix in `.github/workflows/production_safety.yml`.
2. Release tooling: add it to `publishOrder` in `tool/lib/src/core/publish.dart` (after `ispectify`, before `ispect`) and a `ReadmeTarget` in `tool/lib/src/core/readme_builder.dart`.
3. Docs: create `docs/readme/ispectify_<client>.md` modelled on `docs/readme/ispectify_dio.md`, add a row to `docs/readme/_partials/install_matrix.md`, then run `dart run tool/bin/ispect_tool.dart readme`.
4. Add the user-facing entry to root `CHANGELOG.md`.
5. Agent docs: add the package to the pure Dart list in `.ai/src/AGENTS.md`, the adapter line in `.ai/src/rules/architecture.md`, the package lists in `.ai/src/commands/check-package.md` and `.ai/src/skills/package-quality-check/SKILL.md`, then run `agentsync sync`. Never edit the generated `CLAUDE.md` or `AGENTS.md`.

## Key Rules

1. Use `NetworkJsonKeys.*` for every metadata key.
2. Redact only through `NetworkMapRedactor` and the mixin helpers; keep redaction on by default.
3. Extend the base settings and builder; do not duplicate their fields or fluent methods.
4. Log only through `httpRequest`/`httpResponse`/`httpError`.
5. Capture never throws into the host client: every hook runs inside `guardDiagnostics`.
6. Check `hasActiveConsumers` and `settings.enabled` before touching payloads so disabled builds do no work.
7. Leave versions and internal constraints to `ispect_tool sync`.

## Checklist

- [ ] `dart analyze --fatal-infos` - zero issues
- [ ] `flutter test --dart-define=ISPECT_ENABLED=true --coverage` passes
- [ ] `dart test --run-skipped test/production_safety_test.dart` passes without the define
- [ ] `dart format` on changed Dart files
- [ ] No hardcoded metadata key strings in `lib/src/data/`
- [ ] Interceptor mixes in `NetworkLoggerMixin, NetworkRedactionMixin, NetworkConfigurationMixin, BaseNetworkInterceptor`
- [ ] Builder extends `BaseNetworkInterceptorSettingsBuilder<Self, TReq, TRes, TErr>` with factory presets
- [ ] `dart run tool/bin/ispect_tool.dart sync`, `version check`, and `deps` pass
- [ ] `test.yml` and `production_safety.yml` matrices updated
- [ ] `publishOrder` and `ReadmeTarget` added; `dart run tool/bin/ispect_tool.dart readme --check` passes
- [ ] Root `CHANGELOG.md` updated
- [ ] `.ai/src/` package lists updated and `agentsync sync` run
