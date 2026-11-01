import 'package:ispect/src/features/json_viewer/models/json_outline.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

abstract final class JsonOutlineResolver {
  static void fold(
    List<List<String>> paths,
    Map<String, NodeViewModelState> roots,
  ) {
    for (final path in paths) {
      final node = nodeAt(roots, path);
      if (node != null && node.isRoot) node.collapse();
    }
  }

  /// The [landmarks] present under [roots], each paired with the node of its
  /// first path that leads to a non-empty value.
  static List<ResolvedJsonLandmark> resolve(
    List<JsonLandmark> landmarks,
    Map<String, NodeViewModelState> roots,
  ) => [
    for (final landmark in landmarks)
      if (_find(landmark, roots) case final node?)
        (landmark: landmark, node: node),
  ];

  static NodeViewModelState? nodeAt(
    Map<String, NodeViewModelState> roots,
    List<String> path,
  ) {
    Object? level = roots;
    NodeViewModelState? node;
    for (final key in path) {
      if (level is! Map<String, NodeViewModelState>) return null;
      node = level[key];
      if (node == null) return null;
      level = node.value;
    }
    return node;
  }

  static NodeViewModelState? _find(
    JsonLandmark landmark,
    Map<String, NodeViewModelState> roots,
  ) {
    for (final path in landmark.paths) {
      final node = nodeAt(roots, path);
      if (node != null && _hasContent(node)) return node;
    }
    return null;
  }

  static bool _hasContent(NodeViewModelState node) =>
      node.isRoot ? node.children.isNotEmpty : node.value != null;
}
