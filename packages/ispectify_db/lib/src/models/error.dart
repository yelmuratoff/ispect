import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/data/error.dart';
import 'package:ispectify_db/src/data/query.dart';
import 'package:ispectify_db/src/settings.dart';

class DbErrorLog extends ISpectifyData {
  DbErrorLog(
    super.message, {
    required this.settings,
    required this.queryData,
    required this.errorData,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.errorPen ?? (AnsiPen()..red()),
          additionalData: {
            'query': queryData.toJson(),
            'error': errorData.toJson(),
          },
        );

  final ISpectDbLoggerSettings settings;
  final DbQueryData queryData;
  final DbErrorData errorData;

  static const getKey = 'db-error';

  @override
  String get textMessage {
    final buffer = StringBuffer(message ?? '');
    if (settings.printDuration) {
      buffer.write('\nDuration: ${errorData.durationMs} ms');
    }
    if (settings.printError && errorData.exception != null) {
      buffer.write('\nError: ${errorData.exception}');
    }
    return buffer.toString().truncate()!;
  }
}
