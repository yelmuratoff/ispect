import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/navigation_flow/actions_sheet.dart';

void main() {
  group('ISpectNavigationFlowActionsSheet.buildContent redaction (H5)', () {
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
          'screen': 'profile',
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
      expect(content, contains('***'));
      expect(content, contains('profile'));
    });

    test('leaves route arguments raw when redactKeys is null (opt-out)', () {
      final items = [
        transitionWithArgs(const {'token': 'super-secret-abc123'}),
      ];

      final content = ISpectNavigationFlowActionsSheet.buildContent(
        transition: null,
        items: items,
        format: ExportFormat.text,
        action: ExportAction.share,
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
      expect(content, contains('Bearer ***'));
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
  });
}
