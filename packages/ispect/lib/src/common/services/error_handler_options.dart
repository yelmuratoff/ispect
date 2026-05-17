/// Options for configuring how ISpect installs error/log handlers in the
/// running app.
///
/// These five flags control the runtime error-handling pipeline set up by
/// [`ISpect.run`]; they do not control logger configuration.
///
/// * `isFlutterPresentHandlingEnabled` — Whether Flutter present errors are handled.
/// * `isPlatformDispatcherHandlingEnabled` — Whether PlatformDispatcher errors are handled.
/// * `isFlutterErrorHandlingEnabled` — Whether Flutter framework errors are handled.
/// * `isUncaughtErrorsHandlingEnabled` — Whether uncaught Dart errors are handled.
/// * `isBlocHandlingEnabled` — Whether BLoC library events are logged.
///
/// All handlers are enabled by default.
final class ISpectErrorHandlerOptions {
  const ISpectErrorHandlerOptions({
    this.isFlutterPresentHandlingEnabled = true,
    this.isPlatformDispatcherHandlingEnabled = true,
    this.isFlutterErrorHandlingEnabled = true,
    this.isUncaughtErrorsHandlingEnabled = true,
    this.isBlocHandlingEnabled = true,
  });
  final bool isFlutterPresentHandlingEnabled;
  final bool isPlatformDispatcherHandlingEnabled;
  final bool isFlutterErrorHandlingEnabled;
  final bool isUncaughtErrorsHandlingEnabled;
  final bool isBlocHandlingEnabled;
}

/// Renamed to [ISpectErrorHandlerOptions] in 5.0.0 to disambiguate from
/// [ISpectOptions] (UI configuration). Will be removed in 6.0.0.
@Deprecated(
  'Use ISpectErrorHandlerOptions instead. Will be removed in 6.0.0.',
)
typedef ISpectLogOptions = ISpectErrorHandlerOptions;
