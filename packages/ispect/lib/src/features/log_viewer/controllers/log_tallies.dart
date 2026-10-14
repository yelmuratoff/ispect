import 'package:flutter/foundation.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/common/utils/severity_bar.dart';
import 'package:ispectify/ispectify.dart';

typedef LogHeaderCounts = ({int total, int errors, int warnings});

final class _AppendCursor {
  ISpectLogData? _first;
  ISpectLogData? _last;
  int _length = 0;

  int resumeIndex(List<ISpectLogData> logs) {
    final length = _length;
    if (length == 0 || logs.length < length) return 0;
    if (!identical(logs.first, _first) || !identical(logs[length - 1], _last)) {
      return 0;
    }
    return length;
  }

  void advance(List<ISpectLogData> logs) {
    _length = logs.length;
    _first = logs.isEmpty ? null : logs.first;
    _last = logs.isEmpty ? null : logs.last;
  }
}

final class LogTypeKeyTally {
  final _cursor = _AppendCursor();
  Set<String> _excludedKeys = const {};
  Map<String, int> _counts = {};
  LogTypeKeysResult _result = (counts: const {}, unique: const []);

  LogTypeKeysResult update(
    List<ISpectLogData> logs, {
    required Set<String> excludedKeys,
  }) {
    final sameExclusions = setEquals(_excludedKeys, excludedKeys);
    final start = sameExclusions ? _cursor.resumeIndex(logs) : 0;
    if (start > 0 && start == logs.length) return _result;
    if (start == 0) {
      _counts = {};
      _excludedKeys = Set.unmodifiable(excludedKeys);
    }
    for (var index = start; index < logs.length; index++) {
      final key = captureISpectLogWithoutPayload(logs[index]).key;
      if (key == null || excludedKeys.contains(key)) continue;
      _counts[key] = (_counts[key] ?? 0) + 1;
    }
    _cursor.advance(logs);
    return _result = (
      counts: Map<String, int>.unmodifiable(_counts),
      unique: List<String>.unmodifiable(_counts.keys),
    );
  }
}

final class LogHeaderTally {
  final _cursor = _AppendCursor();
  ISpectFilter? _scope;
  LogHeaderCounts _counts = (total: 0, errors: 0, warnings: 0);

  LogHeaderCounts update(
    List<ISpectLogData> logs, {
    required ISpectFilter filter,
  }) {
    final current = _scope;
    final scope = current != null && _sameTypeScope(current, filter)
        ? current
        : _scope = ISpectFilter(
            types: filter.types,
            logTypeKeys: filter.logTypeKeys,
            excludedLogTypeKeys: filter.excludedLogTypeKeys,
            resourceLimits: filter.resourceLimits,
          );
    final start = identical(scope, current) ? _cursor.resumeIndex(logs) : 0;
    if (start > 0 && start == logs.length) return _counts;

    var (:total, :errors, :warnings) = start == 0
        ? (total: 0, errors: 0, warnings: 0)
        : _counts;
    for (var index = start; index < logs.length; index++) {
      final data = logs[index];
      if (!scope.apply(data)) continue;
      total++;
      switch (classifySeverity(data)) {
        case LogSeverity.error:
          errors++;
        case LogSeverity.warning:
          warnings++;
        case LogSeverity.normal:
          break;
      }
    }
    _cursor.advance(logs);
    return _counts = (total: total, errors: errors, warnings: warnings);
  }

  static bool _sameTypeScope(ISpectFilter a, ISpectFilter b) =>
      setEquals(a.types, b.types) &&
      setEquals(a.logTypeKeys, b.logTypeKeys) &&
      setEquals(a.excludedLogTypeKeys, b.excludedLogTypeKeys);
}
