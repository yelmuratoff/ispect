import 'package:ispectify/src/network/network_configuration_mixin.dart';
import 'package:ispectify/src/network/network_logger_mixin.dart';
import 'package:ispectify/src/network/network_redaction_mixin.dart';

export 'network_configuration_mixin.dart';
export 'network_logger_mixin.dart';
export 'network_redaction_mixin.dart';

/// Facade mixin combining [NetworkLoggerMixin], [NetworkRedactionMixin], and
/// [NetworkConfigurationMixin] for backward compatibility.
///
/// Classes using this mixin must also apply the three sub-mixins before it in
/// the `with` clause:
///
/// ```dart
/// class MyInterceptor extends SomeBase
///     with NetworkLoggerMixin, NetworkRedactionMixin,
///          NetworkConfigurationMixin, BaseNetworkInterceptor { ... }
/// ```
///
/// New interceptors can mix in only the sub-mixins they need — e.g. WebSocket
/// can omit [NetworkConfigurationMixin].
mixin BaseNetworkInterceptor
    on NetworkLoggerMixin, NetworkRedactionMixin, NetworkConfigurationMixin {
  /// Alias for [NetworkRedactionMixin.noRedactConfig].
  static const noRedactConfig = NetworkRedactionMixin.noRedactConfig;

  /// Alias for [NetworkLoggerMixin.asStringMap].
  static Map<String, dynamic>? asStringMap(Object? value) =>
      NetworkLoggerMixin.asStringMap(value);
}
