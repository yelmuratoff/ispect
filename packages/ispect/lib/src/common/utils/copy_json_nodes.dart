import 'package:ispect/src/common/controllers/providers/key_provider.dart';
import 'package:ispect/src/common/models/json_node.dart';

/// Copies nodes to unmodifiable list, assigning missing keys and checking for duplicates.
List<JsonNode> copyJsonNodes(List<JsonNode>? jsonNodes) =>
    _copyJsonNodesRecursively(jsonNodes, KeyProvider())!;

List<JsonNode>? _copyJsonNodesRecursively(
  List<JsonNode>? jsonNodes,
  KeyProvider keyProvider,
) {
  if (jsonNodes == null) {
    return null;
  }

  return List.unmodifiable(
    jsonNodes.map(
      (n) => JsonNode(
        key: keyProvider.key(n.key),
        content: n.content,
        children: _copyJsonNodesRecursively(n.children, keyProvider),
      ),
    ),
  );
}
