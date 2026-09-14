import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  ISpectSettingsState settingsWith(Set<String> disabled) => ISpectSettingsState(
    enabled: true,
    useConsoleLogs: false,
    useHistory: true,
    disabledLogTypes: disabled,
  );

  final logs = [
    ISpectLogData('added', key: 'riverpod-add'),
    ISpectLogData('changed', key: 'riverpod-update'),
    ISpectLogData('request', key: 'http-request'),
  ];

  Set<String?> keysOf(List<ISpectLogData> data) =>
      data.map((e) => e.key).toSet();

  group('disabled log types in the viewer', () {
    test('hides already-captured logs of a disabled type', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller.updateSettings(settingsWith({'riverpod-add'}));

      expect(keysOf(controller.applyCurrentFilters(logs)), {
        'riverpod-update',
        'http-request',
      });
    });

    test('hydrates the exclusion from initialSettings', () {
      final controller = ISpectViewController(
        initialSettings: settingsWith({'http-request'}),
      );
      addTearDown(controller.dispose);

      expect(keysOf(controller.applyCurrentFilters(logs)), {
        'riverpod-add',
        'riverpod-update',
      });
    });

    test('keeps hiding a disabled type while a chip filter is active', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..addLogTypeKeyFilter('riverpod-add')
        ..addLogTypeKeyFilter('riverpod-update');

      expect(keysOf(controller.applyCurrentFilters(logs)), {'riverpod-update'});
    });

    test('clearing the chip filters does not resurrect a disabled type', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..addLogTypeKeyFilter('http-request')
        ..clearAllFilters();

      expect(keysOf(controller.applyCurrentFilters(logs)), {
        'riverpod-update',
        'http-request',
      });
    });

    test('hides a disabled type on the default highlight-mode path', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      expect(controller.searchMode, SearchMode.highlight);
      controller.updateSettings(settingsWith({'riverpod-add'}));

      expect(keysOf(controller.applyFiltersWithoutSearch(logs)), {
        'riverpod-update',
        'http-request',
      });
    });

    test(
      'recomputes the highlight-mode result when the disabled set changes',
      () {
        final controller = ISpectViewController();
        addTearDown(controller.dispose);

        controller.updateSettings(settingsWith({'riverpod-add'}));
        expect(controller.applyFiltersWithoutSearch(logs), hasLength(2));

        controller.updateSettings(settingsWith({'http-request'}));

        expect(keysOf(controller.applyFiltersWithoutSearch(logs)), {
          'riverpod-add',
          'riverpod-update',
        });
      },
    );

    test('re-enabling a type shows its logs again', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..updateSettings(settingsWith(const {}));

      expect(keysOf(controller.applyCurrentFilters(logs)), keysOf(logs));
    });
  });

  group('derived viewer statistics', () {
    test('drops a disabled type from the filter chip list', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      expect(controller.getLogTypeKeys(logs).unique, hasLength(3));

      controller.updateSettings(settingsWith({'riverpod-add'}));

      expect(
        controller.getLogTypeKeys(logs).unique,
        unorderedEquals(<String>['riverpod-update', 'http-request']),
      );
    });

    test('restores a chip once its type is re-enabled', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..getLogTypeKeys(logs)
        ..updateSettings(settingsWith(const {}));

      expect(controller.getLogTypeKeys(logs).unique, hasLength(3));
    });

    test('stops counting errors and warnings of a disabled type', () {
      final noisy = [
        ISpectLogData('boom', key: 'riverpod-fail', logLevel: LogLevel.error),
        ISpectLogData('slow', key: 'http-error', logLevel: LogLevel.error),
        ISpectLogData('hmm', key: 'riverpod-fail', logLevel: LogLevel.warning),
      ];
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      expect(controller.getLevelStats(noisy), (errors: 2, warnings: 1));

      controller.updateSettings(settingsWith({'riverpod-fail'}));

      expect(controller.getLevelStats(noisy), (errors: 1, warnings: 0));
    });

    test('resets the chip filter so no selection outlives its chip list', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..addLogTypeKeyFilter('riverpod-add')
        ..addLogTypeKeyFilter('http-request')
        ..updateSettings(settingsWith({'riverpod-add'}));

      expect(controller.filter.logTypeKeys, isEmpty);
      expect(keysOf(controller.applyCurrentFilters(logs)), {
        'riverpod-update',
        'http-request',
      });
    });

    test('keeps the chip filter when the disabled set does not change', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..addLogTypeKeyFilter('http-request')
        ..updateSettings(settingsWith({'riverpod-add'}));

      expect(controller.filter.logTypeKeys, {'http-request'});
    });

    test('assigning a filter directly keeps the settings veto', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..updateSettings(settingsWith({'riverpod-add'}))
        ..filter = ISpectFilter(logTypeKeys: const ['riverpod-add', 'info']);

      expect(controller.filter.excludedLogTypeKeys, {'riverpod-add'});
      expect(keysOf(controller.applyCurrentFilters(logs)), isEmpty);
    });
  });
}
