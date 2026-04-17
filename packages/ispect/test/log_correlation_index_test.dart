import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/services/log_correlation_index.dart';
import 'package:ispectify/ispectify.dart';

ISpectLogData _httpLog({
  required String keySuffix,
  required String requestId,
  required DateTime time,
  bool useV4Shape = false,
  bool success = true,
}) {
  final additional = useV4Shape
      ? <String, dynamic>{'request-id': requestId}
      : <String, dynamic>{
          TraceKeys.category: TraceCategoryIds.network,
          TraceKeys.meta: <String, dynamic>{'requestId': requestId},
          if (!success) TraceKeys.success: false,
        };
  return ISpectLogData(
    'http $keySuffix',
    time: time,
    key: 'http-$keySuffix',
    additionalData: additional,
  );
}

void main() {
  group('LogCorrelationIndex.find', () {
    test('request returns its response with positive duration', () {
      final index = LogCorrelationIndex();
      final t0 = DateTime(2026, 1, 1, 12);
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'r-1',
        time: t0,
      );
      final response = _httpLog(
        keySuffix: 'response',
        requestId: 'r-1',
        time: t0.add(const Duration(milliseconds: 125)),
      );
      final logs = <ISpectLogData>[request, response];

      final result = index.find(request, logs, 1);

      expect(result, isNotNull);
      expect(identical(result!.log, response), isTrue);
      expect(result.duration, const Duration(milliseconds: 125));
    });

    test('response returns its request with positive duration', () {
      final index = LogCorrelationIndex();
      final t0 = DateTime(2026, 1, 1, 12);
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'r-2',
        time: t0,
      );
      final response = _httpLog(
        keySuffix: 'response',
        requestId: 'r-2',
        time: t0.add(const Duration(milliseconds: 80)),
      );
      final logs = <ISpectLogData>[request, response];

      final result = index.find(response, logs, 1);

      expect(result, isNotNull);
      expect(identical(result!.log, request), isTrue);
      expect(result.duration, const Duration(milliseconds: 80));
    });

    test('error log is correlated to its request', () {
      final index = LogCorrelationIndex();
      final t0 = DateTime(2026, 1, 1, 12);
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'r-3',
        time: t0,
      );
      final error = _httpLog(
        keySuffix: 'error',
        requestId: 'r-3',
        time: t0.add(const Duration(milliseconds: 50)),
        success: false,
      );
      final logs = <ISpectLogData>[request, error];

      final forError = index.find(error, logs, 1);
      final forRequest = index.find(request, logs, 1);

      expect(identical(forError?.log, request), isTrue);
      expect(identical(forRequest?.log, error), isTrue);
    });

    test('falls back to v4 request-id in additionalData', () {
      final index = LogCorrelationIndex();
      final t0 = DateTime(2026, 1, 1, 12);
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'v4-1',
        time: t0,
        useV4Shape: true,
      );
      final response = _httpLog(
        keySuffix: 'response',
        requestId: 'v4-1',
        time: t0.add(const Duration(milliseconds: 30)),
        useV4Shape: true,
      );

      final result = index.find(request, [request, response], 1);

      expect(identical(result?.log, response), isTrue);
      expect(result?.duration, const Duration(milliseconds: 30));
    });

    test('returns null for non-HTTP logs', () {
      final index = LogCorrelationIndex();
      final plain = ISpectLogData(
        'debug',
        time: DateTime(2026),
        key: 'debug',
      );
      expect(index.find(plain, const [], 1), isNull);
    });

    test('returns null when no matching counterpart exists', () {
      final index = LogCorrelationIndex();
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'lonely',
        time: DateTime(2026),
      );
      expect(index.find(request, [request], 1), isNull);
    });

    test('scales to 10k logs without scanning on repeated lookups', () {
      final index = LogCorrelationIndex();
      final logs = <ISpectLogData>[];
      final base = DateTime(2026, 1, 1, 12);
      for (var i = 0; i < 5000; i++) {
        final reqId = 'req-$i';
        logs
          ..add(
            _httpLog(
              keySuffix: 'request',
              requestId: reqId,
              time: base.add(Duration(milliseconds: i)),
            ),
          )
          ..add(
            _httpLog(
              keySuffix: 'response',
              requestId: reqId,
              time: base.add(Duration(milliseconds: i + 10)),
            ),
          );
      }

      // First lookup builds the index.
      final first = index.find(logs[0], logs, 1);
      expect(first, isNotNull);
      expect(identical(first!.log, logs[1]), isTrue);

      // Repeated lookups on the same list should be fast and correct.
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i += 2) {
        final result = index.find(logs[i], logs, 1);
        expect(identical(result!.log, logs[i + 1]), isTrue);
      }
      stopwatch.stop();

      // Sanity bound: 1000 cached lookups should finish well under 1s on
      // any developer machine or CI. The goal is behavioural, not timing.
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 1)),
        reason: 'Cached lookups must not rebuild the index per call',
      );
    });

    test('identifies counterpart for the last inserted response', () {
      final index = LogCorrelationIndex();
      final t0 = DateTime(2026, 1, 1, 12);
      final request = _httpLog(
        keySuffix: 'request',
        requestId: 'r-4',
        time: t0,
      );
      final response = _httpLog(
        keySuffix: 'response',
        requestId: 'r-4',
        time: t0.add(const Duration(milliseconds: 10)),
      );
      final error = _httpLog(
        keySuffix: 'error',
        requestId: 'r-4',
        time: t0.add(const Duration(milliseconds: 20)),
        success: false,
      );

      // Request correlates to its response when both response and error
      // are present; error stays reachable via the error log itself.
      final forRequest = index.find(request, [request, response, error], 1);
      expect(identical(forRequest?.log, response), isTrue);

      final forError = index.find(error, [request, response, error], 1);
      expect(identical(forError?.log, request), isTrue);
    });
  });
}
