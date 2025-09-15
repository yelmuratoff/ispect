import 'package:ispectify/ispectify.dart';

class DbResultData {
  DbResultData({
    required this.durationMs,
    this.rowCount,
    this.rows,
    this.notice,
  });

  final int durationMs;
  final int? rowCount;
  final Object? rows; // driver-specific rows or mapped list
  final Object? notice;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
      'duration-ms': durationMs,
      'row-count': rowCount,
      'rows': rows,
      'notice': notice,
    };
    if (redactor == null) return map;
    map['rows'] = redactor.redact(
      map['rows'],
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    map['notice'] = redactor.redact(
      map['notice'],
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    return map;
  }
}
