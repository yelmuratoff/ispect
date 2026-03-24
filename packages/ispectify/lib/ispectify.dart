export 'package:ansicolor/ansicolor.dart';

export 'src/console_settings.dart';
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
export 'src/models/log_type.dart';
export 'src/models/models.dart';
export 'src/network/base_interceptor.dart';
export 'src/network/curl_utils.dart';
export 'src/network/network_interceptor_settings.dart';
export 'src/network/network_interceptor_settings_builder.dart';
export 'src/network/network_log_options.dart';
export 'src/network/network_logs.dart';
export 'src/network/network_payload_sanitizer.dart';
export 'src/network/network_transaction.dart';
export 'src/network/request_id_generator.dart';
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
/// # Development (ISpect enabled)
/// flutter run --dart-define=ISPECT_ENABLED=true
///
/// # Production (ISpect removed)
/// flutter build apk
/// ```
const bool kISpectEnabled = bool.fromEnvironment(
  'ISPECT_ENABLED',
);
