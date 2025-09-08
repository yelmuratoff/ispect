import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for flattening JSON tree structures
class JsonTreeFlattener {
  /// Flattens a hierarchical JSON tree into a list for efficient rendering
  static List<NodeViewModelState> flatten(Object? object) {
    if (object == null) {
      return const <NodeViewModelState>[];
    }

    if (object is List<NodeViewModelState>) {
      return _flattenArray(object);
    }

    if (object is Map<String, NodeViewModelState>) {
      return _flattenClass(object);
    }

    return const <NodeViewModelState>[];
  }

  static List<NodeViewModelState> _flattenClass(
    Map<String, NodeViewModelState> object,
  ) {
    // Pre-allocate with estimated capacity for better performance
    final resultList = <NodeViewModelState>[];

    for (final value in object.values) {
      resultList.add(value);

      if (!value.isCollapsed) {
        final childValue = value.value;
        if (childValue is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(childValue, resultList);
        } else if (childValue is List<NodeViewModelState>) {
          _addFlattenedArrayToList(childValue, resultList);
        }
      }
    }

    return resultList;
  }

  static List<NodeViewModelState> _flattenArray(
    List<NodeViewModelState> objects,
  ) {
    final resultList = <NodeViewModelState>[];

    for (final object in objects) {
      resultList.add(object);
      if (!object.isCollapsed) {
        final childValue = object.value;
        if (childValue is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(childValue, resultList);
        }
      }
    }
    return resultList;
  }

  static void _addFlattenedClassToList(
    Map<String, NodeViewModelState> object,
    List<NodeViewModelState> flatList,
  ) {
    for (final value in object.values) {
      flatList.add(value);

      if (!value.isCollapsed) {
        final childValue = value.value;
        if (childValue is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(childValue, flatList);
        } else if (childValue is List<NodeViewModelState>) {
          _addFlattenedArrayToList(childValue, flatList);
        }
      }
    }
  }

  static void _addFlattenedArrayToList(
    List<NodeViewModelState> objects,
    List<NodeViewModelState> flatList,
  ) {
    for (final object in objects) {
      flatList.add(object);
      if (!object.isCollapsed) {
        final childValue = object.value;
        if (childValue is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(childValue, flatList);
        }
      }
    }
  }
}
