/// Top-level keys in [ISpectLogData.additionalData] for trace envelope.
///
/// Not to be confused with `NetworkJsonKeys` — those are used INSIDE `meta`
/// for domain payload.
abstract final class TraceKeys {
  static const category = 'category';
  static const source = 'source';
  static const operation = 'operation';
  static const target = 'target';
  static const key = 'key';
  static const value = 'value';
  static const durationMs = 'durationMs';
  static const slow = 'slow';
  static const success = 'success';
  static const error = 'error';
  static const meta = 'meta';
  static const transactionId = 'transactionId';
  static const correlationId = 'correlationId';
}
