import 'dart:async';
import 'package:flutter/foundation.dart';
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
  /// Checks if isolates should be used (based on platform and data size)
  static bool get _shouldUseIsolates {
    // For web platform, don't use compute/isolates due to limitations
    // Web workers have different behavior and potential compatibility issues
    if (kIsWeb) return false;

    // On other platforms, use isolates freely
    return true;
  }

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

  /// Asynchronously parses JSON data to prevent UI blocking.
  ///
  /// This should be used for large JSON structures that might cause UI freezes.
  /// On supported platforms, it uses Flutter's [compute] function to run parsing
  /// in a separate isolate. On web, it uses a workaround with microtasks.
  ///
  /// ### Parameters:
  /// - [data]: The raw JSON data to parse.
  /// - [key]: The key for the root node.
  ///
  /// ### Returns:
  /// A [Future] that completes with the parsed [JsonNode] tree.
  static Future<JsonNode> parseAsync(
    Object? data, [
    String key = 'root',
  ]) async {
    // For small data structures, don't bother with async
    if (_isSmallData(data)) {
      return parse(data, key);
    }

    // Use isolates on supported platforms
    if (_shouldUseIsolates) {
      return compute(_parseInIsolate, _ParseParams(data, key));
    }

    // For web, use a custom async approach that doesn't require isolates
    return _parseAsyncWeb(data, key);
  }

  /// Web-friendly version of parseAsync that uses microtasks instead of isolates
  static Future<JsonNode> _parseAsyncWeb(
    Object? data, [
    String key = 'root',
  ]) async {
    // Give the UI thread a chance to update before heavy processing
    await Future.microtask(() {});

    // Allow multiple frames to render by splitting work
    final completer = Completer<JsonNode>();

    // Create a placeholder result that will be populated
    JsonNode result;

    // Use a scheduled microtask to perform parsing without blocking the UI
    scheduleMicrotask(() async {
      // For large data, we'll chunk the parsing process
      if (data is Map && data.length > 100) {
        final tempMap = <String, dynamic>{};
        var count = 0;

        for (final entry in data.entries) {
          tempMap[entry.key.toString()] = entry.value;
          count++;

          // Every 50 items, yield to the UI thread
          if (count % 50 == 0) {
            await Future.microtask(() {});
          }
        }

        result = parse(tempMap, key);
      } else if (data is List && data.length > 200) {
        final tempList = <dynamic>[];
        var count = 0;

        for (final item in data) {
          tempList.add(item);
          count++;

          // Every 50 items, yield to the UI thread
          if (count % 50 == 0) {
            await Future.microtask(() {});
          }
        }

        result = parse(tempList, key);
      } else {
        result = parse(data, key);
      }

      completer.complete(result);
    });

    return completer.future;
  }

  /// Helper method to determine if data is small enough to parse synchronously
  static bool _isSmallData(Object? data) {
    if (data == null) return true;
    if (data is Map) return data.length < 50;
    if (data is List) return data.length < 100;
    return true;
  }

  /// Worker function executed in the isolate for parseAsync
  static JsonNode _parseInIsolate(_ParseParams params) =>
      parse(params.data, params.key);

  /// Lazily parses JSON data into a [JsonNode] tree, limiting the initial child count.
  ///
  /// Unlike [parse], this method only parses a limited number of children for maps
  /// and arrays, making it suitable for handling very large JSON structures without
  /// freezing the UI. The remaining children can be loaded later using [loadMoreChildren].
  ///
  /// ### Parameters:
  /// - [data]: The raw JSON value to parse.
  /// - [key]: (Optional) The key for this node; defaults to `'root'`.
  /// - [initialLimit]: Maximum number of child nodes to parse initially (default: 100).
  ///
  /// ### Returns:
  /// A partially loaded [JsonNode] that contains only the first [initialLimit] children.
  static JsonNode parseLazily(
    Object? data, {
    String key = 'root',
    int initialLimit = 100,
  }) {
    if (data == null) {
      return JsonNode(
        key: key,
        value: 'null',
        type: JsonNodeType.null_,
      );
    }

    if (data is Map) {
      final children = <JsonNode>[];
      final entries = data.entries.toList();
      final totalChildCount = entries.length;

      // Only process up to initialLimit items
      final processCount =
          entries.length > initialLimit ? initialLimit : entries.length;

      for (var i = 0; i < processCount; i++) {
        final entry = entries[i];
        children.add(
          parseLazily(
            entry.value,
            key: entry.key.toString(),
            initialLimit: initialLimit,
          ),
        );
      }

      return JsonNode(
        key: key,
        value: data,
        children: children,
        type: JsonNodeType.object,
        hasMoreChildren: totalChildCount > processCount,
        totalChildrenCount: totalChildCount,
      );
    }

    if (data is List) {
      final children = <JsonNode>[];
      final totalChildCount = data.length;

      // Only process up to initialLimit items
      final processCount =
          data.length > initialLimit ? initialLimit : data.length;

      for (var i = 0; i < processCount; i++) {
        children.add(
          parseLazily(
            data[i],
            key: '[$i]',
            initialLimit: initialLimit,
          ),
        );
      }

      return JsonNode(
        key: key,
        value: data,
        children: children,
        type: JsonNodeType.array,
        hasMoreChildren: totalChildCount > processCount,
        totalChildrenCount: totalChildCount,
      );
    }

    // For primitive values, just use regular parse
    return parse(data, key);
  }

  /// Asynchronously parses JSON data lazily, handling large data structures
  ///
  /// This combines the benefits of lazy loading and async processing
  /// for the best performance with large JSON structures.
  ///
  /// ### Parameters:
  /// - [data]: The raw JSON data to parse.
  /// - [key]: The key for the root node (default: 'root').
  /// - [initialLimit]: Maximum initial children to parse (default: 100).
  ///
  /// ### Returns:
  /// A [Future] that completes with a partially loaded [JsonNode] tree.
  static Future<JsonNode> parseLazilyAsync(
    Object? data, {
    String key = 'root',
    int initialLimit = 100,
  }) async {
    if (data == null) {
      return JsonNode(
        key: key,
        value: 'null',
        type: JsonNodeType.null_,
      );
    }

    // For small data structures, parse synchronously
    if (_isSmallData(data)) {
      return parseLazily(data, key: key, initialLimit: initialLimit);
    }

    // Use isolates on supported platforms
    if (_shouldUseIsolates) {
      return compute(
        _parseLazilyInIsolate,
        _LazyParseParams(data, key, initialLimit),
      );
    }

    // For web, use a custom async approach that doesn't require isolates
    return _parseLazilyAsyncWeb(data, key: key, initialLimit: initialLimit);
  }

  /// Web-friendly version of parseLazilyAsync that uses microtasks
  static Future<JsonNode> _parseLazilyAsyncWeb(
    Object? data, {
    required String key,
    required int initialLimit,
  }) async {
    // Give the UI thread a chance to update
    await Future.microtask(() {});

    // Create a completer to return the result
    final completer = Completer<JsonNode>();

    // Use a scheduled microtask to perform lazy parsing without blocking UI
    scheduleMicrotask(() async {
      JsonNode result;

      if (data is Map) {
        final children = <JsonNode>[];
        final entries = data.entries.toList();
        final totalChildCount = entries.length;

        // Only process up to initialLimit items
        final processCount =
            entries.length > initialLimit ? initialLimit : entries.length;

        // Process a few items at a time
        for (var i = 0; i < processCount;) {
          // Process a small batch
          final endIdx = (i + 10) < processCount ? (i + 10) : processCount;

          for (; i < endIdx; i++) {
            final entry = entries[i];
            children.add(
              await _parseLazilyAsyncWeb(
                entry.value,
                key: entry.key.toString(),
                initialLimit: initialLimit,
              ),
            );
          }

          // Yield to UI thread after each batch
          if (i < processCount) {
            await Future.microtask(() {});
          }
        }

        result = JsonNode(
          key: key,
          value: data,
          children: children,
          type: JsonNodeType.object,
          hasMoreChildren: totalChildCount > processCount,
          totalChildrenCount: totalChildCount,
        );
      } else if (data is List) {
        final children = <JsonNode>[];
        final totalChildCount = data.length;

        // Only process up to initialLimit items
        final processCount =
            data.length > initialLimit ? initialLimit : data.length;

        // Process a few items at a time
        for (var i = 0; i < processCount;) {
          // Process a small batch
          final endIdx = (i + 10) < processCount ? (i + 10) : processCount;

          for (; i < endIdx; i++) {
            children.add(
              await _parseLazilyAsyncWeb(
                data[i],
                key: '[$i]',
                initialLimit: initialLimit,
              ),
            );
          }

          // Yield to UI thread after each batch
          if (i < processCount) {
            await Future.microtask(() {});
          }
        }

        result = JsonNode(
          key: key,
          value: data,
          children: children,
          type: JsonNodeType.array,
          hasMoreChildren: totalChildCount > processCount,
          totalChildrenCount: totalChildCount,
        );
      } else {
        // For primitive values, use regular parse
        result = parse(data, key);
      }

      completer.complete(result);
    });

    return completer.future;
  }

  /// Worker function for parseLazilyAsync
  static JsonNode _parseLazilyInIsolate(_LazyParseParams params) => parseLazily(
        params.data,
        key: params.key,
        initialLimit: params.initialLimit,
      );

  /// Loads more children for a node that was partially loaded.
  ///
  /// This method adds more children to a [JsonNode] that was initially created
  /// with [parseLazily]. It will parse the next [countToLoad] children starting
  /// from [startIndex].
  ///
  /// ### Parameters:
  /// - [node]: The parent node to add more children to.
  /// - [startIndex]: The index to start loading from.
  /// - [countToLoad]: How many additional children to load.
  ///
  /// ### Returns:
  /// `true` if more children were loaded, `false` if there were no more to load.
  static bool loadMoreChildren(JsonNode node, int startIndex, int countToLoad) {
    if (!node.hasMoreChildren) return false;

    if (node.type == JsonNodeType.object) {
      final map = node.value as Map;
      final entries = map.entries.toList();
      final totalCount = entries.length;

      // Don't try to load beyond what's available
      if (startIndex >= totalCount) return false;

      // Calculate how many we can actually load
      final endIndex = (startIndex + countToLoad) > totalCount
          ? totalCount
          : (startIndex + countToLoad);

      // Parse and add new children
      for (var i = startIndex; i < endIndex; i++) {
        final entry = entries[i];
        node.children.add(parse(entry.value, entry.key.toString()));
      }

      // Update the hasMoreChildren flag
      node.hasMoreChildren = endIndex < totalCount;

      return true;
    } else if (node.type == JsonNodeType.array) {
      final list = node.value as List;
      final totalCount = list.length;

      // Don't try to load beyond what's available
      if (startIndex >= totalCount) return false;

      // Calculate how many we can actually load
      final endIndex = (startIndex + countToLoad) > totalCount
          ? totalCount
          : (startIndex + countToLoad);

      // Parse and add new children
      for (var i = startIndex; i < endIndex; i++) {
        node.children.add(parse(list[i], '[$i]'));
      }

      // Update the hasMoreChildren flag
      node.hasMoreChildren = endIndex < totalCount;

      return true;
    }

    return false;
  }

  /// Asynchronously loads more children with batching to prevent UI freezes
  ///
  /// Unlike [loadMoreChildren], this method processes children in smaller batches
  /// with short delays between batches to keep the UI responsive.
  ///
  /// ### Parameters:
  /// - [node]: The parent node to add more children to.
  /// - [startIndex]: The index to start loading from.
  /// - [countToLoad]: How many additional children to load.
  /// - [batchSize]: How many items to process in each batch (default: the minimum of 20 or countToLoad).
  ///
  /// ### Returns:
  /// A [Future] that completes with `true` if more children were loaded, `false` otherwise.
  static Future<bool> loadMoreChildrenAsync(
    JsonNode node,
    int startIndex,
    int countToLoad, {
    int? batchSize,
  }) async {
    if (!node.hasMoreChildren) return false;

    // For small loads, just use the synchronous version
    if (countToLoad <= 20) {
      return loadMoreChildren(node, startIndex, countToLoad);
    }

    // For supported platforms, use compute for the initial batch
    final actualBatchSize = batchSize ?? 20;

    if (_shouldUseIsolates) {
      final firstBatchSize =
          countToLoad < actualBatchSize ? countToLoad : actualBatchSize;

      final params = _LoadMoreParams(node, startIndex, firstBatchSize);
      final result = await compute(_loadMoreChildrenInIsolate, params);

      if (!result) return false;

      // If there are more batches to load, continue loading them in the main isolate
      // but with small delays to prevent UI freezes
      var processed = firstBatchSize;
      while (processed < countToLoad && node.hasMoreChildren) {
        // Give the UI thread a chance to breathe
        await Future<void>.delayed(const Duration(milliseconds: 5));

        final nextBatchSize = (countToLoad - processed) < actualBatchSize
            ? (countToLoad - processed)
            : actualBatchSize;

        loadMoreChildren(node, startIndex + processed, nextBatchSize);
        processed += nextBatchSize;
      }
    } else {
      // For web, use a batched approach without isolates
      var processed = 0;
      while (processed < countToLoad && node.hasMoreChildren) {
        // Process a batch
        final batchSize = ((countToLoad - processed) < actualBatchSize)
            ? (countToLoad - processed)
            : actualBatchSize;

        final result =
            loadMoreChildren(node, startIndex + processed, batchSize);
        if (!result) return false;

        processed += batchSize;

        // Give the UI thread a chance to breathe between batches
        await Future.microtask(() {});
      }
    }

    return true;
  }

  /// Worker function for loadMoreChildrenAsync
  static bool _loadMoreChildrenInIsolate(_LoadMoreParams params) =>
      loadMoreChildren(params.node, params.startIndex, params.countToLoad);
}

/// Helper class for passing parameters to the isolate for parseAsync
class _ParseParams {
  _ParseParams(this.data, this.key);
  final Object? data;
  final String key;
}

/// Helper class for passing parameters to the isolate for parseLazilyAsync
class _LazyParseParams {
  _LazyParseParams(this.data, this.key, this.initialLimit);
  final Object? data;
  final String key;
  final int initialLimit;
}

/// Helper class for passing parameters to the isolate for loadMoreChildrenAsync
class _LoadMoreParams {
  _LoadMoreParams(this.node, this.startIndex, this.countToLoad);
  final JsonNode node;
  final int startIndex;
  final int countToLoad;
}
