class JsonNode {
  JsonNode({
    required this.key,
    required this.value,
    required this.type,
    this.children = const [],
  });
  final String key;
  final dynamic value;
  final List<JsonNode> children;
  final JsonNodeType type;

  bool get hasChildren => children.isNotEmpty;
}

enum JsonNodeType {
  object,
  array,
  string,
  number,
  boolean,
  null_,
}
