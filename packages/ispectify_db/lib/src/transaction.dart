import 'dart:async';

final class ISpectDbTxn {
  const ISpectDbTxn._();

  static const _txnZoneKey = #ispectDbTxnId;

  static String? currentTransactionId() => Zone.current[_txnZoneKey] as String?;

  static Future<R> runInTransactionZone<R>(
    String txnId,
    Future<R> Function() run,
  ) =>
      runZoned<Future<R>>(run, zoneValues: {_txnZoneKey: txnId});
}
