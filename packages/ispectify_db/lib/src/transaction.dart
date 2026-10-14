import 'dart:async';

import 'package:ispectify/ispectify.dart';

final class ISpectDbTxn {
  const ISpectDbTxn._();

  static const _txnZoneKey = #ispectDbTxnId;

  static String? currentTransactionId() =>
      Zone.current[_txnZoneKey] as String? ?? currentTraceTransactionId();

  @Deprecated(
    'Use ISpectLogger.dbTransaction, whose transaction ID '
    'currentTransactionId already reads. Will be removed in 8.0.0.',
  )
  static Future<R> runInTransactionZone<R>(
    String txnId,
    Future<R> Function() run,
  ) =>
      runZoned<Future<R>>(run, zoneValues: {_txnZoneKey: txnId});
}
