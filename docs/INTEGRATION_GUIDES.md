# Integration Walkthroughs

ISpect is a diagnostics dependency, not a new application architecture. Keep
business logic independent from it and add diagnostics at the boundaries where
events cross layers.

## Clean Architecture

Keep `ispectify` in the data and application composition layers. Domain
entities and use cases should not import Flutter or interceptor packages.

| Layer | Recommended integration |
| --- | --- |
| Presentation | `ispect` for the panel, `ISpectNavigatorObserver` for routes, and BLoC/Riverpod observers at app composition. |
| Application/domain | `ispectify` trace extensions around use cases when a duration/outcome is useful. Project results to counts, IDs, and statuses. |
| Data | `ispectify_dio`, `ispectify_http`, `ispectify_ws`, and `ispectify_db` at client/repository boundaries. |

```dart
final user = await logger.traceAsync<User>(
  category: authCategory,
  source: 'sign_in_use_case',
  operation: 'execute',
  run: () => repository.signIn(email, password),
  projectResult: (user) => {'user-id': user.id},
);
```

Do not project credentials, tokens, email addresses, raw response bodies, or
database rows. The default redactor is a safety net, not a reason to collect
unnecessary data.

## BLoC

Install one observer where the application configures global BLoC state. The
observer captures lifecycle and transition events without changing individual
blocs.

```dart
ISpect.run(
  () => runApp(const App()),
  onInit: () {
    Bloc.observer = ISpectBlocObserver(logger: ISpect.logger);
  },
);
```

For high-volume cubits, use `ISpectBlocSettings.minimal` or a filter. Enable
full event/state values only for the investigation that needs them.

## Riverpod

Add the observer at `ProviderScope`, rather than in providers themselves.
Provider code remains independent of diagnostics.

```dart
ISpect.run(
  () => runApp(
    ProviderScope(
      observers: [ISpectRiverpodObserver(logger: ISpect.logger)],
      child: const App(),
    ),
  ),
);
```

Use `ISpectRiverpodSettings.compact` when provider values could contain
sensitive or unusually large data while lifecycle visibility is still useful.

## Navigator-based routing

Create one observer that survives rebuilds, pass it to `MaterialApp`, and use
the same instance in `ISpectOptions`. The panel can then correlate route
changes with diagnostics from the rest of the app.

```dart
final observer = ISpectNavigatorObserver();

MaterialApp(
  navigatorObservers: ISpectNavigatorObserver.observers(observer: observer),
  builder: (_, child) => ISpectBuilder.wrap(
    child: child!,
    options: ISpectOptions(observer: observer),
  ),
);
```

The showcase target at `packages/ispect/example/lib/routing/main.dart` is the
smallest runnable version of this setup. GoRouter and AutoRoute-specific
diagnostics remain demand-driven integrations.
