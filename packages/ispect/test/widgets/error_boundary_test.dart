import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/widgets/error_boundary.dart';

final class _HostilePluginException implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'token=HOSTILE-PLUGIN-SECRET${'x' * (4 * 1024 * 1024)}';
  }
}

void main() {
  group('SafePluginScreen', () {
    testWidgets('renders child when pluginBuilder succeeds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafePluginScreen(
            pluginBuilder: (_) => const Text('Plugin OK'),
            pluginId: 'test-plugin',
          ),
        ),
      );

      expect(find.text('Plugin OK'), findsOneWidget);
      expect(find.text('Failed to render plugin screen'), findsNothing);
    });

    testWidgets('shows fallback when pluginBuilder throws', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafePluginScreen(
            pluginBuilder: (_) => throw Exception('boom'),
            pluginId: 'broken-plugin',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to render plugin screen'), findsOneWidget);
      expect(find.textContaining('Exception'), findsOneWidget);
      expect(find.text('Plugin Error: broken-plugin'), findsOneWidget);
    });

    testWidgets(
      'fallback masks strings and never executes hostile formatters',
      (tester) async {
        final hostile = _HostilePluginException();

        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [
                Expanded(
                  child: SafePluginScreen(
                    pluginBuilder: (_) => throw hostile,
                    pluginId: 'hostile-plugin',
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(hostile.calls, 0);
        expect(find.textContaining('HOSTILE-PLUGIN-SECRET'), findsNothing);

        await tester.pumpWidget(
          MaterialApp(
            home: SafePluginScreen(
              // Exercises defensive handling of non-Error Dart throws.
              // ignore: only_throw_errors
              pluginBuilder: (_) => throw 'token=STRING-PLUGIN-SECRET',
              pluginId: 'string-plugin',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('STRING-PLUGIN-SECRET'), findsNothing);
        expect(find.textContaining('[REDACTED]'), findsOneWidget);
      },
    );

    testWidgets('retry recreates child with new key', (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SafePluginScreen(
            pluginBuilder: (_) {
              callCount++;
              if (callCount == 1) {
                throw Exception('first call fails');
              }
              return const Text('Recovered');
            },
            pluginId: 'retry-plugin',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show fallback after first failure
      expect(find.text('Failed to render plugin screen'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should show recovered content
      expect(find.text('Recovered'), findsOneWidget);
      expect(find.text('Failed to render plugin screen'), findsNothing);
    });

    testWidgets('back button pops navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SafePluginScreen(
                      pluginBuilder: (_) => throw Exception('fail'),
                      pluginId: 'nav-plugin',
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // Navigate to error screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Failed to render plugin screen'), findsOneWidget);

      // Tap Back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be back to original screen
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Failed to render plugin screen'), findsNothing);
    });

    testWidgets('shows stack trace in debug mode', (tester) async {
      // kDebugMode is true in test environment
      assert(kDebugMode, 'This test requires debug mode');

      await tester.pumpWidget(
        MaterialApp(
          home: SafePluginScreen(
            pluginBuilder: (_) => throw Exception('debug-error'),
            pluginId: 'debug-plugin',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stack trace section should be present in debug mode
      expect(find.text('Stack Trace'), findsOneWidget);
    });
  });
}
