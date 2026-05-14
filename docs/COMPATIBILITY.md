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

## Release channels

`5.0.0-dev` is a pre-release channel. Teams that need stable-only dependencies should stay on the latest stable 4.x release until `5.0.0` ships.

## Compatibility changes

Breaking changes are documented in `CHANGELOG.md`. When migration is needed, they also land in `docs/DEPRECATIONS.md`.
