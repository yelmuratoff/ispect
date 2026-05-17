---
name: new-network-package
description: Scaffold a new network interceptor package (e.g. Chopper, Retrofit) using the shared ispectify base. Trigger on "/new-network-package" or when the user asks to add support for a new HTTP client.
---

# New Network Package Skill

Scaffold and implement a new `ispectify_<client>` package that integrates a third-party HTTP client with the ISpect logging toolkit.

## When to Use

- User asks to add support for a new HTTP client (Chopper, Retrofit, etc.)
- User says "/new-network-package"

## Architecture

Every network interceptor package follows the same structure built on shared abstractions from `ispectify`:

```
packages/ispectify_<client>/
  lib/
    ispectify_<client>.dart              # Public barrel export
    src/
      interceptor.dart                   # Main interceptor class
      settings.dart                      # Settings (extends BaseNetworkInterceptorSettings)
      settings_builder.dart              # Builder (extends BaseNetworkInterceptorSettingsBuilder)
      data/
        _data.dart                       # Barrel export for data classes
        request.dart                     # <Client>RequestData — toJson() for request metadata
        response.dart                    # <Client>ResponseData — toJson() for response metadata
        error.dart                       # <Client>ErrorData — toJson() for error metadata (if applicable)
      models/
        _models.dart                     # Barrel export for log models
        request.dart                     # <Client>RequestLog extends NetworkRequestLog
        response.dart                    # <Client>ResponseLog extends NetworkResponseLog
        error.dart                       # <Client>ErrorLog extends NetworkErrorLog
      utils/                             # Optional: serializers for opaque types (FormData, Multipart, etc.)
  test/
    interceptor_test.dart
    settings_test.dart
    settings_builder_test.dart
  pubspec.yaml
  analysis_options.yaml
  README.md
  LICENSE
```

## Shared Base from ispectify (DO NOT duplicate)

These are already in `ispectify` — import and extend, never reimplement:

| What | Purpose |
|------|---------|
| `NetworkJsonKeys` | All JSON key constants (`method`, `url`, `headers`, `data`, `status-code`, etc.) |
| `NetworkMapRedactor` | Redaction pipeline: `redactUrl()`, `redactHeaders()`, `redactData()`, `redactMapField()`, `redactPathFields()`, `redactRedirects()`, `redactMultipart()` |
| `BaseNetworkInterceptor` | Mixin with `safeLog()`, `shouldProcess()`, `redactUrlAndPath()`, `bodyAsMap()`, `payload` (NetworkPayloadSanitizer) |
| `BaseNetworkInterceptorSettings` | Abstract settings: `enabled`, `enableRedaction`, `print*` flags, `AnsiPen` colors |
| `BaseNetworkInterceptorSettingsBuilder<B>` | Fluent builder with `.development()`, `.production()`, `.staging()`, `.disabled()` presets |
| `NetworkRequestLog` / `NetworkResponseLog` / `NetworkErrorLog` | Base log classes |
| `NetworkPayloadSanitizer` | `decodeJsonGracefully()`, `toStringKeyMap()`, `ensureMap()`, header normalization |
| `RedactionService` | Pluggable redaction with key-based, pattern-based, and composite strategies |
| `RequestIdGenerator` | Unique request ID generation for request-response correlation |

## Steps to Implement

### Step 1: Scaffold the package

1. Create directory `packages/ispectify_<client>/`.
2. Create `pubspec.yaml`:
   - Name: `ispectify_<client>`
   - Version: read from `version.config` (single source of truth)
   - Dependencies: `ispectify` (use `dependency_overrides` for local dev), the HTTP client package
   - Dev dependencies: `test`, `mocktail` (or equivalent)
3. Create `analysis_options.yaml` — include the root analysis options.
4. Add `dependency_overrides` pointing to local `../ispectify` path.

### Step 2: Settings

**`settings.dart`** — extend `BaseNetworkInterceptorSettings`:

```dart
class ISpect<Client>InterceptorSettings extends BaseNetworkInterceptorSettings {
  const ISpect<Client>InterceptorSettings({
    // All base params forwarded to super
    super.enabled,
    super.enableRedaction,
    super.printRequestData,
    super.printRequestHeaders,
    super.printResponseData,
    super.printResponseHeaders,
    super.printResponseMessage,
    super.printErrorData,
    super.printErrorHeaders,
    super.printErrorMessage,
    super.requestPen,
    super.responsePen,
    super.errorPen,
    // Client-specific filters:
    this.requestFilter,
    this.responseFilter,
    this.errorFilter,
  });

  final bool Function(<ClientRequest>)? requestFilter;
  final bool Function(<ClientResponse>)? responseFilter;
  final bool Function(<ClientError>)? errorFilter;

  // copyWith() — forward all fields
}
```

**`settings_builder.dart`** — extend `BaseNetworkInterceptorSettingsBuilder<Self>`:

```dart
class ISpect<Client>InterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<ISpect<Client>InterceptorSettingsBuilder> {

  // Factory constructors: .development(), .production(), .staging(), .disabled()
  // Client-specific filter methods: withRequestFilter(), withResponseFilter(), withErrorFilter()
  // build() → ISpect<Client>InterceptorSettings
}
```

### Step 3: Data classes

**`data/request.dart`** — `<Client>RequestData`:

```dart
class <Client>RequestData {
  <Client>RequestData(this.request);
  final <ClientRequest> request;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
      // --- Identity ---
      NetworkJsonKeys.method: request.method,
      NetworkJsonKeys.url: request.url.toString(),
      // ... map all fields using NetworkJsonKeys

      // --- Payload ---
      NetworkJsonKeys.headers: ...,
      NetworkJsonKeys.data: ...,
    };

    if (redactor == null) return map;

    // Use shared redaction pipeline:
    NetworkMapRedactor.redactUrl(map, redactor);
    NetworkMapRedactor.redactHeaders(map, redactor, ignoredValues: ignoredValues, ignoredKeys: ignoredKeys);
    NetworkMapRedactor.redactData(map, redactor, ignoredValues: ignoredValues, ignoredKeys: ignoredKeys);

    return map;
  }
}
```

Apply the same pattern for `ResponseData` and `ErrorData`.

**Field ordering convention** (consistent across all packages):

For requests: Identity → Payload → Timing → Behaviour → Meta
For responses: Status → Identity → Payload → Redirects → Meta → Request (nested, last)
For errors: Error summary → Response → Request (nested, last)

### Step 4: Log models

Extend base network log classes:

```dart
class <Client>RequestLog extends NetworkRequestLog {
  <Client>RequestLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required <Client>InterceptorSettings settings,
    required <Client>RequestData requestData,
    super.requestId,
    super.body,
    RedactionService? redactor,
    Map<String, String>? headers,
  }) : super(
          settings: settings,
          headers: headers?.map(MapEntry.new),
          metadata: requestData.toJson(redactor: redactor),
        );
}
```

### Step 5: Interceptor

```dart
final class ISpect<Client>Interceptor with BaseNetworkInterceptor {
  ISpect<Client>Interceptor({
    required ISpectLogger logger,
    ISpect<Client>InterceptorSettings? settings,
    RedactionService? redactor,
  });

  // Use mixin helpers:
  // - safeLog(() => buildLog(...)) — prevents log failures from breaking HTTP pipeline
  // - shouldProcess(settings.enabled, filter, value) — consolidated enable + filter check
  // - redactUrlAndPath(url, redactor) — returns (redactedUrl, redactedPath)
  // - payload.body(), payload.headersMap(), payload.ensureMap() — payload normalization

  // configure() method — runtime reconfiguration with enableRedaction param
}
```

### Step 6: Tests

Cover:
- Request/response/error logging
- Filter application (request/response/error filters)
- Disabled state (no logging)
- Redaction on/off
- Settings builder presets
- `configure()` runtime changes
- Data class `toJson()` structure
- FormData/Multipart serialization (if applicable)

### Step 7: Integration

1. Add `dependency_overrides` in the new package's `pubspec.yaml` for local dev.
2. Add the package to the publish order in `bash/publish.sh`.
3. Add test commands to `.github/workflows/test.yml`.
4. Add version validation to `.github/workflows/validate_versions.yml`.
5. Update `bash/update_versions.sh` to include the new package.
6. Update root `CLAUDE.md` monorepo structure section.

## Key Rules

1. **NEVER hardcode JSON key strings** — always use `NetworkJsonKeys.*`.
2. **NEVER reimplement redaction** — use `NetworkMapRedactor.*` methods.
3. **NEVER duplicate settings/builder logic** — extend the base classes.
4. **Log models must pass `metadata`** via `requestData.toJson()` to enable JSON export.
5. **`configure()` must include `enableRedaction`** parameter.
6. **`redactHeaders()` returns the result** — if you need type conversion (e.g. `Map<String, String>`), do it in your data class, not in the shared utility.
7. **Interceptor must not throw** — wrap all log-building in `safeLog()`.
8. **Field ordering must follow the convention** — see Step 3.
9. **Version comes from `version.config`** — never hardcode in `pubspec.yaml`.

## Checklist

Before marking complete, verify:

- [ ] `dart analyze --fatal-infos` / `flutter analyze --fatal-infos` — zero issues
- [ ] All tests pass
- [ ] Zero hardcoded JSON key strings (grep for quoted strings in data/ files)
- [ ] Redaction uses `NetworkMapRedactor` exclusively
- [ ] Settings extends `BaseNetworkInterceptorSettings`
- [ ] Builder extends `BaseNetworkInterceptorSettingsBuilder<Self>`
- [ ] Interceptor uses `BaseNetworkInterceptor` mixin
- [ ] Log models extend `NetworkRequestLog` / `NetworkResponseLog` / `NetworkErrorLog`
- [ ] `metadata` passed to log constructors
- [ ] `configure()` includes `enableRedaction`
- [ ] Package added to version management scripts
- [ ] Package added to CI workflows
