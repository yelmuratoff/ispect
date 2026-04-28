# Compatibility

This document describes the compatibility policy for the ISpect monorepo.

## SDK Policy

Current package constraints:

- Dart: `>=3.6.0 <4.0.0`
- Flutter packages: Flutter `3.22.0+` where a Flutter constraint is declared

CI uses a pinned Flutter SDK for the required signal and may also run against the latest stable Flutter channel as an advisory signal. The pinned SDK is the compatibility baseline for the current development line.

## Package Matrix

| Package          | Runtime                                      | Notes                                                                       |
| ---------------- | -------------------------------------------- | --------------------------------------------------------------------------- |
| `ispect`         | Flutter                                      | UI overlay, log viewer, navigator observer, exports, and layout integration |
| `ispect_layout`  | Flutter                                      | Visual layout inspector and color picker                                    |
| `ispectify`      | Dart                                         | Logging, tracing, filters, observers, redaction, history, and export        |
| `ispectify_dio`  | Dart / Flutter apps using Dio                | Dio interceptor with redaction                                              |
| `ispectify_http` | Dart / Flutter apps using `http_interceptor` | HTTP interceptor with redaction                                             |
| `ispectify_ws`   | Dart / Flutter apps using `ws`               | WebSocket diagnostics with redaction                                        |
| `ispectify_db`   | Dart                                         | Passive DB operation tracing through explicit wrappers/extensions           |
| `ispectify_bloc` | Dart / Flutter apps using `bloc`             | BLoC and Cubit observer                                                     |

## Release Channels

`5.0.0-dev` is a pre-release channel. Teams that require stable-only dependencies should remain on the latest stable 4.x release until `5.0.0` is published.

## Compatibility Changes

Breaking changes should be documented in `CHANGELOG.md` and, when migration is needed, in `docs/DEPRECATIONS.md`.
