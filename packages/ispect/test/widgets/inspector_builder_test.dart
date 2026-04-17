import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

class _TestPlugin extends InspectorPlugin {
  _TestPlugin({this.pluginId = 'test-plugin'});

  final String pluginId;
  int initCalls = 0;
  int disposeCalls = 0;

  @override
  String get id => pluginId;

  @override
  String get title => 'Test Plugin';

  @override
  IconData get icon => Icons.extension;

  @override
  Widget buildScreen(BuildContext context) => const Text('Plugin Screen');

  @override
  void onInit() {
    initCalls++;
  }

  @override
  void onDispose() {
    disposeCalls++;
  }
}

const _emptyApp = MaterialApp(home: SizedBox.shrink());

void main() {
  group('ISpectBuilder', () {
    group('plugin lifecycle', () {
      testWidgets(
        'onInit is called when ISpectBuilder is inserted into the tree',
        (tester) async {
          final plugin = _TestPlugin();
          expect(plugin.initCalls, 0);

          await tester.pumpWidget(
            MaterialApp(
              home: ISpectBuilder(
                options: ISpectOptions(plugins: [plugin]),
                child: const SizedBox.shrink(),
              ),
            ),
          );

          expect(plugin.initCalls, 1);
          expect(plugin.disposeCalls, 0);
        },
      );

      testWidgets(
        'onDispose is called when ISpectBuilder is removed from the tree',
        (tester) async {
          final plugin = _TestPlugin();

          await tester.pumpWidget(
            MaterialApp(
              home: ISpectBuilder(
                options: ISpectOptions(plugins: [plugin]),
                child: const SizedBox.shrink(),
              ),
            ),
          );
          expect(plugin.disposeCalls, 0);

          await tester.pumpWidget(_emptyApp);

          expect(plugin.disposeCalls, 1);
        },
      );

      testWidgets(
        'onInit is called once per plugin in options',
        (tester) async {
          final p1 = _TestPlugin(pluginId: 'p1');
          final p2 = _TestPlugin(pluginId: 'p2');

          await tester.pumpWidget(
            MaterialApp(
              home: ISpectBuilder(
                options: ISpectOptions(plugins: [p1, p2]),
                child: const SizedBox.shrink(),
              ),
            ),
          );

          expect(p1.initCalls, 1);
          expect(p2.initCalls, 1);
        },
      );
    });

    group('ErrorWidget.builder ownership', () {
      testWidgets(
        'ErrorWidget.builder is overridden while mounted and restored '
        'after removal',
        (tester) async {
          final original = ErrorWidget.builder;

          await tester.pumpWidget(
            const MaterialApp(
              home: ISpectBuilder(
                options: ISpectOptions(),
                child: SizedBox.shrink(),
              ),
            ),
          );

          expect(ErrorWidget.builder, isNot(same(original)));

          await tester.pumpWidget(_emptyApp);

          expect(ErrorWidget.builder, same(original));
        },
      );
    });

    group('DraggablePanelController ownership', () {
      testWidgets(
        'external controller is NOT disposed when ISpectBuilder is disposed',
        (tester) async {
          final external = DraggablePanelController();

          await tester.pumpWidget(
            MaterialApp(
              home: ISpectBuilder(
                options: const ISpectOptions(),
                controller: external,
                child: const SizedBox.shrink(),
              ),
            ),
          );

          await tester.pumpWidget(_emptyApp);

          // If the widget had disposed the external controller, calling
          // dispose here would throw in debug mode (ChangeNotifier asserts
          // against double-dispose). returnsNormally proves ownership stayed
          // with the test, not the widget.
          expect(external.dispose, returnsNormally);
        },
      );

      testWidgets(
        'internal controller is created and disposed without errors',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ISpectBuilder(
                options: ISpectOptions(),
                child: SizedBox.shrink(),
              ),
            ),
          );

          await tester.pumpWidget(_emptyApp);

          expect(tester.takeException(), isNull);
        },
      );
    });

    group('ISpectBuilder.wrap', () {
      testWidgets(
        'returns child directly when kISpectEnabled is false',
        (tester) async {
          const child = SizedBox.shrink(key: Key('wrapped-child'));
          final wrapped = ISpectBuilder.wrap(child: child);

          // In the test environment `kISpectEnabled` is `false` by default
          // (no `--dart-define=ISPECT_ENABLED=true`), so wrap must bypass
          // ISpectBuilder entirely. When running tests WITH the flag, the
          // builder is created instead.
          if (!kISpectEnabled) {
            expect(identical(wrapped, child), isTrue);
          } else {
            expect(wrapped, isA<ISpectBuilder>());
          }
        },
      );

      testWidgets(
        'returns child directly when isISpectEnabled is false at runtime',
        (tester) async {
          const child = SizedBox.shrink(key: Key('disabled-child'));
          // Without `--dart-define=ISPECT_ENABLED=true` the `false` argument
          // matches the default, but we pin down the runtime-toggle contract
          // regardless of the compile-time flag.
          final wrapped = ISpectBuilder.wrap(
            child: child,
            // ignore: avoid_redundant_argument_values
            isISpectEnabled: false,
          );

          expect(identical(wrapped, child), isTrue);
        },
      );
    });

    group('scope access', () {
      testWidgets(
        'scope availability matches kISpectEnabled',
        (tester) async {
          ISpectScopeController? foundScope;

          await tester.pumpWidget(
            MaterialApp(
              home: ISpectBuilder(
                options: const ISpectOptions(),
                child: Builder(
                  builder: (context) {
                    foundScope = context.dependOnInheritedWidgetOfExactType<
                        ISpectScopeController>();
                    return const Text('child');
                  },
                ),
              ),
            ),
          );

          expect(find.text('child'), findsOneWidget);

          // build() short-circuits and skips injecting ISpectScopeController
          // when kISpectEnabled is false, so the scope is unreachable there.
          if (kISpectEnabled) {
            expect(foundScope, isNotNull);
          } else {
            expect(foundScope, isNull);
          }
        },
      );
    });
  });
}
