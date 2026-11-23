import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/log_page_controller.dart';

void main() {
  late ISpectLogPageController controller;
  late int notifications;

  setUp(() {
    controller = ISpectLogPageController();
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('initial state is false', () {
    expect(controller.inLoggerPage, isFalse);
  });

  test('setInLoggerPage flips value and notifies', () {
    controller.setInLoggerPage(isLoggerPage: true);
    expect(controller.inLoggerPage, isTrue);
    expect(notifications, 1);
  });

  test('setInLoggerPage to same value does not notify', () {
    controller
      ..setInLoggerPage(isLoggerPage: true)
      ..setInLoggerPage(isLoggerPage: true);
    expect(notifications, 1);
  });

  group('unseen errors', () {
    final error = ISpectLogData('boom', logLevel: LogLevel.error);

    test('counts errors logged while the logger page is closed', () {
      controller
        ..recordLog(error)
        ..recordLog(ISpectLogData('fine', logLevel: LogLevel.info))
        ..recordLog(error);

      expect(controller.unseenErrorCount, 2);
      expect(notifications, 2);
    });

    test('treats errors logged inside the logger page as seen', () {
      controller
        ..setInLoggerPage(isLoggerPage: true)
        ..recordLog(error);

      expect(controller.unseenErrorCount, 0);
    });

    test('opening the logger page marks every error as seen', () {
      controller
        ..recordLog(error)
        ..setInLoggerPage(isLoggerPage: true);

      expect(controller.unseenErrorCount, 0);
    });

    test('leaving the logger page starts a fresh count', () {
      controller
        ..recordLog(error)
        ..setInLoggerPage(isLoggerPage: true)
        ..setInLoggerPage(isLoggerPage: false)
        ..recordLog(error);

      expect(controller.unseenErrorCount, 1);
    });
  });

  test('reset clears flag and notifies only when needed', () {
    controller.setInLoggerPage(isLoggerPage: true);
    notifications = 0;
    controller.reset();
    expect(controller.inLoggerPage, isFalse);
    expect(notifications, 1);
  });

  test('reset when already false is a no-op', () {
    controller.reset();
    expect(notifications, 0);
  });
}
