import 'dart:async';

import 'package:ispectify_db/src/core/types.dart';

typedef NextHandler<T> = FutureOr<DbResult<T>> Function(DbOperation op);

abstract class DbInterceptor {
  FutureOr<DbResult<T>> intercept<T>(DbOperation op, NextHandler<T> next);
}

/// Adapter to unify different DB clients under a minimal interface
abstract class DbAdapter {
  FutureOr<DbResult<T>> execute<T>(DbOperation op);
}

/// A client that applies an interceptor chain before hitting the adapter
class InterceptingDbClient {
  InterceptingDbClient({
    required DbAdapter adapter,
    List<DbInterceptor> interceptors = const [],
  })  : _adapter = adapter,
        _interceptors = List.unmodifiable(interceptors);

  final DbAdapter _adapter;
  final List<DbInterceptor> _interceptors;

  Future<DbResult<T>> execute<T>(DbOperation op) async {
    NextHandler<T> dispatch = (inner) => _adapter.execute<T>(inner);
    for (final interceptor in _interceptors.reversed) {
      final next = dispatch;
      dispatch = (inner) => interceptor.intercept<T>(inner, next);
    }
    final result = await Future.sync(() => dispatch(op));
    return result;
  }
}
