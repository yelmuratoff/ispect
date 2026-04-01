export 'package:ansicolor/ansicolor.dart';

export 'src/console_settings.dart';
export 'src/export/log_exporter.dart';
export 'src/filter/category_filter.dart';
export 'src/filter/filter.dart';
export 'src/history/file_log/file_log_history.dart';
export 'src/history/history.dart';
export 'src/history/serialization.dart';
export 'src/ispectify.dart';
export 'src/logger/console_utils.dart';
export 'src/logger/formatter.dart';
export 'src/logger/logger.dart';
export 'src/models/data.dart';
export 'src/models/data_extensions.dart';
export 'src/models/error.dart';
export 'src/models/exception.dart';
export 'src/models/log_data_x.dart';
export 'src/models/log_type.dart';
export 'src/models/models.dart';
export 'src/network/base_interceptor.dart';
export 'src/network/curl_utils.dart';
export 'src/network/network_interceptor_settings.dart';
export 'src/network/network_interceptor_settings_builder.dart';
export 'src/network/network_json_keys.dart';
export 'src/network/network_log_options.dart';
export 'src/network/network_map_redactor.dart';
export 'src/network/network_payload_sanitizer.dart';
export 'src/network/network_transaction.dart';
export 'src/observer/observer.dart';
export 'src/options.dart';
export 'src/redaction/constants/detection_patterns.dart';
export 'src/redaction/constants/placeholders.dart';
export 'src/redaction/redaction_service.dart';
export 'src/redaction/strategies/composite_redaction_strategy.dart';
export 'src/redaction/strategies/key_based_redaction.dart';
export 'src/redaction/strategies/pattern_based_redaction.dart';
export 'src/redaction/strategies/redaction_context.dart';
export 'src/redaction/strategies/redaction_strategy.dart';
export 'src/testing/fake_logger.dart';
export 'src/trace/extensions/analytics.dart';
export 'src/trace/extensions/auth.dart';
export 'src/trace/extensions/graphql.dart';
export 'src/trace/extensions/grpc.dart';
export 'src/trace/extensions/navigation.dart';
export 'src/trace/extensions/network.dart';
export 'src/trace/extensions/payment.dart';
export 'src/trace/extensions/push.dart';
export 'src/trace/extensions/sse.dart';
export 'src/trace/extensions/state.dart';
export 'src/trace/extensions/storage.dart';
export 'src/trace/extensions/ws.dart';
export 'src/trace/trace_categories.dart';
export 'src/trace/trace_category.dart';
export 'src/trace/trace_category_ids.dart';
export 'src/trace/trace_config.dart';
export 'src/trace/trace_extension.dart';
export 'src/trace/trace_keys.dart';
export 'src/trace/trace_token.dart';
export 'src/utils/common_utils.dart';
export 'src/utils/datetime_formatter.dart';
export 'src/utils/error_handler.dart';
export 'src/utils/json_truncator.dart';
export 'src/utils/string_extension.dart';

/// Compile-time constant to enable/disable ISpect via `--dart-define`.
///
/// When `false` (default), logging methods become no-ops and can be
/// tree-shaken from production builds.
///
/// Usage:
/// ```bash
/// flutter run --dart-define=ISPECT_ENABLED=true
/// ```
///
/// ```dart
/// if (kISpectEnabled) {
///   ISpect.init();
/// }
/// ```
const bool kISpectEnabled = bool.fromEnvironment('ISPECT_ENABLED');
