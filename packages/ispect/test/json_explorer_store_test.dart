import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';

void main() {
  testWidgets(
    'newer small input wins when an older large build resumes later',
    (tester) async {
      final store = JsonExplorerStore();
      addTearDown(store.dispose);
      var notifications = 0;
      store.addListener(() => notifications++);

      final delayedSnapshot = JsonInputPreflight.snapshotForViewer(
        <String, Object?>{
          for (var index = 0; index <= 1000; index++) 'stale-$index': index,
        },
      );
      final currentSnapshot = JsonInputPreflight.snapshotForViewer(
        <String, Object?>{'current': true},
      );

      final delayedBuild = store.buildNodes(delayedSnapshot);
      await store.buildNodes(currentSnapshot);

      expect(store.displayNodes.map((node) => node.key), ['current']);
      expect(notifications, 1);

      await tester.pump(const Duration(milliseconds: 5));
      await delayedBuild;

      expect(store.displayNodes.map((node) => node.key), ['current']);
      expect(notifications, 1);
    },
  );

  testWidgets('clearing search invalidates results from an in-flight search', (
    tester,
  ) async {
    final store = JsonExplorerStore();
    addTearDown(store.dispose);
    final build = store.buildNodes(_largeSearchSnapshot());
    await tester.pump(const Duration(milliseconds: 5));
    await build;

    store.search('stale');
    expect(store.isSearching, isTrue);

    store.search('');
    expect(store.searchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
    expect(store.isSearching, isFalse);

    await tester.pump(const Duration(milliseconds: 1));

    expect(store.searchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
    expect(store.isSearching, isFalse);
  });

  testWidgets('rebuilding nodes invalidates a search over the previous tree', (
    tester,
  ) async {
    final store = JsonExplorerStore();
    addTearDown(store.dispose);
    final build = store.buildNodes(_largeSearchSnapshot());
    await tester.pump(const Duration(milliseconds: 5));
    await build;

    store.search('stale');
    expect(store.isSearching, isTrue);

    await store.buildNodes(
      JsonInputPreflight.snapshotForViewer(<String, Object?>{'current': true}),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(store.displayNodes.map((node) => node.key), ['current']);
    expect(store.searchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
    expect(store.isSearching, isFalse);
  });

  group('JsonExplorerStore search matches', () {
    test('finds key and value matches in node order', () async {
      final store = await _storeFor({'name': 'alpha', 'alphabet': 'x'});

      await _search(store, 'alpha');

      expect(_describe(store.searchResults), [
        'name:value@0',
        'alphabet:key@0',
      ]);
    });

    test('reports every occurrence within one value', () async {
      final store = await _storeFor({'k': 'abab'});

      await _search(store, 'ab');

      expect(_describe(store.searchResults), ['k:value@0', 'k:value@2']);
    });

    test('matches keys but never the value of an object or array', () async {
      final store = await _storeFor({
        'obj': {'inner': 1},
        'list': ['inner'],
      });

      await _search(store, 'inner');

      expect(_describe(store.searchResults), ['inner:key@0', '0:value@0']);
    });

    test('matches case-insensitively', () async {
      final store = await _storeFor({'Key': 'VALUE'});

      await _search(store, 'value');

      expect(_describe(store.searchResults), ['Key:value@0']);
    });

    test('reports match indices in source text coordinates', () async {
      final store = await _storeFor({'k': 'İİabc'});

      await _search(store, 'abc');

      expect(_describe(store.searchResults), ['k:value@2']);
    });
  });

  group('JsonExplorerStore expansion', () {
    test(
      'collapsing a parent hides its nested collapsed children too',
      () async {
        final store = await _storeFor({
          'a': {
            'b': {'c': 1},
            'd': 2,
          },
          'e': 3,
        });
        NodeViewModelState node(String key) =>
            store.displayNodes.firstWhere((n) => n.key == key);

        store.collapseNode(node('b'));
        expect(_keys(store), ['a', 'b', 'd', 'e']);

        store.collapseNode(node('a'));
        expect(_keys(store), ['a', 'e']);

        store.expandNode(node('a'));
        expect(_keys(store), ['a', 'b', 'd', 'e']);
      },
    );

    test(
      'collapseAll keeps top-level nodes and expandAll restores all',
      () async {
        final store = await _storeFor({
          'a': {
            'b': {'c': 1},
          },
          'e': 3,
        });

        store.collapseAll();
        expect(_keys(store), ['a', 'e']);
        expect(store.displayNodes.first.isCollapsed, isTrue);

        store.expandAll();
        expect(_keys(store), ['a', 'b', 'c', 'e']);
        expect(store.displayNodes.where((n) => n.isCollapsed), isEmpty);
      },
    );

    test('reports expandable nodes from the built tree', () async {
      final flat = await _storeFor({'a': 1});
      final nested = await _storeFor({
        'a': {'b': 1},
      });

      expect(flat.hasExpandableNodes, isFalse);
      expect(nested.hasExpandableNodes, isTrue);
      nested.collapseAll();
      expect(nested.hasExpandableNodes, isTrue);
    });
  });

  group('JsonExplorerStore search focus', () {
    test('focusNextSearchResult stops at the end unless looping', () async {
      final store = await _storeFor({'x': 'aaa'});
      await _search(store, 'a');

      store
        ..focusNextSearchResult()
        ..focusNextSearchResult()
        ..focusNextSearchResult();
      expect(store.focusedSearchResultIndex, 2);

      store.focusNextSearchResult(loop: true);
      expect(store.focusedSearchResultIndex, 0);
      expect(store.focusedSearchResult?.matchIndex, 0);
    });

    test(
      'focusPreviousSearchResult stops at the start unless looping',
      () async {
        final store = await _storeFor({'x': 'aaa'});
        await _search(store, 'a');

        store.focusPreviousSearchResult();
        expect(store.focusedSearchResultIndex, 0);

        store.focusPreviousSearchResult(loop: true);
        expect(store.focusedSearchResultIndex, 2);
        expect(store.focusedSearchResult?.matchIndex, 2);
      },
    );

    test('has no focused result without search results', () async {
      final store = await _storeFor({'x': 'aaa'});
      await _search(store, 'zzz');

      expect(store.focusedSearchResult, isNull);
      expect(store.focusedSearchResultIndex, 0);
    });
  });
}

Future<JsonExplorerStore> _storeFor(Map<String, Object?> data) async {
  final store = JsonExplorerStore();
  addTearDown(store.dispose);
  await store.buildNodes(JsonInputPreflight.snapshotForViewer(data));
  return store;
}

Future<void> _search(JsonExplorerStore store, String term) async {
  store.search(term);
  while (store.isSearching) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _keys(JsonExplorerStore store) => [
  for (final node in store.displayNodes) node.key,
];

List<String> _describe(Iterable<SearchResult> results) => [
  for (final result in results)
    '${result.node.key}:${result.matchLocation.name}@${result.matchIndex}',
];

JsonInputSnapshot _largeSearchSnapshot() =>
    JsonInputPreflight.snapshotForViewer(<String, Object?>{
      for (var index = 0; index < 6000; index++) 'stale-$index': index,
    });
