import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/display_controller.dart';

void main() {
  group('DisplayController defaults', () {
    test('uses sensible defaults when no settings supplied', () {
      final c = DisplayController();
      expect(c.expandedLogs, isFalse);
      expect(c.isLogOrderReversed, isTrue);
      expect(c.groupHttpLogs, isTrue);
      expect(c.useRelativeTime, isFalse);
      expect(c.compactNetworkUrls, isTrue);
    });

    test('hydrates from initialSettings', () {
      final c = DisplayController(
        initialSettings: const ISpectSettingsState(
          enabled: true,
          useConsoleLogs: true,
          useHistory: true,
          expandedLogs: true,
          isLogOrderReversed: false,
          groupHttpLogs: false,
          useRelativeTime: true,
          compactNetworkUrls: false,
        ),
      );
      expect(c.expandedLogs, isTrue);
      expect(c.isLogOrderReversed, isFalse);
      expect(c.groupHttpLogs, isFalse);
      expect(c.useRelativeTime, isTrue);
      expect(c.compactNetworkUrls, isFalse);
    });
  });

  group('toggles', () {
    late DisplayController c;
    late int n;
    setUp(() {
      c = DisplayController();
      n = 0;
      c.addListener(() => n++);
    });
    tearDown(() => c.dispose());

    test('toggleExpandedLogs flips and notifies', () {
      c.toggleExpandedLogs();
      expect(c.expandedLogs, isTrue);
      expect(n, 1);
    });

    test('toggleLogOrder flips and notifies', () {
      final before = c.isLogOrderReversed;
      c.toggleLogOrder();
      expect(c.isLogOrderReversed, !before);
      expect(n, 1);
    });

    test('toggleGroupHttpLogs flips and notifies', () {
      final before = c.groupHttpLogs;
      c.toggleGroupHttpLogs();
      expect(c.groupHttpLogs, !before);
      expect(n, 1);
    });

    test('toggleTimestampFormat flips and notifies', () {
      c.toggleTimestampFormat();
      expect(c.useRelativeTime, isTrue);
      expect(n, 1);
    });

    test('toggleCompactNetworkUrls flips and notifies', () {
      final before = c.compactNetworkUrls;
      c.toggleCompactNetworkUrls();
      expect(c.compactNetworkUrls, !before);
      expect(n, 1);
    });

    test('setting same value does not notify', () {
      c.expandedLogs = c.expandedLogs;
      expect(n, 0);
    });
  });

  group('applyFromSettings', () {
    test('updates fields and emits one notification when changed', () {
      final c = DisplayController();
      var n = 0;
      c
        ..addListener(() => n++)
        ..applyFromSettings(
          const ISpectSettingsState(
            enabled: true,
            useConsoleLogs: true,
            useHistory: true,
            expandedLogs: true,
            isLogOrderReversed: false,
            groupHttpLogs: false,
            useRelativeTime: true,
            compactNetworkUrls: false,
          ),
        );

      expect(c.expandedLogs, isTrue);
      expect(c.isLogOrderReversed, isFalse);
      expect(c.groupHttpLogs, isFalse);
      expect(c.useRelativeTime, isTrue);
      expect(c.compactNetworkUrls, isFalse);
      expect(n, 1);
    });

    test('no-op when nothing changes', () {
      final c = DisplayController();
      var n = 0;
      c
        ..addListener(() => n++)
        ..applyFromSettings(
          const ISpectSettingsState(
            enabled: true,
            useConsoleLogs: true,
            useHistory: true,
          ),
        );

      expect(n, 0);
    });
  });
}
