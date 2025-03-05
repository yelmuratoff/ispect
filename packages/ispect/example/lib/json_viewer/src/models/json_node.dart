class JsonNode {
  final String key;
  final dynamic value;
  final List<JsonNode> children;
  final JsonNodeType type;
  
  JsonNode({
    required this.key,
    required this.value,
    this.children = const [],
    required this.type,
  });
  
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