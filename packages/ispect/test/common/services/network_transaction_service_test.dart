import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/services/network_transaction_service.dart';
import 'package:ispectify/ispectify.dart';

ISpectLogData _http(
  String id, {
  required String requestId,
  required ISpectLogType type,
}) => ISpectLogData(
  '${type.key} $id',
  id: id,
  key: type.key,
  additionalData: <String, dynamic>{
    TraceKeys.category: TraceCategoryIds.network,
    TraceKeys.meta: <String, dynamic>{'requestId': requestId},
  },
);

ISpectLogData _request(int index) => _http(
  'REQUEST-$index',
  requestId: 'request-$index',
  type: ISpectLogType.httpRequest,
);

ISpectLogData _response(int index) => _http(
  'RESPONSE-$index',
  requestId: 'request-$index',
  type: ISpectLogType.httpResponse,
);

ISpectLogData _error(int index) => _http(
  'ERROR-$index',
  requestId: 'request-$index',
  type: ISpectLogType.httpError,
);

ISpectLogData _plain(String id) =>
    ISpectLogData('message $id', id: id, key: ISpectLogType.info.key);

Iterable<String> _rowIds(List<Object> entries) => entries.map(
  (entry) => switch (entry) {
    NetworkTransaction() => 'tx:${entry.requestId}',
    ISpectLogData() => entry.id,
    _ => throw StateError('unexpected row $entry'),
  },
);

void main() {
  late NetworkTransactionService service;

  setUp(() {
    service = NetworkTransactionService();
  });

  test('folds request, response, and error into one row per transaction', () {
    final logs = [
      _plain('A'),
      _request(1),
      _plain('B'),
      _response(1),
      _request(2),
      _error(2),
    ];

    final grouped = service.getGroupedEntries(logs, 1);

    expect(_rowIds(grouped.entries), [
      'A',
      'tx:request-1',
      'B',
      'tx:request-2',
    ]);
    expect(grouped.transactions['request-1']?.response?.id, 'RESPONSE-1');
    expect(grouped.transactions['request-1']?.isSuccess, isTrue);
    expect(grouped.transactions['request-2']?.error?.id, 'ERROR-2');
    expect(grouped.transactions['request-2']?.isError, isTrue);
  });

  test('assembles rows from source so a filtered subset stays whole', () {
    final source = [
      _request(1),
      _response(1),
      _request(2),
      _response(2),
      _request(3),
    ];
    final responsesOnly = [source[1], source[3]];

    final grouped = service.getGroupedEntries(responsesOnly, 1, source: source);

    expect(_rowIds(grouped.entries), ['tx:request-1', 'tx:request-2']);
    final rows = grouped.entries.cast<NetworkTransaction>();
    expect(rows.map((tx) => tx.request.id), ['REQUEST-1', 'REQUEST-2']);
    expect(rows.map((tx) => tx.response?.id), ['RESPONSE-1', 'RESPONSE-2']);
    expect(rows.every((tx) => tx.isSuccess), isTrue);
  });

  test('reuses the cached rows for the same lists and generation', () {
    final logs = [_request(1), _response(1)];

    final first = service.getGroupedEntries(logs, 1);
    final second = service.getGroupedEntries(logs, 1);

    expect(identical(first, second), isTrue);
  });

  test('rebuilds when the folded list changes under the same generation', () {
    final before = [_request(1), _response(1)];
    final after = [_request(2), _response(2)];

    service.getGroupedEntries(before, 1);
    final grouped = service.getGroupedEntries(after, 1);

    expect(_rowIds(grouped.entries), ['tx:request-2']);
  });
}
