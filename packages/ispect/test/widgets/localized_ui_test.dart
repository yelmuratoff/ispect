import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/widgets/error_boundary.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/app_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/desktop_status_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/desktop_log_table_header.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_context_menu.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/limit_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/settings_bottom_sheet.dart';

import '../helpers/pump_ispect.dart';

const _ru = Locale('ru');

void _useLargeSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1600, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final class _FakeSender implements NetworkRequestSender {
  const _FakeSender(this.id);

  @override
  final String id;

  @override
  String get label => id;

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

void main() {
  group('app bar log counter', () {
    late ISpectViewController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = ISpectViewController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildAppBar({
      required int total,
      required int warnings,
      required int errors,
      Locale? locale,
    }) => appShell(
      CustomScrollView(
        slivers: [
          ISpectAppBar(
            title: 'ISpect',
            controller: controller,
            counts: const {},
            uniqTitles: const [],
            onToggleTitle: (_, _) {},
            focusNode: focusNode,
            totalCount: total,
            warningCount: warnings,
            errorCount: errors,
          ),
          const SliverFillRemaining(),
        ],
      ),
      locale: locale,
    );

    testWidgets('uses singular and plural English forms', (tester) async {
      await tester.pumpWidget(buildAppBar(total: 1, warnings: 2, errors: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('1 log · 2 warnings · 1 error', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('uses Russian one, few and many plural forms', (tester) async {
      await tester.pumpWidget(
        buildAppBar(total: 21, warnings: 3, errors: 5, locale: _ru),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('21 лог · 3 предупреждения · 5 ошибок', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('settings sheet', () {
    testWidgets('renders section labels and profiles in Russian', (
      tester,
    ) async {
      _useLargeSurface(tester);
      final loggerValue = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final logger = ISpectLoggerNotifier(loggerValue);
      final controller = ISpectViewController();
      addTearDown(() {
        controller.dispose();
        logger.dispose();
        loggerValue.dispose();
      });
      final sheet = ISpectSettingsBottomSheet(
        logger: logger,
        actions: const [],
        controller: controller,
      );

      await tester.pumpWidget(
        appShell(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(sheet.show(context)),
              child: const Text('open'),
            ),
          ),
          locale: _ru,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ОТОБРАЖЕНИЕ'), findsOneWidget);
      expect(find.text('Развернуть логи'), findsOneWidget);
      expect(find.text('Относительное время'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Профиль ресурсов'),
        250,
        scrollable: find.byType(Scrollable, skipOffstage: false).last,
      );

      expect(find.text('ДОПОЛНИТЕЛЬНО'), findsOneWidget);
      expect(find.text('Профиль ресурсов'), findsOneWidget);
      expect(find.text('Сбалансированный'), findsWidgets);
    });
  });

  group('limit editor', () {
    testWidgets('validates input with localized copy', (tester) async {
      await tester.pumpWidget(
        appShell(
          LimitTile(
            label: 'limit',
            description: 'description',
            icon: Icons.memory_rounded,
            value: 10,
            options: const [10, 20],
            formatter: formatCount,
            onChanged: (_) {},
          ),
          locale: _ru,
        ),
      );
      await tester.tap(find.text('limit'));
      await tester.pumpAndSettle();

      expect(find.text('Применить'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '-1');
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();

      expect(find.text('Введите неотрицательное целое число'), findsOneWidget);
    });
  });

  group('log type titles', () {
    const customType = ISpectLogType('firebase-read', title: 'Firebase Read');
    const theme = ISpectTheme(
      customLogTypes: [customType],
      logColors: {'firebase-read': Colors.amber},
      logIcons: {'firebase-read': Icons.cloud_rounded},
    );

    testWidgets('a custom type shows its configured title on the card and '
        'in the context menu', (tester) async {
      await tester.pumpWidget(
        appShell(
          SingleChildScrollView(
            child: LogCard(
              icon: Icons.cloud_rounded,
              color: Colors.amber,
              data: ISpectLogData('read users', key: customType.key),
              index: 0,
              isExpanded: false,
              onTap: () {},
            ),
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase Read'), findsOneWidget);
      expect(find.text('firebase-read'), findsNothing);

      await tester.longPress(find.text('read users'));
      await tester.pumpAndSettle();

      expect(find.text('Firebase Read'), findsNWidgets(2));
    });

    testWidgets('the context menu labels its filter section in Russian', (
      tester,
    ) async {
      _useLargeSurface(tester);
      await tester.pumpWidget(
        appShell(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                showLogContextMenu(
                  context: context,
                  position: Offset.zero,
                  data: ISpectLogData('message', key: 'info'),
                  onTypeFilterTap: (_, _) {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
          locale: _ru,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ФИЛЬТРЫ'), findsOneWidget);
      expect(find.text('Показать только этот тип'), findsOneWidget);
    });
  });

  group('desktop log table', () {
    testWidgets('localizes column headers and their sort labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(
          DesktopLogTableHeader(
            sortColumn: 0,
            sortDirection: 0,
            onSortTap: (_) {},
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ТИП'), findsOneWidget);
      expect(find.text('СООБЩЕНИЕ'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('^Сортировать по столбцу «Тип», по возрастанию'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('localizes the status bar counters and live tail state', (
      tester,
    ) async {
      _useLargeSurface(tester);
      await tester.pumpWidget(
        appShell(
          DesktopStatusBar(
            filteredCount: 2,
            totalCount: 21,
            isFiltered: true,
            useRelativeTime: false,
            onToggleTimestamp: () {},
            isLiveTailActive: true,
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 21 лог'), findsOneWidget);
      expect(find.text('ОНЛАЙН'), findsOneWidget);
    });

    testWidgets('fits the localized status bar into the narrowest desktop', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(768, 400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        appShell(
          DesktopStatusBar(
            filteredCount: 12345,
            totalCount: 67890,
            isFiltered: true,
            useRelativeTime: false,
            onToggleTimestamp: () {},
            isLiveTailActive: true,
            selectedLog: ISpectLogData('m', key: 'http-request'),
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'shows every keyboard hint in full at a regular desktop width',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1200, 400)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          appShell(
            DesktopStatusBar(
              filteredCount: 2,
              totalCount: 21,
              isFiltered: true,
              useRelativeTime: false,
              onToggleTimestamp: () {},
              selectedLog: ISpectLogData('m', key: 'http-request'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bar = tester.getRect(find.byType(DesktopStatusBar));
        expect(tester.getRect(find.text('close')).right, lessThan(bar.right));
      },
    );

    testWidgets('announces the HTTP status badge in the active locale', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(const DesktopStatusBadge(statusCode: 404), locale: _ru),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('HTTP-статус 404'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('log detail view', () {
    testWidgets('labels trace identifiers in the active locale', (
      tester,
    ) async {
      final log = ISpectLogData(
        'trace identifiers',
        additionalData: const {
          TraceKeys.correlationId: 'corr-1',
          TraceKeys.transactionId: 'txn-1',
        },
      );

      await tester.pumpWidget(
        appShell(LogDetailView(activeData: log), locale: _ru),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Корр:'), findsOneWidget);
      expect(find.textContaining('Транз:'), findsOneWidget);
    });
  });

  group('http composer', () {
    testWidgets('names the method and client pickers for assistive tech', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(
          const HttpComposerScreen(
            senders: [_FakeSender('dio'), _FakeSender('http')],
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('^Метод')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Клиент')), findsOneWidget);
      semantics.dispose();
    });
  });

  group('json viewer', () {
    testWidgets('falls back to localized title and correlation labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          JsonScreen(
            data: const {'message': 'payload'},
            correlatedLogData: const {'key': 'http-response', 'message': 'ok'},
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Просмотр JSON'), findsOneWidget);
      expect(find.text('Подробности'), findsOneWidget);
    });
  });

  group('logs screen', () {
    testWidgets('reports a failed external log load in the active locale', (
      tester,
    ) async {
      _useLargeSurface(tester);
      await tester.pumpWidget(
        appShell(
          const SessionLogsScreen(logs: []),
          locale: _ru,
          options: ISpectOptions(
            onLoadLogContent: (_) async => throw StateError('loader failed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      final logViewerAction = find.text('Просмотр логов').last;
      await tester.scrollUntilVisible(
        logViewerAction,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(logViewerAction);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Загрузить содержимое файла').last);
      await tester.pumpAndSettle();

      expect(find.text('Ошибка обработки содержимого'), findsOneWidget);
      expect(
        find.text('Не удалось загрузить содержимое логов'),
        findsOneWidget,
      );
    });
  });

  group('plugin error boundary', () {
    testWidgets('renders its fallback in the active locale', (tester) async {
      await tester.pumpWidget(
        appShell(
          SafePluginScreen(
            pluginBuilder: (_) => throw StateError('broken'),
            pluginId: 'broken-plugin',
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ошибка плагина: broken-plugin'), findsOneWidget);
      expect(find.text('Не удалось отобразить экран плагина'), findsOneWidget);
      expect(find.text('Назад'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });
  });

  group('resizable split view', () {
    testWidgets('announces the divider in the active locale', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(
          const ResizableSplitView(
            left: SizedBox.shrink(),
            right: SizedBox.shrink(),
          ),
          locale: _ru,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Изменить размер разделителя'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
