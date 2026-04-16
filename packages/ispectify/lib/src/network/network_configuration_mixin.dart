import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/network/network_interceptor_settings.dart';

/// Mixin providing runtime reconfiguration for network interceptors.
///
/// Interceptors that support runtime settings changes (e.g. Dio, HTTP) should
/// override [configurableSettings] and [applyConfigurableSettings].
/// Read-only interceptors (e.g. WebSocket) can omit this mixin entirely.
mixin NetworkConfigurationMixin {
  /// The current settings exposed for runtime reconfiguration.
  ///
  /// Returns `null` by default — override in interceptors that support
  /// [configure] (e.g. Dio, HTTP). WS and other read-only interceptors
  /// do not need to override this.
  BaseNetworkInterceptorSettings? get configurableSettings => null;

  /// Applies [updated] settings. Override alongside [configurableSettings].
  ///
  /// The default implementation is a no-op.
  // ignore: use_setters_to_change_properties
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {}

  /// Reconfigures logging options at runtime without replacing the interceptor.
  ///
  /// Only fields provided (non-null) are updated; omitted fields retain their
  /// current values. Has no effect when [configurableSettings] returns `null`.
  void configure({
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    bool? enableRedaction,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
  }) {
    final current = configurableSettings;
    if (current == null) return;
    applyConfigurableSettings(
      current.copyWith(
        printResponseData: printResponseData,
        printResponseHeaders: printResponseHeaders,
        printResponseMessage: printResponseMessage,
        printErrorData: printErrorData,
        printErrorHeaders: printErrorHeaders,
        printErrorMessage: printErrorMessage,
        printRequestData: printRequestData,
        printRequestHeaders: printRequestHeaders,
        enableRedaction: enableRedaction,
        requestPen: requestPen,
        responsePen: responsePen,
        errorPen: errorPen,
      ),
    );
  }
}
