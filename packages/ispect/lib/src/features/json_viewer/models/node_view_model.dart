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
      );

  /// Build a `NodeViewModelState` as a class.
  factory NodeViewModelState.fromClass({
    required int treeDepth,
    required String key,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        isClass: true,
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
        isArray: true,
        key: key,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );

  NodeViewModelState._({
    required this.treeDepth,
    required this.key,
    required this.rawValue,
    this.isClass = false,
    this.isArray = false,
    this.value,
    this.parent,
  }) : isRoot = isClass || isArray;

  final String key;
  final int treeDepth;
  final bool isClass;
  final bool isArray;
  final bool isRoot;
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
  Iterable<NodeViewModelState> get children {
    if (isClass && value is Map<String, NodeViewModelState>) {
      return (value! as Map<String, NodeViewModelState>).values;
    } else if (isArray && value is List<NodeViewModelState>) {
      return value! as List<NodeViewModelState>;
    }
    return const <NodeViewModelState>[];
  }
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
