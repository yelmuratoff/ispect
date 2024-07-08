import 'package:flutter/foundation.dart';

/// A controller for a tree state.
///
/// Allows to modify the state of the tree.
class JsonController {
  JsonController({
    this.allNodesExpanded = true,
    this.uncovered = 1,
  });

  /// Sets whether the json tree is expanded by default
  bool allNodesExpanded;

  /// Sets the value to what nesting by default the json tree will be expanded
  int uncovered;
  final Map<Key, bool> _expanded = <Key, bool>{};

  bool isJsonExpanded(Key key) => _expanded[key] ?? allNodesExpanded;

  bool? isHasExpanded(Key key) => _expanded[key];

  void toggleJsonExpanded(Key key) {
    _expanded[key] = !isJsonExpanded(key);
  }

  void expandAll() {
    allNodesExpanded = true;
    for (final element in _expanded.entries) {
      _expanded[element.key] = true;
    }
  }

  void collapseAll() {
    allNodesExpanded = false;
    for (final element in _expanded.entries) {
      _expanded[element.key] = false;
    }
  }

  void expandJsonNode(Key key) {
    _expanded[key] = true;
  }

  void collapseJsonNode(Key key) {
    _expanded[key] = false;
  }
}
