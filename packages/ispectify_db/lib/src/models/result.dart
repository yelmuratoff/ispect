import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/data/query.dart';
import 'package:ispectify_db/src/data/result.dart';
import 'package:ispectify_db/src/settings.dart';

class DbResultLog extends ISpectifyData {
  DbResultLog(
    super.message, {
    required this.settings,
    required this.queryData,
    required this.resultData,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.resultPen ?? (AnsiPen()..green()),
          additionalData: {
            'query': queryData.toJson(),
            'result': resultData.toJson(),
          },
        );

  final ISpectDbLoggerSettings settings;
  final DbQueryData queryData;
  final DbResultData resultData;

  static const getKey = 'db-result';

  @override
  String get textMessage {
    final buffer = StringBuffer(message ?? '');
    if (settings.printDuration) {
      buffer.write('\nDuration: ${resultData.durationMs} ms');
    }
    if (settings.printResult && resultData.rows != null) {
      final pretty = JsonTruncatorService.pretty(resultData.rows);
      buffer.write('\nRows: $pretty');
    }
    return buffer.toString().truncate()!;
  }
}
