import 'package:flutter_test/flutter_test.dart';
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
