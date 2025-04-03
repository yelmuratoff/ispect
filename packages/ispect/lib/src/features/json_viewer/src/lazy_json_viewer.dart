// import 'package:flutter/material.dart';

// class LazyJsonViewer extends StatefulWidget {
//   const LazyJsonViewer({
//     required this.json,
//     this.initialExpandedLevel = 1,
//     this.maxInitialChildren = 100,
//     super.key,
//   });

//   final Map<String, dynamic> json;
//   final int initialExpandedLevel;
//   final int maxInitialChildren;

//   @override
//   State<LazyJsonViewer> createState() => _LazyJsonViewerState();
// }

// class _LazyJsonViewerState extends State<LazyJsonViewer> {
//   late final List<_JsonNode> _rootNodes;

//   @override
//   void initState() {
//     super.initState();
//     _rootNodes = _buildNodes(widget.json);
//   }

//   List<_JsonNode> _buildNodes(Map<String, dynamic> json) {
//     final nodes = <_JsonNode>[];
//     for (final entry in json.entries) {
//       nodes.add(_JsonNode(
//         key: entry.key,
//         value: entry.value,
//         level: 0,
//         initialExpandedLevel: widget.initialExpandedLevel,
//         maxInitialChildren: widget.maxInitialChildren,
//       ));
//     }
//     return nodes;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _JsonTree(nodes: _rootNodes);
//   }
// }

// class _JsonTree extends StatelessWidget {
//   const _JsonTree({required this.nodes});

//   final List<_JsonNode> nodes;

//   @override
//   Widget build(BuildContext context) {
//     // Using ListView.builder for lazy loading of items
//     return ListView.builder(
//       itemCount: nodes.length,
//       cacheExtent: 1000, // Cache more items for smoother scrolling
//       itemBuilder: (context, index) {
//         return _JsonNodeWidget(node: nodes[index]);
//       },
//     );
//   }
// }

// class _JsonNode {
//   _JsonNode({
//     required this.key,
//     required this.value,
//     required this.level,
//     int initialExpandedLevel = 1,
//     int maxInitialChildren = 100,
//     this.expanded = false,
//   }) : _maxInitialChildren = maxInitialChildren {
//     // Auto-expand up to initialExpandedLevel
//     if (level < initialExpandedLevel) {
//       expanded = true;
//     }
//   }

//   final String key;
//   final dynamic value;
//   final int level;
//   final int _maxInitialChildren;
//   bool expanded;
//   List<_JsonNode>? _childNodes;
//   bool _hasMoreChildren = false;
//   int _loadedChildrenCount = 0;

//   bool get isExpandable => value is Map || value is List;
//   bool get hasMoreChildren => _hasMoreChildren;

//   // Lazy initialization of child nodes only when needed, with pagination
//   List<_JsonNode> get childNodes {
//     if (_childNodes != null) return _childNodes!;

//     _childNodes = <_JsonNode>[];
//     if (value is Map) {
//       final map = value as Map<dynamic, dynamic>;
//       final entries = map.entries.toList();

//       _loadedChildrenCount = entries.length > _maxInitialChildren
//           ? _maxInitialChildren
//           : entries.length;

//       for (int i = 0; i < _loadedChildrenCount; i++) {
//         final entry = entries[i];
//         _childNodes!.add(_JsonNode(
//           key: entry.key.toString(),
//           value: entry.value,
//           level: level + 1,
//           maxInitialChildren: _maxInitialChildren,
//         ));
//       }

//       _hasMoreChildren = entries.length > _loadedChildrenCount;
//     } else if (value is List) {
//       final list = value as List;

//       _loadedChildrenCount =
//           list.length > _maxInitialChildren ? _maxInitialChildren : list.length;

//       for (int i = 0; i < _loadedChildrenCount; i++) {
//         _childNodes!.add(_JsonNode(
//           key: i.toString(),
//           value: list[i],
//           level: level + 1,
//           maxInitialChildren: _maxInitialChildren,
//         ));
//       }

//       _hasMoreChildren = list.length > _loadedChildrenCount;
//     }
//     return _childNodes!;
//   }

//   void loadMoreChildren(int count) {
//     if (!_hasMoreChildren || _childNodes == null) return;

//     if (value is Map) {
//       final map = value as Map<dynamic, dynamic>;
//       final entries = map.entries.toList();
//       final nextBatchSize = _loadedChildrenCount + count > entries.length
//           ? entries.length - _loadedChildrenCount
//           : count;

//       for (int i = _loadedChildrenCount;
//           i < _loadedChildrenCount + nextBatchSize;
//           i++) {
//         final entry = entries[i];
//         _childNodes!.add(_JsonNode(
//           key: entry.key.toString(),
//           value: entry.value,
//           level: level + 1,
//           maxInitialChildren: _maxInitialChildren,
//         ));
//       }

//       _loadedChildrenCount += nextBatchSize;
//       _hasMoreChildren = entries.length > _loadedChildrenCount;
//     } else if (value is List) {
//       final list = value as List;
//       final nextBatchSize = _loadedChildrenCount + count > list.length
//           ? list.length - _loadedChildrenCount
//           : count;

//       for (int i = _loadedChildrenCount;
//           i < _loadedChildrenCount + nextBatchSize;
//           i++) {
//         _childNodes!.add(_JsonNode(
//           key: i.toString(),
//           value: list[i],
//           level: level + 1,
//           maxInitialChildren: _maxInitialChildren,
//         ));
//       }

//       _loadedChildrenCount += nextBatchSize;
//       _hasMoreChildren = list.length > _loadedChildrenCount;
//     }
//   }

//   int get childrenCount {
//     if (value is Map) {
//       return (value as Map).length;
//     } else if (value is List) {
//       return (value as List).length;
//     }
//     return 0;
//   }

//   String get displayValue {
//     if (value == null) return 'null';
//     if (value is String) return '"${value.toString()}"';
//     if (value is Map) return '{${(value as Map).length}}';
//     if (value is List) return '[${(value as List).length}]';
//     return value.toString();
//   }
// }

// class _JsonNodeWidget extends StatefulWidget {
//   const _JsonNodeWidget({required this.node});

//   final _JsonNode node;

//   @override
//   State<_JsonNodeWidget> createState() => _JsonNodeWidgetState();
// }

// class _JsonNodeWidgetState extends State<_JsonNodeWidget> {
//   static const int _loadMoreBatchSize = 50;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         InkWell(
//           onTap: widget.node.isExpandable ? _toggleExpanded : null,
//           child: Padding(
//             padding: EdgeInsets.only(left: widget.node.level * 16.0),
//             child: Row(
//               children: [
//                 if (widget.node.isExpandable) ...[
//                   Icon(
//                     widget.node.expanded
//                         ? Icons.keyboard_arrow_down
//                         : Icons.keyboard_arrow_right,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 4),
//                 ] else
//                   const SizedBox(width: 20),
//                 Text(
//                   '"${widget.node.key}": ',
//                   style: const TextStyle(
//                     color: Colors.purple,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     widget.node.displayValue,
//                     style: TextStyle(
//                       color: _getValueColor(widget.node.value),
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (widget.node.expanded && widget.node.isExpandable) _buildChildren(),
//       ],
//     );
//   }

//   Color _getValueColor(dynamic value) {
//     if (value == null) return Colors.grey;
//     if (value is String) return Colors.green;
//     if (value is num) return Colors.blue;
//     if (value is bool) return Colors.orange;
//     return Colors.black;
//   }

//   Widget _buildChildren() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.node.childrenCount > 100)
//           _buildVirtualizedChildren()
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: widget.node.childNodes.length,
//             itemBuilder: (context, index) {
//               return _JsonNodeWidget(node: widget.node.childNodes[index]);
//             },
//           ),
//         if (widget.node.hasMoreChildren)
//           Padding(
//             padding: EdgeInsets.only(left: widget.node.level * 16.0 + 20),
//             child: TextButton(
//               onPressed: _loadMoreChildren,
//               child: const Text('Load more...'),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildVirtualizedChildren() {
//     return SizedBox(
//       height: 300, // Fixed height for virtualized list
//       child: ListView.builder(
//         // This allows independent scrolling for large child lists
//         physics: const ClampingScrollPhysics(),
//         itemCount: widget.node.childNodes.length,
//         itemBuilder: (context, index) {
//           return _JsonNodeWidget(node: widget.node.childNodes[index]);
//         },
//       ),
//     );
//   }

//   void _toggleExpanded() {
//     setState(() {
//       widget.node.expanded = !widget.node.expanded;
//     });
//   }

//   void _loadMoreChildren() {
//     setState(() {
//       widget.node.loadMoreChildren(_loadMoreBatchSize);
//     });
//   }
// }
