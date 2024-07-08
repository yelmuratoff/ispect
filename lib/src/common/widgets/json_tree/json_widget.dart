// Copyright 2020 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/models/json_node.dart';
import 'package:ispect/src/common/utils/copy_json_nodes.dart';
import 'package:ispect/src/common/utils/json_node_content.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/json_nodes_widget.dart';

/// Json view with collapsible and expandable nodes.
class JsonWidget extends StatefulWidget {
  const JsonWidget({
    this.indentLeftEndJsonNode = 14,
    this.indentWidth = 20,
    this.indentHeight = 20,
    this.jsonController,
    this.json,
    this.jsonNodes,
    this.iconOpened,
    this.iconClosed,
    this.keyColor,
    super.key,
  }) : assert(json != null || jsonNodes != null, 'Must pass json or jsonNode');

  /// Horizontal indent between levels.
  final double indentWidth;

  /// Vertical indent between levels.
  final double indentHeight;

  /// The starting position of the ending node.
  /// Recommended size is the size of the icon.
  final double indentLeftEndJsonNode;

  /// Json controller to manage the tree state.
  final JsonController? jsonController;

  /// Parsed json
  final Map<String, dynamic>? json;

  /// List of root level json nodes.
  final List<JsonNode>? jsonNodes;

  /// Custom icons for opening and closing a node
  final Widget? iconOpened;
  final Widget? iconClosed;

  final Color? keyColor;

  @override
  State createState() => _JsonWidgetState();
}

class _JsonWidgetState extends State<JsonWidget> {
  // ignore: avoid_public_members_in_states
  late final List<JsonNode> jsonNodes;

  @override
  void initState() {
    super.initState();

    if (widget.jsonNodes != null) {
      jsonNodes = copyJsonNodes(widget.jsonNodes);
    } else {
      jsonNodes = copyJsonNodes(_toJsonNodes(widget.json));
    }
  }

  @override
  Widget build(BuildContext context) => JsonNodesWidget(
        jsonNodes: jsonNodes,
        state: widget.jsonController ?? JsonController(),
        indentLeftEndJsonNode: widget.indentLeftEndJsonNode,
        indentWidth: widget.indentWidth,
        indentHeight: widget.indentHeight,
        iconOpened: widget.iconOpened,
        iconClosed: widget.iconClosed,
        isDefaultExpanded: true,
        underTree: 1,
      );

  /// Create Nodes
  List<JsonNode> _toJsonNodes(Object? parsedJson) {
    /// Create Map Nodes
    if (parsedJson is Map) {
      return parsedJson.entries.map((k) {
        List<JsonNode>? children;

        /// If the item is a List or a Map then create a node
        /// with nesting otherwise create a node without nesting
        children = parsedJson[k.key] is Map || parsedJson[k.key] is List
            ? _toJsonNodes(parsedJson[k.key])
            : null;

        return JsonNode(
          content: JsonNodeContent(
            keyValue: '${k.key}: ',
            value: k.value,
            keyColor: widget.keyColor,
          ),
          children: children,
        );
      }).toList();
    }

    /// Create List Nodes
    if (parsedJson is List) {
      return parsedJson
          .asMap()
          .map((i, element) {
            List<JsonNode>? children;

            /// If the item is a List or a Map then create a node
            /// with nesting otherwise create a node without nesting
            children = element is Map || element is List
                ? _toJsonNodes(element)
                : null;

            return MapEntry(
              i,
              JsonNode(
                content: JsonNodeContent(
                  keyValue: '[$i]:  ',
                  value: element,
                  keyColor: widget.keyColor,
                ),
                children: children,
              ),
            );
          })
          .values
          .toList();
    }

    return [JsonNode(content: Text(parsedJson.toString()))];
  }
}
