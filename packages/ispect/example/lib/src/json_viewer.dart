import 'dart:convert';

import 'package:flutter/material.dart';

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

  bool containsSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return key.toLowerCase().contains(lowerQuery) ||
        (value != null &&
            value.toString().toLowerCase().contains(lowerQuery)) ||
        children.any((child) => child.containsSearch(query));
  }
}

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
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  List<JsonNode> filterNodes(List<JsonNode> nodes, String query) {
    return nodes
        .where((node) => node.containsSearch(query))
        .map((node) => JsonNode(
              key: node.key,
              value: node.value,
              isExpanded: node.isExpanded,
              children: filterNodes(node.children, query),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNodes = filterNodes(nodes, searchQuery);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search JSON...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredNodes.length,
            itemBuilder: (context, index) {
              return JsonNodeWidget(
                node: filteredNodes[index],
                depth: 0,
                onTap: () => toggleExpansion(filteredNodes[index]),
                searchQuery: searchQuery,
              );
            },
          ),
        ),
      ],
    );
  }
}

// presentation/widgets/json_node_widget.dart

class JsonNodeWidget extends StatelessWidget {
  final JsonNode node;
  final int depth;
  final VoidCallback onTap;
  final String searchQuery;

  const JsonNodeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.onTap,
    required this.searchQuery,
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
                _buildHighlightedText(
                  context,
                  '${node.key}: ',
                  searchQuery,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (node.children.isEmpty)
                  Flexible(
                    child: _buildHighlightedText(
                      context,
                      _formatValue(node.value),
                      searchQuery,
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
              onTap: onTap,
              searchQuery: searchQuery,
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query, {
    TextStyle? style,
    TextOverflow? overflow,
  }) {
    if (query.isEmpty) {
      return Text(text, style: style, overflow: overflow);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = lowerQuery.allMatches(lowerText);

    if (matches.isEmpty) {
      return Text(text, style: style, overflow: overflow);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            color: Colors.black,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}

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
        body: JsonViewer(
          jsonString: '''
          {
            "name": "John Doe",
            "age": 30,
            "address": {
              "street": "123 Main St",
              "city": "New York"
            },
            "hobbies": ["reading", "gaming"]
          }
          ''',
        ),
      ),
    );
  }
}
