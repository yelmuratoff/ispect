import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for flattening JSON tree structures
class JsonTreeFlattener {
  /// Flattens a hierarchical JSON tree into a list for efficient rendering
  static List<NodeViewModelState> flatten(Object? object) => switch (object) {
        null => const <NodeViewModelState>[],
        final List<NodeViewModelState> list =>
          _flattenIterable(list),
        final Map<String, NodeViewModelState> map =>
          _flattenIterable(map.values),
        _ => const <NodeViewModelState>[],
      };

  static List<NodeViewModelState> _flattenIterable(
    Iterable<NodeViewModelState> nodes,
  ) {
    final resultList = <NodeViewModelState>[];

    for (final node in nodes) {
      resultList.add(node);
      if (_shouldExpand(node)) {
        _addFlattenedChildren(node, resultList);
      }
    }

    return resultList;
  }

  static void _addFlattenedChildren(
    NodeViewModelState node,
    List<NodeViewModelState> flatList,
  ) {
    for (final child in node.children) {
      flatList.add(child);
      if (_shouldExpand(child)) {
        _addFlattenedChildren(child, flatList);
      }
    }
  }

  static bool _shouldExpand(NodeViewModelState node) =>
      node.isRoot && !node.isCollapsed;
}
