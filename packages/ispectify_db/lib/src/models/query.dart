import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/data/query.dart';
import 'package:ispectify_db/src/settings.dart';

class DbQueryLog extends ISpectifyData {
  DbQueryLog(
    super.message, {
    required this.settings,
    required this.queryData,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.queryPen ?? (AnsiPen()..xterm(75)),
          additionalData: queryData.toJson(),
        );

  final ISpectDbLoggerSettings settings;
  final DbQueryData queryData;

  static const getKey = 'db-query';

  @override
  String get textMessage {
    final buffer = StringBuffer(message ?? '');
    if (settings.printQuery && queryData.sql != null) {
      buffer.write('\nSQL: ${queryData.sql}');
    }
    if (settings.printParams && queryData.params != null) {
      final pretty = JsonTruncatorService.pretty(queryData.params);
      buffer.write('\nParams: $pretty');
    }
    return buffer.toString().truncate()!;
  }
}
