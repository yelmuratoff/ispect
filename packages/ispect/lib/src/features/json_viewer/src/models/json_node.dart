/// A model representing a single node in a parsed JSON tree.
///
/// Each [JsonNode] contains a key, value, a list of optional children
/// (used for arrays and objects), and a [JsonNodeType] describing the data.
///
/// This class is used by the JSON viewer to build and render expandable/collapsible
/// tree structures.
///
/// ### Example:
/// ```dart
/// final node = JsonNode(
///   key: 'name',
///   value: 'Alice',
///   type: JsonNodeType.string,
/// );
///
/// final listNode = JsonNode(
///   key: 'items',
///   value: [1, 2, 3],
///   type: JsonNodeType.array,
///   children: [
///     JsonNode(key: '[0]', value: 1, type: JsonNodeType.number),
///     JsonNode(key: '[1]', value: 2, type: JsonNodeType.number),
///     JsonNode(key: '[2]', value: 3, type: JsonNodeType.number),
///   ],
/// );
/// ```
class JsonNode {
  /// Creates a [JsonNode] with the given [key], [value], [type], and optional [children].
  JsonNode({
    required this.key,
    required this.value,
    required this.type,
    this.children = const [],
  });

  /// The unique key of the node (e.g. field name or list index).
  final String key;

  /// The value represented by this node (can be primitive, list, or map).
  final dynamic value;

  /// The child nodes, if any (used when the type is [JsonNodeType.object] or [JsonNodeType.array]).
  final List<JsonNode> children;

  /// The type of the value, used to determine rendering and color.
  final JsonNodeType type;

  /// Whether this node has one or more children.
  bool get hasChildren => children.isNotEmpty;
}

/// Describes the type of a [JsonNode]'s value for rendering and parsing purposes.
enum JsonNodeType {
  /// Represents a JSON object (`Map<String, dynamic>`).
  object,

  /// Represents a JSON array (`List<dynamic>`).
  array,

  /// Represents a string value.
  string,

  /// Represents a numeric value.
  number,

  /// Represents a boolean value.
  boolean,

  /// Represents a null value.
  null_,
}
