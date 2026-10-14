import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/log_tallies.dart';

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
    List<String> chipKeys(
      LogTypeKeyTally tally,
      ISpectViewController controller,
    ) => tally
        .update(logs, excludedKeys: controller.settings.disabledLogTypes)
        .unique;

    test('drops a disabled type from the filter chip list', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);
      final tally = LogTypeKeyTally();

      expect(chipKeys(tally, controller), hasLength(3));

      controller.updateSettings(settingsWith({'riverpod-add'}));

      expect(
        chipKeys(tally, controller),
        unorderedEquals(<String>['riverpod-update', 'http-request']),
      );
    });

    test('restores a chip once its type is re-enabled', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);
      final tally = LogTypeKeyTally();

      controller.updateSettings(settingsWith({'riverpod-add'}));
      chipKeys(tally, controller);
      controller.updateSettings(settingsWith(const {}));

      expect(chipKeys(tally, controller), hasLength(3));
    });

    test('stops counting errors and warnings of a disabled type', () {
      final noisy = [
        ISpectLogData('boom', key: 'riverpod-update', logLevel: LogLevel.error),
        ISpectLogData('slow', key: 'http-error', logLevel: LogLevel.error),
        ISpectLogData(
          'hmm',
          key: 'riverpod-update',
          logLevel: LogLevel.warning,
        ),
      ];
      final controller = ISpectViewController();
      addTearDown(controller.dispose);
      final tally = LogHeaderTally();

      expect(tally.update(noisy, filter: controller.filter), (
        total: 3,
        errors: 2,
        warnings: 1,
      ));

      controller.updateSettings(settingsWith({'riverpod-update'}));

      expect(tally.update(noisy, filter: controller.filter), (
        total: 1,
        errors: 1,
        warnings: 0,
      ));
    });

    test('drops only the newly disabled type from the chip selection', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..addLogTypeKeyFilter('riverpod-add')
        ..addLogTypeKeyFilter('http-request')
        ..updateSettings(settingsWith({'riverpod-add'}));

      expect(controller.filter.logTypeKeys, {'http-request'});
      expect(keysOf(controller.applyCurrentFilters(logs)), {'http-request'});
    });

    test('disabling an unrelated type keeps the selected chip', () {
      final controller = ISpectViewController();
      addTearDown(controller.dispose);

      controller
        ..addLogTypeKeyFilter('http-error')
        ..updateSettings(settingsWith({'riverpod-add'}));

      expect(controller.filter.logTypeKeys, {'http-error'});
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
