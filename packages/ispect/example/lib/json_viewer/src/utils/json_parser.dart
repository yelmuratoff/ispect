import '../models/json_node.dart';

class JsonParser {
  static JsonNode parse(dynamic data, [String key = 'root']) {
    if (data == null) {
      return JsonNode(
        key: key,
        value: 'null',
        type: JsonNodeType.null_,
      );
    }

    if (data is Map) {
      final children = <JsonNode>[];
      data.forEach((key, value) {
        children.add(parse(value, key.toString()));
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