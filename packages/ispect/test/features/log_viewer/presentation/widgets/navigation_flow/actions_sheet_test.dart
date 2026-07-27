import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/navigation_flow/actions_sheet.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  group('ISpectNavigationFlowActionsSheet.buildContent redaction (H5)', () {
    late bool originalRedactionEnabled;

    setUp(() {
      originalRedactionEnabled = ISpectRedaction.enabled;
      ISpectRedaction.enabled = true;
    });

    tearDown(() {
      ISpectRedaction.enabled = originalRedactionEnabled;
    });

    RouteTransition transitionWithArgs(Object? arguments) => RouteTransition(
          id: 'corr-1',
          from: const RouteMetadata(name: '/home', routeType: 'Page'),
          to: const RouteMetadata(name: '/profile', routeType: 'Page'),
          type: TransitionType.push,
          timestamp: DateTime(2025, 1, 1, 12),
          arguments: arguments,
        );

    test('masks sensitive route-argument values on export when redactKeys set',
        () {
      final items = [
        transitionWithArgs(const {
          'token': 'super-secret-abc123',
          'screen': 'ARGUMENT_PROFILE_SECRET',
        }),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
        redactKeys: const {'token'},
      );

      expect(content, isNot(contains('super-secret-abc123')));
      expect(content, contains('Map'));
      expect(content, isNot(contains('ARGUMENT_PROFILE_SECRET')));
    });

    test('redacts route arguments by default when keys are omitted', () {
      final items = [
        transitionWithArgs(const {'token': 'super-secret-abc123'}),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
      );

      expect(content, isNot(contains('super-secret-abc123')));
      expect(content, contains('Map'));
    });

    test('fails closed when route arguments reject length inspection', () {
      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: [transitionWithArgs(_ThrowingLengthMap())],
        format: ExportFormat.text,
        action: ExportAction.share,
      );

      expect(content, contains('Map'));
      expect(content, isNot(contains('MAP_LENGTH_SECRET')));
    });

    test('leaves route arguments raw after explicit export opt-out', () {
      final items = [
        transitionWithArgs(const {'token': 'super-secret-abc123'}),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
        enableRedaction: false,
      );

      expect(content, contains('super-secret-abc123'));
    });

    test('masks credentials in the markdown-wrapped export', () {
      final items = [
        transitionWithArgs('Authorization: Bearer super-secret-abc123'),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.markdown,
        action: ExportAction.share,
        redactKeys: const {'token'},
      );

      expect(content, startsWith('# Navigation Flow'));
      expect(content, isNot(contains('Bearer super-secret-abc123')));
      expect(content, contains('Arguments: (String)'));
    });

    test('masks arguments on the single-transition share path', () {
      final items = [
        transitionWithArgs(const {'token': 'super-secret-abc123'}),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: items.first,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
        redactKeys: const {'token'},
      );

      expect(content, isNot(contains('super-secret-abc123')));
    });

    test('removes sensitive identifiers from route names', () {
      final items = [
        RouteTransition(
          id: 'corr-route',
          from: const RouteMetadata(name: '/home', routeType: 'Page'),
          to: const RouteMetadata(
            name: '/users/alice@example.com?account=123456',
            routeType: 'Page',
          ),
          type: TransitionType.push,
          timestamp: DateTime(2025, 1, 1, 12),
          arguments: null,
        ),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
      );

      expect(content, isNot(contains('alice@example.com')));
      expect(content, isNot(contains('123456')));
      expect(content, contains('[REDACTED]'));
    });

    test('bounds a lazy history before materializing all transitions', () {
      final item = transitionWithArgs(null);
      final items = _LazyTransitionList(
        item,
        virtualLength: 1000000,
      );

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
      );

      expect(items.reads, lessThanOrEqualTo(1000));
      expect(content, contains(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(content),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('bounds reverse traversal for a copied navigation path', () {
      final item = transitionWithArgs(null);
      final items = _LazyTransitionList(
        item,
        virtualLength: 1000000,
      );
      final target = RouteTransition(
        id: 'not-in-window',
        from: item.from,
        to: item.to,
        type: item.type,
        timestamp: item.timestamp,
        arguments: null,
      );

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: target,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.copy,
      );

      expect(items.reads, lessThanOrEqualTo(1000));
      expect(content, contains(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(content),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('fails closed on oversized route text before redaction', () {
      const leadingSecret = 'OVERSIZED_ROUTE_SECRET';
      const trailingSecret = 'OVERSIZED_ROUTE_TAIL_SECRET';
      final hugeRoute = '$leadingSecret${''.padRight(
        LogExportOutput.maxRecordBytes * 2,
        'x',
      )}$trailingSecret';
      final item = RouteTransition(
        id: 'oversized',
        from: const RouteMetadata(name: '/home', routeType: 'Page'),
        to: RouteMetadata(name: hugeRoute, routeType: 'Page'),
        type: TransitionType.push,
        timestamp: DateTime(2025),
        arguments: null,
      );

      for (final format in ExportFormat.values) {
        final content = ISpectNavigationFlowActionsSheet.buildContent(
          transition: null,
          items: [item],
          format: format,
          action: ExportAction.share,
        );

        expect(content, isNot(contains(leadingSecret)));
        expect(content, isNot(contains(trailingSecret)));
        expect(content, contains(LogExportOutput.truncatedMarker));
        expect(
          LogExportOutput.utf8Length(content),
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      }
    });

    test('keeps only a bounded prefix after explicit redaction opt-out', () {
      const visiblePrefix = 'CONTROLLED_DEBUG_PREFIX';
      const omittedTail = 'CONTROLLED_DEBUG_OMITTED_TAIL';
      final hugeRoute = '$visiblePrefix${''.padRight(
        LogExportOutput.maxRecordBytes * 2,
        'x',
      )}$omittedTail';
      final item = RouteTransition(
        id: 'oversized-opt-out',
        from: const RouteMetadata(name: '/home', routeType: 'Page'),
        to: RouteMetadata(name: hugeRoute, routeType: 'Page'),
        type: TransitionType.push,
        timestamp: DateTime(2025),
        arguments: null,
      );

      for (final format in ExportFormat.values) {
        final content = ISpectNavigationFlowActionsSheet.buildContent(
          transition: null,
          items: [item],
          format: format,
          action: ExportAction.share,
          enableRedaction: false,
        );

        expect(content, contains(visiblePrefix));
        expect(content, isNot(contains(omittedTail)));
        expect(content, contains(LogExportOutput.truncatedMarker));
        expect(
          LogExportOutput.utf8Length(content),
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      }
    });

    test('uses a content-safe closed Markdown fence', () {
      final item = RouteTransition(
        id: 'markdown-fence',
        from: const RouteMetadata(name: '/home', routeType: 'Page'),
        to: const RouteMetadata(
          name: '/route\n```\nBACKTICK_INJECTION\n```\n'
              '~~~\nTILDE_INJECTION\n~~~',
          routeType: 'Page',
        ),
        type: TransitionType.push,
        timestamp: DateTime(2025),
        arguments: null,
      );

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: [item],
        format: ExportFormat.markdown,
        action: ExportAction.share,
        enableRedaction: false,
      );
      final lines = content.trimRight().split('\n');
      final fence = lines[2];
      final bodyLines = lines.sublist(3, lines.length - 1);

      expect(fence, matches(RegExp(r'^(`{3,}|~{3,})$')));
      expect(lines.last, fence);
      expect(bodyLines, isNot(contains(fence)));
      expect(content, contains('BACKTICK_INJECTION'));
      expect(content, contains('TILDE_INJECTION'));
      expect(
        LogExportOutput.utf8Length(content),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('does not execute hostile diagnostic formatters', () {
      final hostile = _HostileDiagnostic();
      final calls = _FormatterCallTracker();
      final item = _HostileFormatterTransition(
        arguments: hostile,
        calls: calls,
      );

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: [item],
        format: ExportFormat.text,
        action: ExportAction.share,
        enableRedaction: false,
      );

      expect(hostile.toJsonCalls, 0);
      expect(hostile.toStringCalls, 0);
      expect(calls.prettyArguments, 0);
      expect(calls.transitionText, 0);
      expect(calls.toStringCalls, 0);
      expect(content, isNot(contains('HOSTILE_FORMATTER_SECRET')));
      expect(
        LogExportOutput.utf8Length(content),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('does not call a hostile timestamp formatter', () {
      final hostileTimestamp = _HostileDateTime();
      final item = RouteTransition(
        id: 'hostile-time',
        from: const RouteMetadata(name: '/home', routeType: 'Page'),
        to: const RouteMetadata(name: '/profile', routeType: 'Page'),
        type: TransitionType.push,
        timestamp: hostileTimestamp,
        arguments: null,
      );

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: [item],
        format: ExportFormat.text,
        action: ExportAction.share,
      );

      expect(hostileTimestamp.toStringCalls, 0);
      expect(content, contains(JsonValueNormalizer.unprintableValue));
      expect(content, isNot(contains('HOSTILE_TIME_SECRET')));
    });
  });
}

final class _ThrowingLengthMap extends MapBase<Object?, Object?> {
  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(Object? key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<Object?> get keys => const <Object?>[];

  @override
  int get length => throw StateError('MAP_LENGTH_SECRET');

  @override
  Object? remove(Object? key) => null;
}

final class _LazyTransitionList extends ListBase<RouteTransition> {
  _LazyTransitionList(
    this.item, {
    required this.virtualLength,
  });

  final RouteTransition item;
  final int virtualLength;
  int reads = 0;

  @override
  int get length => virtualLength;

  @override
  set length(int value) => throw UnsupportedError('read-only');

  @override
  RouteTransition operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', virtualLength);
    reads++;
    return item;
  }

  @override
  void operator []=(int index, RouteTransition value) =>
      throw UnsupportedError('read-only');
}

final class _HostileDiagnostic {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object toJson() {
    toJsonCalls++;
    throw StateError('HOSTILE_FORMATTER_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_FORMATTER_SECRET');
  }
}

final class _HostileFormatterTransition extends RouteTransition {
  _HostileFormatterTransition({
    required Object arguments,
    required this.calls,
  }) : super(
          id: 'hostile-formatter',
          from: const RouteMetadata(name: '/home', routeType: 'Page'),
          to: const RouteMetadata(name: '/profile', routeType: 'Page'),
          type: TransitionType.push,
          timestamp: DateTime(2025),
          arguments: arguments,
        );

  final _FormatterCallTracker calls;

  @override
  String? get prettyArguments {
    calls.prettyArguments++;
    throw StateError('HOSTILE_FORMATTER_SECRET');
  }

  @override
  String get transitionText {
    calls.transitionText++;
    throw StateError('HOSTILE_FORMATTER_SECRET');
  }

  @override
  String toString() {
    calls.toStringCalls++;
    throw StateError('HOSTILE_FORMATTER_SECRET');
  }
}

final class _FormatterCallTracker {
  int prettyArguments = 0;
  int transitionText = 0;
  int toStringCalls = 0;
}

final class _HostileDateTime implements DateTime {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_TIME_SECRET');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('HOSTILE_TIME_SECRET');
}
