import 'package:ispectify/ispectify.dart';

class DbQueryData {
  DbQueryData({
    required this.operation,
    required this.table,
    required this.sql,
    required this.params,
    this.driver,
    this.database,
    this.host,
    this.port,
    this.schema,
  });

  final String operation; // SELECT/INSERT/UPDATE/DELETE/RAW
  final String? table;
  final String? sql;
  final Map<String, dynamic>? params;

  final String? driver; // e.g. postgres, mysql, sqlite
  final String? database;
  final String? host;
  final int? port;
  final String? schema;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
      'operation': operation,
      'table': table,
      'sql': sql,
      'params': params,
      'driver': driver,
      'database': database,
      'host': host,
      'port': port,
      'schema': schema,
    };
    if (redactor == null) return map;
    final rawParams = (map['params'] as Map?)?.cast<String, dynamic>();
    if (rawParams != null) {
      map['params'] = redactor.redact(
        rawParams,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
    return map;
  }
}
