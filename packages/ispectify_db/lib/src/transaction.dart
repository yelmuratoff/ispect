import 'dart:async';

final class ISpectDbTxn {
  static const _txnZoneKey = #ispectDbTxnId;

  static String? currentTransactionId() => Zone.current[_txnZoneKey] as String?;

  static Future<R> runInTransactionZone<R>(
      String txnId, Future<R> Function() run) {
    return runZoned<Future<R>>(run, zoneValues: {_txnZoneKey: txnId});
  }
}
