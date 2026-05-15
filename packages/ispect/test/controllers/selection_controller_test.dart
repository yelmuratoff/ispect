import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/selection_controller.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  late SelectionController controller;
  late ISpectLogData logA;
  late ISpectLogData logB;
  late int notifications;

  setUp(() {
    controller = SelectionController();
    logA = ISpectLogData('A', key: 'info');
    logB = ISpectLogData('B', key: 'error');
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  group('activeData', () {
    test('initial state is null', () {
      expect(controller.activeData, isNull);
      expect(controller.detailData, isNull);
    });

    test('setting same value does not notify', () {
      controller
        ..activeData = logA
        ..activeData = logA;
      expect(notifications, 1);
    });

    test('setting different value notifies', () {
      controller
        ..activeData = logA
        ..activeData = logB;
      expect(notifications, 2);
      expect(controller.activeData, logB);
    });

    test('clearing to null notifies', () {
      controller
        ..activeData = logA
        ..activeData = null;
      expect(notifications, 2);
      expect(controller.activeData, isNull);
    });
  });

  group('selectLog', () {
    test('sets activeData and notifies', () {
      controller.selectLog(logA);
      expect(controller.activeData, logA);
      expect(notifications, 1);
    });
  });

  group('openLogDetail', () {
    test('first call opens detail and sets active', () {
      controller.openLogDetail(logA);
      expect(controller.activeData, logA);
      expect(controller.detailData, logA);
      expect(notifications, 1);
    });

    test('second call on same entry closes detail but keeps active', () {
      controller
        ..openLogDetail(logA)
        ..openLogDetail(logA);
      expect(controller.activeData, logA);
      expect(controller.detailData, isNull);
      expect(notifications, 2);
    });

    test('opening different entry replaces detail', () {
      controller
        ..openLogDetail(logA)
        ..openLogDetail(logB);
      expect(controller.activeData, logB);
      expect(controller.detailData, logB);
    });
  });

  group('selectAndFollowDetail', () {
    test('sets both active and detail in one notification', () {
      controller.selectAndFollowDetail(logA);
      expect(controller.activeData, logA);
      expect(controller.detailData, logA);
      expect(notifications, 1);
    });
  });

  group('closeDetail', () {
    test('no-op when detail already null', () {
      controller.closeDetail();
      expect(notifications, 0);
    });

    test('clears detail without touching active', () {
      controller.openLogDetail(logA);
      notifications = 0;
      controller.closeDetail();
      expect(controller.activeData, logA);
      expect(controller.detailData, isNull);
      expect(notifications, 1);
    });
  });

  group('handleLogItemTap', () {
    test('first tap selects entry', () {
      controller.handleLogItemTap(logA);
      expect(controller.activeData, logA);
    });

    test('second tap on same entry deselects', () {
      controller
        ..handleLogItemTap(logA)
        ..handleLogItemTap(logA);
      expect(controller.activeData, isNull);
    });

    test('tap on different entry replaces selection', () {
      controller
        ..handleLogItemTap(logA)
        ..handleLogItemTap(logB);
      expect(controller.activeData, logB);
    });
  });
}
