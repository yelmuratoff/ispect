// ignore_for_file: comment_references

import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/json_controller.dart';
import 'package:ispect/src/common/models/json_node.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/json_node_widget.dart';

/// Builds set of [jsonNodes] respecting [state], [indent] and [_iconSize].
class JsonNodesWidget extends StatelessWidget {
  const JsonNodesWidget({
    required this.jsonNodes,
    required this.state,
    required this.indentLeftEndJsonNode,
    required this.indentWidth,
    required this.indentHeight,
    required this.underTree,
    this.isDefaultExpanded = false,
    this.iconOpened,
    this.iconClosed,
    super.key,
  });

  final Iterable<JsonNode> jsonNodes;
  final JsonController state;
  final double indentLeftEndJsonNode;
  final double indentWidth;
  final double indentHeight;
  final int underTree;
  final bool isDefaultExpanded;
  final Widget? iconOpened;
  final Widget? iconClosed;

  @override
  Widget build(BuildContext context) {
    if (underTree <= state.uncovered) {
      for (final jsonNode in jsonNodes) {
        if (state.isHasExpanded(jsonNode.key!) == null) {
          state.expandJsonNode(jsonNode.key!);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final jsonNode in jsonNodes)
          JsonNodeWidget(
            jsonNode: jsonNode,
            state: state,
            indentLeftEndNode: indentLeftEndJsonNode,
            indentWidth: indentWidth,
            indentHeight: indentHeight,
            iconOpened: iconOpened,
            iconClosed: iconClosed,
            underTree: underTree + 1,
          ),
      ],
    );
  }
}
