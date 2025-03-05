// 1. Data Layer
// domain/models/json_node.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect_example/json_viewer/src/json_tree_view.dart';

class JsonNode {
  final String key;
  final dynamic value;
  bool isExpanded;
  final List<JsonNode> children;

  JsonNode({
    required this.key,
    required this.value,
    this.isExpanded = false,
    this.children = const [],
  });

  factory JsonNode.fromJson(MapEntry<String, dynamic> entry) {
    return JsonNode(
      key: entry.key,
      value: entry.value,
      children: _parseValue(entry.value),
    );
  }

  static List<JsonNode> _parseValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.entries.map((e) => JsonNode.fromJson(e)).toList();
    } else if (value is List) {
      return value
          .asMap()
          .entries
          .map((e) => JsonNode(
                key: e.key.toString(),
                value: e.value,
              ))
          .toList();
    }
    return [];
  }
}

// 2. Domain Layer
// domain/repositories/json_repository.dart
abstract class JsonRepository {
  List<JsonNode> parseJson(String jsonString);
}

// data/repositories/json_repository_impl.dart

class JsonRepositoryImpl implements JsonRepository {
  @override
  List<JsonNode> parseJson(String jsonString) {
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.entries.map((e) => JsonNode.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}

// 3. Presentation Layer
// presentation/widgets/json_viewer.dart

class JsonViewer extends StatefulWidget {
  final String jsonString;

  const JsonViewer({super.key, required this.jsonString});

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  late List<JsonNode> nodes;
  final JsonRepository jsonRepository = JsonRepositoryImpl();

  @override
  void initState() {
    super.initState();
    nodes = jsonRepository.parseJson(widget.jsonString);
  }

  void toggleExpansion(JsonNode node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return JsonNodeWidget(
          node: nodes[index],
          depth: 0,
          onTap: () => toggleExpansion(nodes[index]),
        );
      },
    );
  }
}

// presentation/widgets/json_node_widget.dart
class JsonNodeWidget extends StatelessWidget {
  final JsonNode node;
  final int depth;
  final VoidCallback onTap;

  const JsonNodeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren ? onTap : null,
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    node.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                const SizedBox(width: 4),
                Text(
                  '${node.key}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    node.children.isEmpty ? _formatValue(node.value) : '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isExpanded && hasChildren)
          ...node.children.map(
            (child) => JsonNodeWidget(
              node: child,
              depth: depth + 1,
              onTap: () => onTap(),
            ),
          ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}

// 4. Usage Example
// main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('JSON Viewer')),
        body: JsonTreeView(
          initiallyExpanded: true,
          showControls: true,
          jsonString: '''{
            "applicationName": "JSON Viewer Tester",
            "version": 1.2,
            "releaseDate": "2024-10-27",
            "isValid": true,
            "author": {
              "name": "Alex Doe",
              "email": "alex.doe@example.com",
              "organization": "Acme Software",
              "address": {
                "street": "42 Galaxy Way",
                "city": "Metropolis",
                "state": "Stateville",
                "zip": "12345",
                "country": "United Fictional Republic",
                "coordinates": {
                  "latitude": 48.8566,
                  "longitude": 2.3522,
                  "altitude": null
                }
              },
              "contactNumbers": ["+15551112222", "+15553334444"],
              "isActive": true
            },
            "features": [
              "Syntax Highlighting",
              "Collapsible Nodes",
              "Search Functionality",
              "JSON Validation",
              "Data Type Display"
            ],
            "configuration": {
              "theme": "dark",
              "fontSize": 14,
              "indentSize": 2,
              "showLineNumbers": true,
              "maxDepth": 10,
              "customColors": {
                "string": "#f1fa8c",
                "number": "#bd93f9",
                "boolean": "#ff79c6",
                "null": "#8be9fd",
                "key": "#50fa7b"
              },
              "allowedOperations": ["read", "parse", "validate"]
            },
            "data": [
              {
                "id": 1,
                "name": "Item 1",
                "description": "This is the first item.",
                "price": 19.99,
                "inStock": true,
                "tags": ["tag1", "tag2", "tag3"],
                "relatedItems": [2, 3]
              },
              {
                "id": 2,
                "name": "Item 2",
                "description": null,
                "price": 29.99,
                "inStock": false,
                "tags": ["tag2", "tag4"],
                "relatedItems": [1]
              },
              {
                "id": 3,
                "name": "Item 3",
                "description": "Another item.",
                "price": 9.99,
                "inStock": true,
                "tags": [],
                "relatedItems": [1, 2],
                "details": {
                  "weight": 0.5,
                  "dimensions": {"width": 10, "height": 5, "depth": 2}
                }
              }
            ],
            "logs": [
              {
                "timestamp": "2024-10-26T10:00:00Z",
                "level": "info",
                "message": "Application started"
              },
              {
                "timestamp": "2024-10-26T10:01:00Z",
                "level": "warn",
                "message": "Configuration file not found, using defaults",
                "details": {
                  "file_path": "/path/to/config.json",
                  "error_code": 404
                }
              },
              {
                "timestamp": "2024-10-26T10:05:00Z",
                "level": "error",
                "message": "Failed to load data",
                "details": null
              }
            ],
            "statusCodes": [200, 201, 400, 401, 403, 404, 500],
            "emptyArray": [],
            "emptyObject": {},
            "nullValue": null,
            "booleanTrue": true,
            "booleanFalse": false,
            "largeNumber": 1234567890,
            "smallNumber": 1.23e-7,
            "negativeNumber": -42,
            "longString":
                "This is a very long string to test the wrapping capabilities of the JSON viewer.  It should handle long strings gracefully without breaking the layout.",
            "unicodeCharacters": "你好世界",
            "mixedArray": [
              1,
              "two",
              true,
              null,
              {"key": "value"}
            ],
            "deeplyNested": {
              "level1": {
                "level2": {
                  "level3": {
                    "level4": {"level5": "Finally, some data!"}
                  }
                }
              }
            },
            "anotherArray": [
              {"name": "John", "age": 30, "city": "New York"},
              {"name": "Jane", "age": 25, "city": "Los Angeles"},
              {"name": "Peter", "age": 40, "city": "Chicago"}
            ],
            "lastItem": "The end"
          }''',
        ),
      ),
    );
  }
}
