
## 4.4.0-dev01

### Added
- **New Package: `ispectify_db`** - Passive database logging utilities for the ISpect toolkit. Enables logging of DB operations (queries, updates, key-value access) without proxying calls, supporting drivers like sqflite, drift, hive, shared_preferences.
  - **API Methods**: `ISpectify.db()` for single event logging, `ISpectify.dbTrace<T>()` for wrapping async operations with duration/error capture, `ISpectify.dbStart()`/`dbEnd()` for manual spans, `ISpectify.dbTransaction()` for transaction markers with shared `transactionId` via Dart Zone.
  - **Features**: Configurable redaction of sensitive data (e.g., passwords, tokens), sampling to reduce log volume, truncation of long values/args/statements, SQL digest for grouping similar queries, slow query marking based on threshold, transaction correlation with begin/commit/rollback markers, error handling with optional stack trace propagation when `attachStackOnError` is enabled, leaf-level truncation for `args` and `namedArgs` to prevent oversized logs while preserving structure.
  - **Configuration**: `ISpectDbConfig` with options like `sampleRate`, `redact`, `redactKeys`, `maxValueLength`, `maxArgsLength`, `maxStatementLength`, `attachStackOnError`, `enableTransactionMarkers`, `slowQueryThreshold`.
  - **Integration**: Logs `ISpectifyData` with keys `db-query`, `db-result`, `db-error` (already supported in ISpect UI), includes `additionalData` with operation details, duration, transactionId, etc.
  - **Unit Tests**: Comprehensive tests covering redaction, truncation, error handling, transaction markers, and projection.
  - **Example Project**: Standalone example under `packages/ispectify_db/example` demonstrating usage patterns for drift (SQL queries/updates), hive (key-value get), shared_preferences (key-value write), and transaction markers.

### Documentation
- Updated `ispectify_db/README.md` with detailed API reference, configuration examples, best practices, and notes on stack trace capture and args truncation.
- Added example project README with run instructions and integration notes.

### Enhancements
- Updated package versions across the monorepo using `update_versions.sh` script for consistency.

## 4.4.0-dev02

### Added
- **New Package: `ispectify_db`** - Passive database logging utilities for the ISpect toolkit. Enables logging of DB operations (queries, updates, key-value access) without proxying calls, supporting drivers like sqflite, drift, hive, shared_preferences.
  - **API Methods**: `ISpectify.db()` for single event logging, `ISpectify.dbTrace<T>()` for wrapping async operations with duration/error capture, `ISpectify.dbStart()`/`dbEnd()` for manual spans, `ISpectify.dbTransaction()` for transaction markers with shared `transactionId` via Dart Zone.
  - **Features**: Configurable redaction of sensitive data (e.g., passwords, tokens), sampling to reduce log volume, truncation of long values/args/statements, SQL digest for grouping similar queries, slow query marking based on threshold, transaction correlation with begin/commit/rollback markers, error handling with optional stack trace propagation when `attachStackOnError` is enabled, leaf-level truncation for `args` and `namedArgs` to prevent oversized logs while preserving structure.
  - **Configuration**: `ISpectDbConfig` with options like `sampleRate`, `redact`, `redactKeys`, `maxValueLength`, `maxArgsLength`, `maxStatementLength`, `attachStackOnError`, `enableTransactionMarkers`, `slowQueryThreshold`.
  - **Integration**: Logs `ISpectifyData` with keys `db-query`, `db-result`, `db-error` (already supported in ISpect UI), includes `additionalData` with operation details, duration, transactionId, etc.
  - **Unit Tests**: Comprehensive tests covering redaction, truncation, error handling, transaction markers, and projection.
  - **Example Project**: Standalone example under `packages/ispectify_db/example` demonstrating usage patterns for drift (SQL queries/updates), hive (key-value get), shared_preferences (key-value write), and transaction markers.

### Documentation
- Updated `ispectify_db/README.md` with detailed API reference, configuration examples, best practices, and notes on stack trace capture and args truncation.
- Added example project README with run instructions and integration notes.

### Enhancements
- Updated package versions across the monorepo using `update_versions.sh` script for consistency.
- Improved `RedactionService` heuristics to recognize both padded and unpadded Base64/Base64URL payloads while avoiding false negatives from whitespace or alternate alphabets.
- Relaxed binary-string detection in `RedactionService` to treat Unicode text as printable, preventing `[binary …]` placeholders from replacing legitimate localized content.

## 4.4.0-dev03

### Added
- **New Package: `ispectify_db`** - Passive database logging utilities for the ISpect toolkit. Enables logging of DB operations (queries, updates, key-value access) without proxying calls, supporting drivers like sqflite, drift, hive, shared_preferences.
  - **API Methods**: `ISpectify.db()` for single event logging, `ISpectify.dbTrace<T>()` for wrapping async operations with duration/error capture, `ISpectify.dbStart()`/`dbEnd()` for manual spans, `ISpectify.dbTransaction()` for transaction markers with shared `transactionId` via Dart Zone.
  - **Features**: Configurable redaction of sensitive data (e.g., passwords, tokens), sampling to reduce log volume, truncation of long values/args/statements, SQL digest for grouping similar queries, slow query marking based on threshold, transaction correlation with begin/commit/rollback markers, error handling with optional stack trace propagation when `attachStackOnError` is enabled, leaf-level truncation for `args` and `namedArgs` to prevent oversized logs while preserving structure.
  - **Configuration**: `ISpectDbConfig` with options like `sampleRate`, `redact`, `redactKeys`, `maxValueLength`, `maxArgsLength`, `maxStatementLength`, `attachStackOnError`, `enableTransactionMarkers`, `slowQueryThreshold`.
  - **Integration**: Logs `ISpectifyData` with keys `db-query`, `db-result`, `db-error` (already supported in ISpect UI), includes `additionalData` with operation details, duration, transactionId, etc.
  - **Unit Tests**: Comprehensive tests covering redaction, truncation, error handling, transaction markers, and projection.
  - **Example Project**: Standalone example under `packages/ispectify_db/example` demonstrating usage patterns for drift (SQL queries/updates), hive (key-value get), shared_preferences (key-value write), and transaction markers.

### Documentation
- Updated `ispectify_db/README.md` with detailed API reference, configuration examples, best practices, and notes on stack trace capture and args truncation.
- Added example project README with run instructions and integration notes.

### Enhancements
- Updated package versions across the monorepo using `update_versions.sh` script for consistency.
- Improved `RedactionService` heuristics to recognize both padded and unpadded Base64/Base64URL payloads while avoiding false negatives from whitespace or alternate alphabets.
- Relaxed binary-string detection in `RedactionService` to treat Unicode text as printable, preventing `[binary …]` placeholders from replacing legitimate localized content.
