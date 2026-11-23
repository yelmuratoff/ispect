# Compatibility

The compatibility policy for the ISpect monorepo.

## SDK policy

Current package constraints:

- Dart: `>=3.6.0 <4.0.0`; `ispect` and `ispect_layout` declare Dart `3.8.0+`, and in practice need Dart `3.13.0+`, which `material_ui` 1.11 requires and Flutter 3.47 ships with.
- Flutter: `ispect` and `ispect_layout` require Flutter `3.47.0+`, the first release with the standalone `material_ui` package they build on. The host app's `MaterialApp` and Material/Cupertino localization delegates must come from `material_ui` and `cupertino_ui` as well.

CI runs against the Flutter SDK that `.fvmrc` pins as the required signal, and against the latest stable Flutter channel as an advisory signal. The pinned SDK is the compatibility baseline for the current development line.

## Package matrix

| Package          | Runtime                                      | Notes                                                                       |
| ---------------- | -------------------------------------------- | --------------------------------------------------------------------------- |
| `ispect`         | Flutter                                      | UI overlay, log viewer, navigator observer, exports, layout integration.    |
| `ispect_layout`  | Flutter                                      | Visual layout inspector and color picker.                                   |
| `ispectify`      | Dart                                         | Logging, tracing, filters, observers, redaction, history, export.           |
| `ispectify_dio`  | Dart / Flutter apps using Dio                | Dio interceptor with redaction.                                             |
| `ispectify_http` | Dart / Flutter apps using `http_interceptor` | HTTP interceptor with redaction.                                            |
| `ispectify_ws`   | Dart / Flutter, any WebSocket client         | Provider-agnostic WebSocket diagnostics with redaction.                     |
| `ispectify_db`   | Dart                                         | Passive DB operation tracing through explicit wrappers and extensions.      |
| `ispectify_bloc` | Dart / Flutter apps using `bloc`             | BLoC and Cubit observer.                                                    |
| `ispectify_riverpod` | Dart / Flutter apps using `riverpod`     | Riverpod `ProviderObserver` for add, update, dispose, and failure events.   |

## Release channels

New work targets the `8.x` line, in prerelease as `8.0.0-dev.N`. It builds on
`material_ui` and needs Flutter 3.47. The `7.x` line stays the stable channel on
pub.dev for apps still on the framework Material library. `6.x` is the previous
major line. Upgrade notes live in `CHANGELOG.md` and `docs/DEPRECATIONS.md`.

## Compatibility changes

Breaking changes are documented in `CHANGELOG.md`. When migration is needed, they also land in `docs/DEPRECATIONS.md`.
