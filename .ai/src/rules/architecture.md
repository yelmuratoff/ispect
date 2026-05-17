# Architecture Rules

## Package Boundaries

- Put shared logging, trace categories, redaction, filters, history, and network primitives in `packages/ispectify`.
- Put client-specific network adapters in their package: Dio in `ispectify_dio`, `http_interceptor` in `ispectify_http`, `ws` in `ispectify_ws`.
- Put database tracing primitives in `packages/ispectify_db`; storage-driver examples and wrappers stay under `packages/ispectify_db/example`.
- Put Flutter UI, scopes, overlays, export/import UI, localization, and the app-facing `ISpect` entry point in `packages/ispect`.
- Put visual layout inspection mechanics in `packages/ispect_layout`; avoid moving inspector state into the app shell package.
- Keep `web_logs_viewer` as a demo/consumer of the packages through local `dependency_overrides`, not as a source for package internals.

## Public API

- Export consumer-facing APIs from the package root library (`lib/<package>.dart`) when they are meant for users.
- Keep implementation helpers in `lib/src/**`; do not import another package's `src` from production code.
- Match existing Dart 3 modifiers: use `final class` for closed utilities/models, `abstract final class` for constant namespaces, and `abstract interface class` for contracts.

## Cross-Cutting Flows

- Route diagnostic events through `ISpectLogger.trace`, network helpers, or package-specific logger extensions instead of parallel log pipelines.
- Keep correlation IDs consistent across request/response/error flows (`request-id`, trace token, transaction ID).
- Keep compile-time gating behavior intact: `kISpectEnabled` false should make ISpect initialization a no-op.

## Anti-Patterns

- Do not add shared code to a client adapter package when `ispectify` is the natural owner.
- Do not create a new package for a single feature before checking whether an existing `ispectify_*` package owns that integration type.
- Do not expose `src` files as examples for package consumers.
