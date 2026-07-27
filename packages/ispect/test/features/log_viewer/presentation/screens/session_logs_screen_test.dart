import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/session_logs_screen.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_list_item.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_all_logs_sheet.dart';

import '../../../../helpers/pump_ispect.dart';

final class _CheckStatusAuthEvent {
  const _CheckStatusAuthEvent();
}

final class _AuthenticateWithTokensAuthEvent {
  const _AuthenticateWithTokensAuthEvent();

  @override
  String toString() =>
      'AuthenticateWithTokensAuthEvent(Bearer embedded-secret-token)';
}

final class _ReadTrackingLogs extends ListBase<ISpectLogData> {
  _ReadTrackingLogs(this._logs);

  final List<ISpectLogData> _logs;
  int recordReads = 0;

  @override
  int get length => _logs.length;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  ISpectLogData operator [](int index) {
    recordReads++;
    return _logs[index];
  }

  @override
  void operator []=(int index, ISpectLogData value) =>
      throw UnsupportedError('immutable');
}

final class _UnsendableRedactionStrategy implements RedactionStrategy {
  const _UnsendableRedactionStrategy(this.port);

  final ReceivePort port;

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      keyName == 'project_private' ? '[CUSTOM MASK]' : null;
}

void main() {
  testWidgets(
    'independent logs use the same app bar and display defaults as live logs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        appShell(
          SessionLogsScreen(
            logs: [
              ISpectLogData(
                'persisted session entry',
                id: 'SESSION-LOG',
                key: ISpectLogType.info.key,
                logLevel: LogLevel.info,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ISpect'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(
        tester.widget<LogListItem>(find.byType(LogListItem)).isExpanded,
        isFalse,
      );
    },
  );

  testWidgets('clear history action clears the independent snapshot',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      appShell(
        SessionLogsScreen(
          logs: [
            ISpectLogData(
              'snapshot-only entry',
              id: 'SNAPSHOT-ONLY',
              key: ISpectLogType.info.key,
              logLevel: LogLevel.info,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('snapshot-only entry'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final clearHistory = find.text('Clear history');
    await tester.scrollUntilVisible(
      clearHistory,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(clearHistory);
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('snapshot-only entry'), findsNothing);
  });

  test('export content encodes the independent snapshot', () async {
    final content = await buildLogsExportContent(
      ExportFormat.text,
      logs: [
        ISpectLogData(
          'shared snapshot entry',
          id: 'SHARED-SNAPSHOT',
          key: ISpectLogType.info.key,
          logLevel: LogLevel.info,
        ),
      ],
    );

    expect(content, contains('shared snapshot entry'));
  });

  test('JSON export snapshots non-encodable values without formatters',
      () async {
    final content = await buildLogsExportContent(
      ExportFormat.json,
      logs: [
        ISpectLogData(
          'Dio-style diagnostic entry',
          id: 'NON-ENCODABLE-SNAPSHOT',
          additionalData: {
            'timeout': const Duration(seconds: 1),
            'endpoint': Uri.parse('https://example.com/logs'),
            TraceKeys.meta: const {
              'event': _CheckStatusAuthEvent(),
              'tokenEvent': _AuthenticateWithTokensAuthEvent(),
              'authorization': 'Bearer secret-token',
              'metrics': {1: double.nan},
            },
          },
        ),
      ],
      redactKeys: defaultSensitiveKeys,
    );

    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final logs = decoded['logs'] as List<dynamic>;
    final log = logs.single as Map<String, dynamic>;
    final additionalData = log['additional-data'] as Map<String, dynamic>;

    expect(additionalData['timeout'], JsonValueNormalizer.unprintableValue);
    expect(additionalData['endpoint'], JsonValueNormalizer.unprintableValue);
    final blocMetadata = additionalData[TraceKeys.meta] as Map<String, dynamic>;
    expect(
      blocMetadata['event'],
      JsonValueNormalizer.unprintableValue,
    );
    expect(
      blocMetadata['tokenEvent'],
      isNot(contains('embedded-secret-token')),
    );
    expect(blocMetadata['authorization'], isNot(contains('secret-token')));
    expect(
      blocMetadata['metrics'],
      {
        JsonValueNormalizer.traversalMarkerKey:
            JsonValueNormalizer.unprintableValue,
      },
    );
  });

  for (final format in const [
    ExportFormat.text,
    ExportFormat.markdown,
    ExportFormat.csv,
  ]) {
    test('large ${format.label} export defers record reads', () async {
      final logs = _ReadTrackingLogs(
        List<ISpectLogData>.generate(
          64,
          (index) => ISpectLogData(
            'background export $index',
            id: 'BACKGROUND-$index',
          ),
        ),
      );

      final operation = buildLogsExportContent(format, logs: logs);

      expect(logs.recordReads, 0);
      final content = await operation;
      expect(content, contains('background export 0'));
    });
  }

  test('large export preserves an isolate-incompatible custom redactor',
      () async {
    final port = ReceivePort();
    addTearDown(port.close);
    final logs = List<ISpectLogData>.generate(
      64,
      (index) => ISpectLogData(
        'custom policy $index',
        additionalData: {'project_private': 'visible raw value $index'},
      ),
    );

    final content = await buildLogsExportContent(
      ExportFormat.text,
      logs: logs,
      redactionService: RedactionService(
        strategy: _UnsendableRedactionStrategy(port),
      ),
    );

    expect(content, contains('[CUSTOM MASK]'));
    expect(content, isNot(contains('visible raw value')));
  });
}
