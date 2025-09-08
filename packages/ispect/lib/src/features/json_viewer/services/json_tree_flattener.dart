import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for flattening JSON tree structures
class JsonTreeFlattener {
  /// Flattens a hierarchical JSON tree into a list for efficient rendering
  static List<NodeViewModelState> flatten(Object? object) {
    if (object is List) {
      return _flattenArray(object as List<NodeViewModelState>);
    }

    if (object == null) {
      return const <NodeViewModelState>[];
    }
    return _flattenClass(object as Map<String, NodeViewModelState>);
  }

  static List<NodeViewModelState> _flattenClass(
    Map<String, NodeViewModelState> object,
  ) {
    final flatList = <NodeViewModelState>[];

    object.forEach((key, value) {
      flatList.add(value);

      if (!value.isCollapsed) {
        if (value.value is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(
            value.value! as Map<String, NodeViewModelState>,
            flatList,
          );
        } else if (value.value is List) {
          _addFlattenedArrayToList(
            value.value! as List<NodeViewModelState>,
            flatList,
          );
        }
      }
    });
    return flatList;
  }

  static List<NodeViewModelState> _flattenArray(
    List<NodeViewModelState> objects,
  ) {
    final flatList = <NodeViewModelState>[];

    for (final object in objects) {
      flatList.add(object);
      if (!object.isCollapsed &&
          object.value is Map<String, NodeViewModelState>) {
        _addFlattenedClassToList(
          object.value! as Map<String, NodeViewModelState>,
          flatList,
        );
      }
    }
    return flatList;
  }

  static void _addFlattenedClassToList(
    Map<String, NodeViewModelState> object,
    List<NodeViewModelState> flatList,
  ) {
    object.forEach((key, value) {
      flatList.add(value);

      if (!value.isCollapsed) {
        if (value.value is Map<String, NodeViewModelState>) {
          _addFlattenedClassToList(
            value.value! as Map<String, NodeViewModelState>,
            flatList,
          );
        } else if (value.value is List) {
          _addFlattenedArrayToList(
            value.value! as List<NodeViewModelState>,
            flatList,
          );
        }
      }
    });
  }

  static void _addFlattenedArrayToList(
    List<NodeViewModelState> objects,
    List<NodeViewModelState> flatList,
  ) {
    for (final object in objects) {
      flatList.add(object);
      if (!object.isCollapsed &&
          object.value is Map<String, NodeViewModelState>) {
        _addFlattenedClassToList(
          object.value! as Map<String, NodeViewModelState>,
          flatList,
        );
      }
    }
  }
}
