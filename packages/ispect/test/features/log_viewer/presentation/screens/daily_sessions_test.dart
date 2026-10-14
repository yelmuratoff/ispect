import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/daily_sessions.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';

import '../../../../helpers/pump_ispect.dart';

final class _FakeFileLogHistory implements FileLogHistory {
  _FakeFileLogHistory({
    this.dates = const [],
    this.failDates = false,
    this.failClear = false,
    this.failSize = false,
    this.failLogs = false,
  });

  List<DateTime> dates;
  bool failDates;
  bool gateDates = false;
  final List<Completer<List<DateTime>>> pendingDates = [];
  final bool failClear;
  final bool failSize;
  final bool failLogs;
  final List<ISpectLogData> _entries = [];

  @override
  List<ISpectLogData> get history => List.unmodifiable(_entries);

  @override
  void add(ISpectLogData data) => _entries.add(data);

  @override
  void clear() => _entries.clear();

  @override
  void dispose() => _entries.clear();

  @override
  Future<void> saveToDailyFile() async {}

  @override
  String get sessionDirectory => 'sessions';

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    if (failDates) throw Exception('dates unavailable');
    if (gateDates) {
      final pending = Completer<List<DateTime>>();
      pendingDates.add(pending);
      return pending.future;
    }
    return dates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) async {
    if (failSize) throw Exception('size unavailable');
    return 2048;
  }

  @override
  Future<void> clearAllFileStorage() async {
    if (failClear) throw Exception('clear failed');
  }

  @override
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) async {
    if (failLogs) throw Exception('session unreadable');
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final session = DateTime(2024, 3, 2);

  group('DailySessionsScreen', () {
    testWidgets('shows an error with retry when listing sessions fails', (
      tester,
    ) async {
      final history = _FakeFileLogHistory(failDates: true);
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Error'), findsOneWidget);

      history
        ..failDates = false
        ..dates = [session];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsNothing);
      expect(find.textContaining('2.0 KB'), findsOneWidget);
    });

    testWidgets('retry shows loading and starts a single reload', (
      tester,
    ) async {
      final history = _FakeFileLogHistory(failDates: true);
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      history
        ..failDates = false
        ..gateDates = true;
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.text('Error'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(history.pendingDates, hasLength(1));

      history.pendingDates.single.complete([session]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('2.0 KB'), findsOneWidget);
    });

    testWidgets('drops a refresh result that a newer refresh superseded', (
      tester,
    ) async {
      final history = _FakeFileLogHistory();
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      history.gateDates = true;
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(history.pendingDates, hasLength(2));

      history.pendingDates[1].complete([session]);
      await tester.pump();
      history.pendingDates[0].complete([
        DateTime(2024, 3, 3),
        DateTime(2024, 2, 29),
      ]);
      await tester.pumpAndSettle();

      expect(find.textContaining('2.0 KB'), findsOneWidget);
    });

    testWidgets('keeps the sessions listed when clearing them fails', (
      tester,
    ) async {
      final history = _FakeFileLogHistory(dates: [session], failClear: true);
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear_all_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('2.0 KB'), findsOneWidget);
    });

    testWidgets('explains a listing failure in the active locale', (
      tester,
    ) async {
      final history = _FakeFileLogHistory(failDates: true);
      await tester.pumpWidget(
        appShell(
          DailySessionsScreen(history: history),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ошибка'), findsOneWidget);
      expect(find.text('Не удалось загрузить сессии'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('names the failed clear in the error toast', (tester) async {
      final history = _FakeFileLogHistory(dates: [session], failClear: true);
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear_all_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to clear sessions'), findsOneWidget);
    });

    testWidgets('stops showing loading when a file size cannot be read', (
      tester,
    ) async {
      final history = _FakeFileLogHistory(dates: [session], failSize: true);
      await tester.pumpWidget(appShell(DailySessionsScreen(history: history)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Loading'), findsNothing);
    });
  });

  group('SessionLogsScreen', () {
    tearDown(ISpect.dispose);

    testWidgets('reports a session that cannot be read', (tester) async {
      await ISpect.dispose();
      ISpect.initialize(
        ISpectLogger.testing(
          options: ISpectLoggerOptions(useConsoleLogs: false),
          history: _FakeFileLogHistory(failLogs: true),
        ),
      );

      await tester.pumpWidget(
        appShell(SessionLogsScreen(sessionDate: session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Failed to load session logs'), findsOneWidget);
    });

    testWidgets('reports an unreadable session in the active locale', (
      tester,
    ) async {
      await ISpect.dispose();
      ISpect.initialize(
        ISpectLogger.testing(
          options: ISpectLoggerOptions(useConsoleLogs: false),
          history: _FakeFileLogHistory(failLogs: true),
        ),
      );

      await tester.pumpWidget(
        appShell(
          SessionLogsScreen(sessionDate: session),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить логи сессии'), findsOneWidget);
    });
  });
}
