# Roadmap

This roadmap is short on purpose. It describes the direction, not a promise that every imaginable integration ships in the next release.

## Evidence before enterprise adoption

Not required to use ISpect on internal builds, but these help larger teams trust the project:

- A reproducible benchmark suite and published results for startup cost, logging volume, export volume, history bounds, and payload capture on/off. **In progress:** CI publishes AOT hot-path and Android release-footprint results; startup and profile-frame measurements still need a physical-device pass.
- At least two real internal QA or staging use cases, published with concrete numbers, not invented ones.

The point of the numbers is to turn "ISpect is cheap" into evidence: the disabled build tree-shakes to a no-op, and the enabled build's cost is predictable and controllable. Current generated data lives in the `benchmark-data` branch; device-only startup and frame results will join it after reproducible physical-device passes.

### Remaining measurements

Most pure-Dart coverage is now automated: `ispectify`, `ispectify_db`, Dio, and
http run with fixed inputs and AOT compilation. The remaining measurements
need Flutter `3.32.6` and a recorded Android device.

- **Disabled-build footprint** — APK `--analyze-size` runs are automated. Still record cold start with `flutter run --profile --trace-startup` (`timeToFirstFrameMicros`) for each variant.
- **Per-log, redaction, export, DB, and adapter cost** — automated AOT cases cover metadata/payload logs, disabled/bounded history, 1/10/100 KB redaction, JSON Lines export, in-memory DB tracing, and Dio/http metadata/body capture.
- **High-volume / FPS** — run the `integration_test` in profile mode, wrapped in `binding.traceAction` + `TimelineSummary`, to record build/raster timing and missed-frame count with filters on and off.

Record the hardware next to every number, warm up before measuring, and run comparable passes on the same machine — otherwise the results are not reproducible.

## Developer experience: onboarding and examples

The toolkit is broad, and the current entry points assume the reader already knows which pieces they need. Two things lower the barrier: a setup that cannot be copied wrong, and runnable examples split by the integration you actually care about.

### Onboarding

- **Complete:** the root and `ispect` README sources lead with a copy-paste setup using `ISpect.run`, `ISpectBuilder.wrap`, a navigator observer, and the internal-build command. `ISpect` is a `final class` with a private constructor, not a widget.
- **Complete:** a package-selection table maps logging-only, network, sockets, storage, BLoC, Riverpod, UI, and layout needs to their packages.
- **Complete:** `ispectify` documents the logger-only path for projects that do not need the Flutter panel or observers.

### Examples split by category

Coverage is uneven today: `ispectify_db` and `ispectify_ws` already organize runnable variants under an `example/lib/examples/` subfolder, `ispectify_dio` / `ispectify_http` ship a single `main.dart`, and `ispectify_bloc` and `ispectify_riverpod` have no example project at all. The `ispect` showcase app already depends on every integration (its `complex_example.dart` demos Dio/HTTP/WS/DB plus Riverpod/BLoC observers in one file), so the split needs no new dependencies — it splits that combined tour into focused, category-first entry points:

```
packages/ispect/example/lib/
  network/main.dart      # Dio + http interceptors
  ws/main.dart           # WebSocket interceptor
  db/main.dart           # database/storage tracing
  bloc/main.dart         # BLoC observer
  riverpod/main.dart     # Riverpod observer
  routing/main.dart      # navigator observer (+ GoRouter/AutoRoute)
```

- **Complete:** focused showcase entry points live under `packages/ispect/example/lib/{network,ws,db,bloc,riverpod,routing}/main.dart` and run with `flutter run -t lib/<category>/main.dart`. `complex_example.dart` remains the all-in-one tour.
- **Complete:** `ispectify_bloc/example` and `ispectify_riverpod/example` are runnable standalone observer examples.
- **Complete:** [integration walkthroughs](docs/INTEGRATION_GUIDES.md) cover Clean Architecture boundaries, BLoC, Riverpod, and Navigator-based routing. GoRouter/AutoRoute as navigation _diagnostics_ (beyond a plain integration example) stays under "Later: optional integrations".

### Inspector UI customization

Requests for "more inspector customization" are open-ended, and theming already exists. Before adding surface area, collect concrete asks (default filters, visible columns, panel layout) so the API grows against real call sites rather than speculative options.

## Later: optional integrations

Potential integrations land only when there is real demand and a maintainable API surface:

- GraphQL clients.
- gRPC clients.
- GoRouter and AutoRoute navigation diagnostics.
- Firebase and Supabase wrappers.
- Analytics and crash-reporting breadcrumbs.
- Push notification diagnostics.
- Cache and background-task diagnostics.

## Not goals

- Replacing Flutter DevTools profiling and debugger workflows.
- Replacing production telemetry platforms (Sentry, Crashlytics, and the rest).
- Capturing all application data by default.
- Shipping every ecosystem integration in the core package.
