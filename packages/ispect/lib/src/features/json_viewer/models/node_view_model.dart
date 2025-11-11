import 'package:flutter/widgets.dart';

/// A view model state that represents a single node item in a json object tree.
/// A decoded json object can be converted to a `NodeViewModelState` by calling
/// the `buildViewModelNodes` method.
class NodeViewModelState extends ChangeNotifier {
  /// Build a `NodeViewModelState` as a property.
  factory NodeViewModelState.fromProperty({
    required int treeDepth,
    required String key,
    required Object? value,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        key: key,
        value: value,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
        kind: const NodeKind.property(),
      );

  /// Build a `NodeViewModelState` as a class.
  factory NodeViewModelState.fromClass({
    required int treeDepth,
    required String key,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        kind: const NodeKind.object(),
        key: key,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );

  /// Build a `NodeViewModelState` as an array.
  factory NodeViewModelState.fromArray({
    required int treeDepth,
    required String key,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        kind: const NodeKind.array(),
        key: key,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );

  NodeViewModelState._({
    required this.treeDepth,
    required this.key,
    required this.rawValue,
    required this.kind,
    this.value,
    this.parent,
  });

  final String key;
  final int treeDepth;
  final NodeKind kind;
  bool get isClass => kind.isClass;
  bool get isArray => kind.isArray;
  bool get isRoot => kind.isRoot;
  final NodeViewModelState? parent;
  final Object? rawValue;

  Object? value;
  bool isCollapsed = false;
  bool isHighlighted = false;
  bool isFocused = false;

  /// Collapses this node so its children won't be visible.
  void collapse() {
    isCollapsed = true;
    notifyListeners();
  }

  /// Expands this node so its children become visible.
  void expand() {
    isCollapsed = false;
    notifyListeners();
  }

  /// Highlights this node.
  void highlight({bool isHighlighted = true}) {
    this.isHighlighted = isHighlighted;
    notifyListeners();
  }

  /// Focuses this node.
  void focus({bool isFocused = true}) {
    this.isFocused = isFocused;
    notifyListeners();
  }

  /// Gets the children of this node.
  Iterable<NodeViewModelState> get children => switch ((kind, value)) {
        (ClassNodeKind(), final Map<String, NodeViewModelState> map) =>
          map.values,
        (ArrayNodeKind(), final List<NodeViewModelState> list) => list,
        _ => const <NodeViewModelState>[],
      };
}

/// A matched search in the given `node`.
class SearchResult {
  const SearchResult(
    this.node, {
    required this.matchLocation,
    required this.matchIndex,
  });

  final NodeViewModelState node;
  final SearchMatchLocation matchLocation;
  final int matchIndex;
}

/// The location of the search match in a node.
enum SearchMatchLocation {
  key,
  value,
}

sealed class NodeKind {
  const NodeKind();

  const factory NodeKind.property() = PropertyNodeKind;
  const factory NodeKind.object() = ClassNodeKind;
  const factory NodeKind.array() = ArrayNodeKind;

  bool get isClass => this is ClassNodeKind;
  bool get isArray => this is ArrayNodeKind;
  bool get isRoot => isClass || isArray;
}

final class PropertyNodeKind extends NodeKind {
  const PropertyNodeKind();
}

final class ClassNodeKind extends NodeKind {
  const ClassNodeKind();
}

final class ArrayNodeKind extends NodeKind {
  const ArrayNodeKind();
}
