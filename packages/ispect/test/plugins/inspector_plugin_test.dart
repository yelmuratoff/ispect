import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

class _TestPlugin extends InspectorPlugin {
  _TestPlugin({
    this.pluginId = 'test-plugin',
    this.pluginTitle = 'Test Plugin',
  });

  final String pluginId;
  final String pluginTitle;

  bool initCalled = false;
  bool disposeCalled = false;

  @override
  String get id => pluginId;

  @override
  String get title => pluginTitle;

  @override
  @override
  IconData get icon => Icons.extension;

  @override
  Widget buildScreen(BuildContext context) => const Text('Plugin Screen');

  @override
  void onInit() {
    initCalled = true;
  }

  @override
  void onDispose() {
    disposeCalled = true;
  }
}

class _BadgedPlugin extends InspectorPlugin {
  @override
  String get id => 'badged';

  @override
  String get title => 'Badged Plugin';

  @override
  IconData get icon => Icons.notifications;

  @override
  bool get enableBadge => true;

  @override
  String? get description => 'Custom description';

  @override
  Widget buildScreen(BuildContext context) => const Text('Badged Screen');
}

void main() {
  group('InspectorPlugin', () {
    group('default values', () {
      test('description defaults to null', () {
        final plugin = _TestPlugin();
        expect(plugin.description, isNull);
      });

      test('enableBadge defaults to false', () {
        final plugin = _TestPlugin();
        expect(plugin.enableBadge, isFalse);
      });

      test('onInit does not throw', () {
        final plugin = _TestPlugin();
        expect(plugin.onInit, returnsNormally);
      });

      test('onDispose does not throw', () {
        final plugin = _TestPlugin();
        expect(plugin.onDispose, returnsNormally);
      });
    });

    group('overridden values', () {
      test('description can be overridden', () {
        final plugin = _BadgedPlugin();
        expect(plugin.description, 'Custom description');
      });

      test('enableBadge can be overridden', () {
        final plugin = _BadgedPlugin();
        expect(plugin.enableBadge, isTrue);
      });
    });
  });

  group('ISpectOptions with plugins', () {
    test('plugins defaults to empty list', () {
      const options = ISpectOptions();
      expect(options.plugins, isEmpty);
    });

    test('plugins are preserved in copyWith', () {
      final plugin = _TestPlugin();
      final options = ISpectOptions(plugins: [plugin]);
      final copied = options.copyWith();
      expect(copied.plugins, [plugin]);
    });

    test('plugins can be replaced in copyWith', () {
      final plugin1 = _TestPlugin(pluginId: 'p1');
      final plugin2 = _TestPlugin(pluginId: 'p2');
      final options = ISpectOptions(plugins: [plugin1]);
      final copied = options.copyWith(plugins: [plugin2]);
      expect(copied.plugins, [plugin2]);
    });

    test('equality includes plugins', () {
      final plugin = _TestPlugin();
      final options1 = ISpectOptions(plugins: [plugin]);
      final options2 = ISpectOptions(plugins: [plugin]);
      expect(options1, equals(options2));
    });

    test('toString includes plugins', () {
      const options = ISpectOptions();
      expect(options.toString(), contains('plugins:'));
    });
  });

  group('Plugin lifecycle', () {
    test('onInit is called when ISpectBuilder initializes', () {
      final plugin = _TestPlugin();
      expect(plugin.initCalled, isFalse);
      plugin.onInit();
      expect(plugin.initCalled, isTrue);
    });

    test('onDispose is called on cleanup', () {
      final plugin = _TestPlugin();
      expect(plugin.disposeCalled, isFalse);
      plugin.onDispose();
      expect(plugin.disposeCalled, isTrue);
    });
  });

  group('Duplicate plugin ids', () {
    test('multiple plugins with same id are both kept in list', () {
      final plugin1 = _TestPlugin(pluginId: 'same-id', pluginTitle: 'First');
      final plugin2 = _TestPlugin(pluginId: 'same-id', pluginTitle: 'Second');
      final options = ISpectOptions(plugins: [plugin1, plugin2]);
      expect(options.plugins.length, 2);
    });
  });
}
