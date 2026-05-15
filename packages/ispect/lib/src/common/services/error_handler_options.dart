/// Options for configuring ISpect's log handling capabilities.
///
/// This class allows you to enable or disable various error and logging
/// handlers that ISpect provides.
///
/// * `isFlutterPresentHandlingEnabled` - Controls whether Flutter present errors are handled.
/// * `isPlatformDispatcherHandlingEnabled` - Controls whether PlatformDispatcher errors are handled.
/// * `isFlutterErrorHandlingEnabled` - Controls whether Flutter framework errors are handled.
/// * `isUncaughtErrorsHandlingEnabled` - Controls whether uncaught Dart errors are handled.
/// * `isBlocHandlingEnabled` - Controls whether BLoC library events are logged.
///
/// By default, all handlers are enabled.
final class ISpectLogOptions {
  const ISpectLogOptions({
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
