# Compatibility

The compatibility policy for the ISpect monorepo.

## SDK policy

Current package constraints:

- Dart: `>=3.6.0 <4.0.0`.
- Flutter packages: Flutter `3.22.0+` where a Flutter constraint is declared.

CI runs against a pinned Flutter SDK as the required signal, and against the latest stable Flutter channel as an advisory signal. The pinned SDK is the compatibility baseline for the current development line.

## Package matrix

| Package          | Runtime                                      | Notes                                                                       |
| ---------------- | -------------------------------------------- | --------------------------------------------------------------------------- |
| `ispect`         | Flutter                                      | UI overlay, log viewer, navigator observer, exports, layout integration.    |
| `ispect_layout`  | Flutter                                      | Visual layout inspector and color picker.                                   |
| `ispectify`      | Dart                                         | Logging, tracing, filters, observers, redaction, history, export.           |
| `ispectify_dio`  | Dart / Flutter apps using Dio                | Dio interceptor with redaction.                                             |
| `ispectify_http` | Dart / Flutter apps using `http_interceptor` | HTTP interceptor with redaction.                                            |
| `ispectify_ws`   | Dart / Flutter apps using `ws`               | WebSocket diagnostics with redaction.                                       |
| `ispectify_db`   | Dart                                         | Passive DB operation tracing through explicit wrappers and extensions.      |
| `ispectify_bloc` | Dart / Flutter apps using `bloc`             | BLoC and Cubit observer.                                                    |
| `ispectify_riverpod` | Dart / Flutter apps using `riverpod`     | Riverpod `ProviderObserver` for add, update, dispose, and failure events.   |

## Release channels

The `5.x` line is the current stable channel. `5.0.0-dev` was the pre-release line during the 5.x architecture rollout and is no longer published. Teams that need an older API surface can pin the latest 4.x release from pub.dev, but new work targets `5.x`.

## Compatibility changes

Breaking changes are documented in `CHANGELOG.md`. When migration is needed, they also land in `docs/DEPRECATIONS.md`.
