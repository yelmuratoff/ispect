import 'dart:collection';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _HostileSearchException implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_SEARCH_EXCEPTION');
  }
}

final class _HostileSearchStack implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_SEARCH_STACK');
  }
}

final class _HostileSearchMap extends MapBase<String, Object?> {
  int iteratorCalls = 0;

  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(String key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<String> get keys {
    iteratorCalls++;
    throw StateError('HOSTILE_SEARCH_ITERATOR');
  }

  @override
  Object? remove(Object? key) => null;
}

final class _ThrowingFilter extends ISpectFilter {
  _ThrowingFilter();

  @override
  bool apply(ISpectLogData item) => throw StateError('HOSTILE_FILTER_CALLBACK');
}

final class _HostileSearchLogGetters extends ISpectLogData {
  _HostileSearchLogGetters()
      : super(
          'trusted-search-message',
          time: DateTime.utc(2025),
          key: 'trusted-search-key',
          logLevel: LogLevel.info,
          additionalData: const {
            'trusted': 'search-data',
            TraceKeys.category: 'trusted-category',
            TraceKeys.source: 'trusted-source',
            TraceKeys.correlationId: 'trusted-correlation',
            TraceKeys.transactionId: 'trusted-transaction',
            TraceKeys.operation: 'trusted-operation',
          },
        );

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError('FORGED_SEARCH_GETTER_SECRET');
  }

  @override
  DateTime get time => _forged();

  @override
  String? get key => _forged();

  @override
  LogLevel? get logLevel => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();

  @override
  Object? get exception => _forged();

  @override
  Error? get error => _forged();

  @override
  StackTrace? get stackTrace => _forged();

  @override
  Object? get messageForSerialization => _forged();

  @override
  String get formattedTime => _forged();

  @override
  Type get runtimeType => _forged();
}

void main() {
  test('SearchFilter never formats hostile diagnostic fields', () {
    final exception = _HostileSearchException();
    final stack = _HostileSearchStack();
    final data = ISpectLogData(
      'safe',
      exception: exception,
      stackTrace: stack,
      captureMode: DiagnosticCaptureMode.strict,
    );

    expect(SearchFilter('needle').apply(data), isFalse);
    expect(exception.calls, 0);
    expect(stack.calls, 0);
  });

  test('SearchFilter ignores hostile log getter overrides', () {
    final data = _HostileSearchLogGetters();

    expect(SearchFilter('trusted-search-message').apply(data), isTrue);
    expect(SearchFilter('trusted-search-key').apply(data), isTrue);
    expect(SearchFilter('FORGED_SEARCH_GETTER_SECRET').apply(data), isFalse);
    expect(data.getterCalls, 0);
  });

  test('structured filters and getters ignore hostile log overrides', () {
    final data = _HostileSearchLogGetters();

    expect(LogTypeKeyFilter(['trusted-search-key']).apply(data), isTrue);
    expect(const CategoryFilter({'trusted-category'}).apply(data), isTrue);
    expect(const SourceFilter({'trusted-source'}).apply(data), isTrue);
    expect(
      const CorrelationFilter('trusted-correlation').apply(data),
      isTrue,
    );
    expect(
      const TransactionFilter('trusted-transaction').apply(data),
      isTrue,
    );
    expect(data.traceCategory, 'trusted-category');
    expect(data.traceSource, 'trusted-source');
    expect(data.traceOperation, 'trusted-operation');
    expect(data.getterCalls, 0);
  });

  test('TypeFilter classifies only trusted core log kinds', () {
    final custom = _HostileSearchLogGetters();

    expect(TypeFilter([_HostileSearchLogGetters]).apply(custom), isFalse);
    expect(TypeFilter([ISpectLogData]).apply(custom), isTrue);
    expect(
      TypeFilter([ISpectLogError]).apply(ISpectLogError(StateError('safe'))),
      isTrue,
    );
    expect(
      TypeFilter([ISpectLogException]).apply(
        ISpectLogException(const FormatException('safe')),
      ),
      isTrue,
    );
    expect(custom.getterCalls, 0);
  });

  test('additional-data capture bounds a hostile map before search', () {
    final hostile = _HostileSearchMap();
    final data = ISpectLogData('safe', additionalData: hostile);

    expect(SearchFilter('needle').apply(data), isFalse);
    expect(hostile.iteratorCalls, 1);
  });

  test('SearchFilter bounds multi-MiB query and searchable values', () {
    final filter = SearchFilter('q' * (4 * 1024 * 1024));
    final data = ISpectLogData(
      'm' * (4 * 1024 * 1024),
      additionalData: {'payload': 'p' * (4 * 1024 * 1024)},
    );

    expect(filter.query.length, lessThan(4 * 1024 * 1024));
    expect(filter.apply(data), isFalse);
  });

  test('logger fails closed when a filter callback throws', () {
    final logger = ISpectLogger.testing(
      filter: _ThrowingFilter(),
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    expect(() => logger.info('safe'), returnsNormally);
    expect(logger.history, isEmpty);
  });

  group('SearchFilter envelope', () {
    test('does not match the synthetic envelope field names', () {
      final data = ISpectLogData('ok', key: 'info');

      for (final query in [
        'error',
        'time',
        'key',
        'message',
        'stack-trace',
        'additional-data',
        'log-level',
      ]) {
        expect(SearchFilter(query).apply(data), isFalse, reason: query);
      }
    });

    test('still matches payload keys and envelope values', () {
      final data = ISpectLogData(
        'ok',
        key: 'info',
        additionalData: const {'orderNumber': 7},
      );

      expect(SearchFilter('ordernumber').apply(data), isTrue);
      expect(SearchFilter('info').apply(data), isTrue);
      expect(SearchFilter('ok').apply(data), isTrue);
    });
  });

  group('filters over redacted payloads', () {
    ISpectLogData redactedTraceLog() {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      addTearDown(logger.dispose);
      logger.logData(
        ISpectLogData(
          'auth',
          key: 'trace-auth',
          additionalData: const {
            TraceKeys.category: 'auth',
            TraceKeys.source: 'login',
            TraceKeys.correlationId: 'corr-1',
            TraceKeys.transactionId: 'tx-1',
            'password': 'hunter2-secret',
          },
        ),
      );
      final data = logger.history.single;
      expect(data.additionalData?['password'], isNot('hunter2-secret'));
      return data;
    }

    test('key and trace-field filters match the redacted entry', () {
      final data = redactedTraceLog();

      expect(LogTypeKeyFilter(['trace-auth']).apply(data), isTrue);
      expect(LogTypeKeyFilter(['other']).apply(data), isFalse);
      expect(const CategoryFilter({'auth'}).apply(data), isTrue);
      expect(const CategoryFilter({'db'}).apply(data), isFalse);
      expect(const SourceFilter({'login'}).apply(data), isTrue);
      expect(const CorrelationFilter('corr-1').apply(data), isTrue);
      expect(const TransactionFilter('tx-1').apply(data), isTrue);
      expect(const TransactionFilter('tx-2').apply(data), isFalse);
    });
  });
}
