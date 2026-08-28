import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/json_viewer/json_screen.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  test('snapshots every caller graph before retaining the widget', () {
    final hostile = _HostileLeaf();
    final dataNested = <String, dynamic>{
      'value': 'data-before',
      'hostile': hostile,
    };
    final truncatedNested = <String, dynamic>{'value': 'truncated-before'};
    final correlatedNested = <String, dynamic>{'value': 'correlated-before'};
    final data = <String, dynamic>{'nested': dataNested};
    final truncatedData = <String, dynamic>{'nested': truncatedNested};
    final correlatedData = <String, dynamic>{'nested': correlatedNested};

    final screen = JsonScreen(
      data: data,
      truncatedData: truncatedData,
      correlatedLogData: correlatedData,
    );

    dataNested['value'] = 'data-after';
    truncatedNested['value'] = 'truncated-after';
    correlatedNested['value'] = 'correlated-after';
    data.clear();
    truncatedData.clear();
    correlatedData.clear();

    final capturedData = screen.data['nested']! as Map<String, dynamic>;
    final capturedTruncated =
        screen.truncatedData!['nested']! as Map<String, dynamic>;
    final capturedCorrelated =
        screen.correlatedLogData!['nested']! as Map<String, dynamic>;

    expect(screen.data, isNot(same(data)));
    expect(screen.truncatedData, isNot(same(truncatedData)));
    expect(screen.correlatedLogData, isNot(same(correlatedData)));
    expect(capturedData['value'], 'data-before');
    expect(capturedTruncated['value'], 'truncated-before');
    expect(capturedCorrelated['value'], 'correlated-before');
    expect(capturedData['hostile'], isA<String>());
    expect(capturedData['hostile'], isNot(same(hostile)));
    expect(hostile.toStringCalls, 0);
    expect(hostile.toJsonCalls, 0);
  });

  test('catches hostile root Map traversal at construction time', () {
    final source = _ThrowingEntriesMap();

    final screen = JsonScreen(
      data: source,
      truncatedData: source,
      correlatedLogData: source,
    );

    expect(
      screen.data[JsonInputPreflight.traversalMarkerKey],
      JsonInputPreflight.unprintableValue,
    );
    expect(screen.truncatedData, same(screen.data));
    expect(screen.correlatedLogData, same(screen.data));
    expect(source.entriesReads, 1);
  });

  test('retains only an aggregate-bounded graph', () {
    final source = <String, dynamic>{
      'first': 'a' * JsonInputPreflight.maxViewerEncodedBytes,
      'second': 'b' * JsonInputPreflight.maxViewerEncodedBytes,
    };

    final screen = JsonScreen(data: source);
    final encoded = utf8.encode(jsonEncode(screen.data));

    expect(
      encoded.length,
      lessThanOrEqualTo(JsonInputPreflight.maxViewerEncodedBytes),
    );
    expect(
      utf8.decode(encoded),
      anyOf(
        contains(JsonInputPreflight.truncatedValue),
        contains(JsonInputPreflight.rejectedContent),
      ),
    );
  });

  test('honors a local viewer byte budget', () {
    final screen = JsonScreen(
      data: {'value': 'x' * 1024},
      resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
        maxViewerBytes: 64,
      ),
    );

    expect(utf8.encode(jsonEncode(screen.data)).length, lessThanOrEqualTo(64));
    expect(screen.data.toString(), contains(JsonInputPreflight.truncatedValue));
  });
}

final class _HostileLeaf {
  int toStringCalls = 0;
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('JsonScreen must not invoke toJson');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('JsonScreen must not invoke toString');
  }
}

final class _ThrowingEntriesMap extends MapBase<String, Object?> {
  int entriesReads = 0;

  @override
  Iterable<MapEntry<String, Object?>> get entries {
    entriesReads++;
    throw StateError('hostile entries');
  }

  @override
  Object? operator [](Object? key) =>
      throw StateError('operator[] must not be used');

  @override
  void operator []=(String key, Object? value) =>
      throw StateError('operator[]= must not be used');

  @override
  void clear() => throw StateError('clear must not be used');

  @override
  Iterable<String> get keys => throw StateError('keys must not be used');

  @override
  Object? remove(Object? key) => throw StateError('remove must not be used');
}
