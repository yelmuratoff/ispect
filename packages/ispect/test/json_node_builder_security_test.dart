import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_node_builder.dart';

void main() {
  Iterable<NodeViewModelState> allNodes(
    Iterable<NodeViewModelState> roots,
  ) sync* {
    final pending = roots.toList();
    while (pending.isNotEmpty) {
      final node = pending.removeLast();
      yield node;
      pending.addAll(node.children);
    }
  }

  test('builds reasonable decoded JSON normally', () {
    final nodes = JsonNodeBuilder.buildViewModelNodes({
      'profile': {
        'name': 'Ada',
        'roles': ['admin', 'reviewer'],
      },
    });

    expect(nodes['profile']?.isClass, true);
    expect(nodes['profile']?.children, hasLength(2));
  });

  test('preserves a safe marker for decoded JSON beyond the depth budget', () {
    Object? nested = 'leaf';
    for (var i = 0; i <= JsonNodeBuilder.maxBuildDepth; i++) {
      nested = <Object?>[nested];
    }

    final nodes = JsonNodeBuilder.buildViewModelNodes(nested);

    expect(
      allNodes(nodes.values).map((node) => node.value),
      contains(JsonInputPreflight.maxDepthReached),
    );
  });

  test('stops building at the node budget with a safe marker', () {
    final wide = List<Object?>.filled(JsonNodeBuilder.maxBuildNodes + 1, null);

    final nodes = JsonNodeBuilder.buildViewModelNodes(wide);
    final flattened = allNodes(nodes.values).toList();

    expect(
      flattened,
      hasLength(lessThanOrEqualTo(JsonNodeBuilder.maxBuildNodes)),
    );
    expect(
      flattened.map((node) => node.value),
      contains(JsonInputPreflight.maxNodesReached),
    );
  });

  test('replaces cyclic decoded containers with a safe marker', () {
    final cyclic = <Object?>[];
    cyclic.add(cyclic);

    final nodes = JsonNodeBuilder.buildViewModelNodes(cyclic);

    expect(
      allNodes(nodes.values).map((node) => node.value),
      contains(JsonInputPreflight.circularReference),
    );
  });

  test('does not retain or stringify hostile leaves', () {
    final hostile = _HostileLeaf();

    final nodes = JsonNodeBuilder.buildViewModelNodes(<String, Object?>{
      'hostile': hostile,
    });
    final node = nodes['hostile']!;

    expect(node.value, isA<String>());
    expect(node.rawValue, isA<String>());
    expect(node.rawValue, isNot(same(hostile)));
    expect(hostile.toStringCalls, 0);
  });
}

final class _HostileLeaf {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('node building must not stringify hostile leaves');
  }
}
