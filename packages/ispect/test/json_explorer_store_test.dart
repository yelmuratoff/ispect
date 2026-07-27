import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
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

  testWidgets(
    'clearing search invalidates results from an in-flight search',
    (tester) async {
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
    },
  );

  testWidgets(
    'rebuilding nodes invalidates a search over the previous tree',
    (tester) async {
      final store = JsonExplorerStore();
      addTearDown(store.dispose);
      final build = store.buildNodes(_largeSearchSnapshot());
      await tester.pump(const Duration(milliseconds: 5));
      await build;

      store.search('stale');
      expect(store.isSearching, isTrue);

      await store.buildNodes(
        JsonInputPreflight.snapshotForViewer(
          <String, Object?>{'current': true},
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      expect(store.displayNodes.map((node) => node.key), ['current']);
      expect(store.searchTerm, isEmpty);
      expect(store.searchResults, isEmpty);
      expect(store.isSearching, isFalse);
    },
  );
}

JsonInputSnapshot _largeSearchSnapshot() =>
    JsonInputPreflight.snapshotForViewer(
      <String, Object?>{
        for (var index = 0; index < 6000; index++) 'stale-$index': index,
      },
    );
