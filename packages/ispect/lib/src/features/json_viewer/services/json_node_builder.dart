import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for building JSON view model nodes
class JsonNodeBuilder {
  /// Builds view model nodes from raw JSON object
  static Map<String, NodeViewModelState> buildViewModelNodes(Object? object) {
    if (object is Map<String, dynamic>) {
      return _buildClassNodes(object: object);
    }
    return _buildClassNodes(object: <String, dynamic>{'data': object});
  }

  /// Builds class nodes from Map efficiently
  static Map<String, NodeViewModelState> _buildClassNodes({
    required Map<String, dynamic> object,
    int treeDepth = 0,
    NodeViewModelState? parent,
  }) {
    final map = <String, NodeViewModelState>{};

    for (final entry in object.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map) {
        final classNode = NodeViewModelState.fromClass(
          treeDepth: treeDepth,
          key: key,
          parent: parent,
          rawValue: value,
        );

        final children = _buildClassNodes(
          object: value.cast<String, dynamic>(),
          treeDepth: treeDepth + 1,
          parent: classNode,
        );

        classNode.value = children;
        map[key] = classNode;
      } else if (value is List) {
        final arrayNode = NodeViewModelState.fromArray(
          treeDepth: treeDepth,
          key: key,
          parent: parent,
          rawValue: value,
        );

        final children = _buildArrayNodes(
          object: value,
          treeDepth: treeDepth,
          parent: arrayNode,
        );

        arrayNode.value = children;
        map[key] = arrayNode;
      } else {
        map[key] = NodeViewModelState.fromProperty(
          key: key,
          value: value,
          treeDepth: treeDepth,
          parent: parent,
          rawValue: value,
        );
      }
    }

    return map;
  }

  /// Builds array nodes from List
  static List<NodeViewModelState> _buildArrayNodes({
    required List<dynamic> object,
    int treeDepth = 0,
    NodeViewModelState? parent,
  }) {
    final array = <NodeViewModelState>[];

    for (var i = 0; i < object.length; i++) {
      final dynamic arrayValue = object[i];

      if (arrayValue is Map<String, dynamic>) {
        final classNode = NodeViewModelState.fromClass(
          key: i.toString(),
          treeDepth: treeDepth + 1,
          parent: parent,
          rawValue: arrayValue,
        );

        final children = _buildClassNodes(
          object: arrayValue,
          treeDepth: treeDepth + 2,
          parent: classNode,
        );

        classNode.value = children;
        array.add(classNode);
      } else {
        array.add(
          NodeViewModelState.fromProperty(
            key: i.toString(),
            value: arrayValue,
            treeDepth: treeDepth + 1,
            parent: parent,
            rawValue: arrayValue,
          ),
        );
      }
    }

    return array;
  }
}
