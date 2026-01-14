export 'package:ansicolor/ansicolor.dart';

export 'src/common/base_interceptor.dart';
export 'src/common/extensions/ispectify_data.dart';
export 'src/enums/log_type.dart';
export 'src/filter/filter.dart';
export 'src/history/file_log/file_log_history.dart';
export 'src/history/history.dart';
export 'src/history/serialization.dart';
export 'src/ispectify.dart';
export 'src/logger/logger.dart';
export 'src/models/data.dart';
export 'src/models/error.dart';
export 'src/models/exception.dart';
export 'src/models/models.dart';
export 'src/network/network_log_options.dart';
export 'src/network/network_logs.dart';
export 'src/network/network_payload_sanitizer.dart';
export 'src/observer.dart';
export 'src/redaction/redaction_service.dart';
export 'src/redaction/strategies/composite_redaction_strategy.dart';
export 'src/redaction/strategies/key_based_redaction.dart';
export 'src/redaction/strategies/pattern_based_redaction.dart';
export 'src/redaction/strategies/redaction_strategy.dart';
export 'src/settings.dart';
export 'src/theme/options.dart';
export 'src/truncator.dart';
export 'src/utils/console_utils.dart';
export 'src/utils/curl_utils.dart';
export 'src/utils/error_handler.dart';
export 'src/utils/pretty_json.dart';
export 'src/utils/string_extension.dart';
export 'src/utils/time_formatter.dart';

/// Compile-time constant to enable/disable ISpect via `--dart-define`.
///
/// When `false` (default), logging methods become no-ops and can be
/// tree-shaken from production builds.
///
/// Usage:
/// ```bash
/// # Development (ISpect enabled)
/// flutter run --dart-define=ENABLE_ISPECT=true
///
/// # Production (ISpect removed)
/// flutter build apk
/// ```
const bool kISpectEnabled = bool.fromEnvironment(
  'ENABLE_ISPECT',
);
