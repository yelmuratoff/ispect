import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';

/// A utility class for parsing raw JSON data into a [JsonNode] tree structure.
///
/// The [JsonParser] supports recursive parsing of:
/// - Maps (objects)
/// - Lists (arrays)
/// - Primitives (strings, numbers, booleans)
/// - Null values
///
/// Each node includes its [key], [value], inferred [JsonNodeType],
/// and child nodes if applicable.
class JsonParser {
  /// Recursively parses JSON [data] into a [JsonNode] tree.
  ///
  /// The [key] parameter represents the current node's key (used during recursion).
  ///
  /// ### Behavior:
  /// - If [data] is `null`, a node of type [JsonNodeType.null_] is returned.
  /// - If [data] is a [Map], each key-value pair is parsed into child nodes.
  /// - If [data] is a [List], each element is parsed with a key like `"[0]"`, `"[1]"`, etc.
  /// - If [data] is a primitive (String, num, bool), a single leaf node is created.
  /// - Any unrecognized type is converted to a string and stored as [JsonNodeType.string].
  ///
  /// ### Parameters:
  /// - [data]: The raw JSON value to parse.
  /// - [key]: (Optional) The key for this node; defaults to `'root'`.
  ///
  /// ### Returns:
  /// A fully-formed [JsonNode] that may contain child nodes depending on the input structure.
  static JsonNode parse(Object? data, [String key = 'root']) {
    if (data == null) {
      return JsonNode(
        key: key,
        value: 'null',
        type: JsonNodeType.null_,
      );
    }

    if (data is Map) {
      final children = <JsonNode>[];
      data.forEach((k, v) {
        children.add(parse(v, k.toString()));
      });
      return JsonNode(
        key: key,
        value: data,
        children: children,
        type: JsonNodeType.object,
      );
    }

    if (data is List) {
      final children = <JsonNode>[];
      for (var i = 0; i < data.length; i++) {
        children.add(parse(data[i], '[$i]'));
      }
      return JsonNode(
        key: key,
        value: data,
        children: children,
        type: JsonNodeType.array,
      );
    }

    if (data is String) {
      return JsonNode(
        key: key,
        value: data,
        type: JsonNodeType.string,
      );
    }

    if (data is num) {
      return JsonNode(
        key: key,
        value: data,
        type: JsonNodeType.number,
      );
    }

    if (data is bool) {
      return JsonNode(
        key: key,
        value: data,
        type: JsonNodeType.boolean,
      );
    }

    return JsonNode(
      key: key,
      value: data.toString(),
      type: JsonNodeType.string,
    );
  }
}
