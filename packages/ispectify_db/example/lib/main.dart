import 'dart:async';
import 'dart:developer';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

void main() async {
  final logger = ISpectLogger();

  ISpectDbCore.config = const ISpectDbConfig(
    sampleRate: 1.0,
    redact: true,
    attachStackOnError: true,
    enableTransactionMarkers: true,
    slowQueryThreshold: Duration(milliseconds: 250),
  );

  // Drift-like usage (raw SQL or generated queries)
  await logger.dbTrace<List<Map<String, Object?>>>(
    source: 'drift',
    operation: 'query',
    table: 'users',
    statement: 'SELECT * FROM users WHERE id = ? LIMIT 1',
    args: [123],
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return [
        {'id': 123, 'name': 'Alice'},
      ];
    },
    projectResult: (rows) => {'rows': rows.length},
  );

  // Hive-like (key-value) usage
  await logger.dbTrace<String?>(
    source: 'hive',
    operation: 'get',
    key: 'session_token',
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return null;
    },
  );

  // shared_preferences-like (key-value) usage
  await logger.dbTrace<bool>(
    source: 'shared_prefs',
    operation: 'write',
    key: 'onboarding_done',
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 3));
      return true;
    },
  );

  // Transaction markers example
  await logger.dbTransaction(
    source: 'drift',
    logMarkers: true,
    run: () async {
      await logger.dbTrace<int>(
        source: 'drift',
        operation: 'update',
        statement: 'UPDATE users SET name=? WHERE id=?',
        args: ['Bob', 123],
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 7));
          return 1; // affected rows
        },
      );
    },
  );

  // Listen to logs
  logger.stream.listen((e) {
    log('[${e.key}] ${e.message}');
  });
}
