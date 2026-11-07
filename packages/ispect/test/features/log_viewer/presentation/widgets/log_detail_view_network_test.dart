import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';
import 'package:ispect/src/features/json_viewer/breadcrumb_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';

import '../../../../helpers/pump_ispect.dart';

const _url = 'https://api.test/todos/1';

ISpectLogData _httpResponse({
  Map<String, Object?> body = const {'id': 1, 'todo': 'Buy milk'},
}) => ISpectLogData(
  'GET $_url',
  key: ISpectLogType.httpResponse.key,
  additionalData: {
    TraceKeys.category: TraceCategoryIds.network,
    TraceKeys.source: 'dio',
    TraceKeys.meta: {
      NetworkJsonKeys.requestId: 'r1',
      NetworkJsonKeys.statusCode: 200,
      NetworkJsonKeys.responseData: {
        NetworkJsonKeys.statusCode: 200,
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: _url,
        NetworkJsonKeys.headers: {
          for (var index = 0; index < 23; index++)
            'x-header-$index': 'header-value-$index',
        },
        NetworkJsonKeys.data: body,
        NetworkJsonKeys.request: const {
          NetworkJsonKeys.method: 'GET',
          NetworkJsonKeys.url: _url,
          NetworkJsonKeys.headers: {'accept': 'request-accept-value'},
        },
      },
    },
  },
);

ISpectLogData _httpRequest() => ISpectLogData(
  'POST $_url',
  key: ISpectLogType.httpRequest.key,
  additionalData: const {
    TraceKeys.meta: {
      NetworkJsonKeys.requestData: {
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: _url,
        NetworkJsonKeys.queryParameters: {'page': '2'},
        NetworkJsonKeys.headers: {'accept': 'request-accept-value'},
        NetworkJsonKeys.data: {'title': 'Buy milk'},
      },
    },
  },
);

ISpectLogData _httpPackageError() => ISpectLogData(
  'GET $_url',
  key: ISpectLogType.httpError.key,
  additionalData: const {
    TraceKeys.meta: {
      NetworkJsonKeys.errorData: {
        NetworkJsonKeys.statusCode: 404,
        NetworkJsonKeys.headers: {'x-error': 'error-header-value'},
        NetworkJsonKeys.body: {'message': 'Todo not found'},
      },
    },
  },
);

Finder _landmark(String id) => find.byKey(ValueKey('json-landmark-$id'));

final class _Sender implements NetworkRequestSender {
  @override
  String get id => 'detail-test';

  @override
  String get label => 'Detail test';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

Finder _value(String text) => find.text(text, findRichText: true);

Future<void> _pumpDetail(
  WidgetTester tester,
  ISpectLogData log, {
  Size size = const Size(900, 2400),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
  await tester.pumpAndSettle();
}

void main() {
  group('LogDetailView for an HTTP log', () {
    testWidgets('opens with the body shown and the headers folded', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpResponse());

      expect(_value('Buy milk'), findsOneWidget);
      expect(_value('header-value-0'), findsNothing);
      expect(_value('request-accept-value'), findsNothing);
    });

    testWidgets('offers the sections the log carries', (tester) async {
      await _pumpDetail(tester, _httpResponse());

      expect(find.byKey(const ValueKey('json-landmark-body')), findsOneWidget);
      expect(find.text('Headers (23)'), findsOneWidget);
      expect(find.byKey(const ValueKey('json-landmark-query')), findsNothing);
      expect(find.byKey(const ValueKey('json-landmark-request')), findsNothing);
    });

    testWidgets('a section chip unfolds the section it names', (tester) async {
      await _pumpDetail(tester, _httpResponse());

      await tester.tap(find.byKey(const ValueKey('json-landmark-headers')));
      await tester.pumpAndSettle();

      expect(_value('header-value-0'), findsOneWidget);
      expect(_value('request-accept-value'), findsNothing);
    });

    testWidgets('a section chip scrolls its section to the top', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpResponse(), size: const Size(545, 790));
      final topRow = _value('time');
      expect(topRow, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('json-landmark-headers')));
      await tester.pumpAndSettle();

      expect(topRow, findsNothing);
      expect(_value('header-value-0'), findsOneWidget);
    });

    testWidgets('the chip of the section in view is the only colored one', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpResponse());
      Color chipColor(String id) =>
          tester.widget<DetailChip>(_landmark(id)).color;

      expect(chipColor('headers'), chipColor('body'));

      await tester.tap(_landmark('headers'));
      await tester.pumpAndSettle();

      expect(chipColor('headers'), isNot(chipColor('body')));
    });

    testWidgets('the chip of the section in view is announced as selected', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpResponse());
      bool? selected(String id) => tester
          .widget<Semantics>(
            find
                .descendant(of: _landmark(id), matching: find.byType(Semantics))
                .first,
          )
          .properties
          .selected;

      expect(selected('headers'), isFalse);

      await tester.tap(_landmark('headers'));
      await tester.pumpAndSettle();

      expect(selected('headers'), isTrue);
      expect(selected('body'), isFalse);
    });

    testWidgets('a request offers its body, headers and query', (tester) async {
      await _pumpDetail(tester, _httpRequest());

      expect(_landmark('body'), findsOneWidget);
      expect(find.text('Headers (1)'), findsOneWidget);
      expect(find.text('Query parameters (1)'), findsOneWidget);
      expect(_value('request-accept-value'), findsNothing);
    });

    testWidgets('an http package error offers its body and headers', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpPackageError());

      expect(_value('Todo not found'), findsOneWidget);
      expect(_value('error-header-value'), findsNothing);
      expect(find.text('Headers (1)'), findsOneWidget);
    });

    testWidgets('keys in the body that share a section name stay untouched', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        _httpResponse(
          body: const {
            NetworkJsonKeys.headers: {'own': 'body-header-value'},
            TraceKeys.meta: {
              NetworkJsonKeys.requestData: {
                NetworkJsonKeys.data: {'nested': 'body-nested-value'},
              },
            },
          },
        ),
      );

      expect(_value('body-header-value'), findsOneWidget);

      await tester.tap(_landmark('body'));
      await tester.pumpAndSettle();

      Finder crumb(String key) => find.descendant(
        of: find.byType(BreadcrumbBar),
        matching: find.text(key),
      );
      expect(crumb(NetworkJsonKeys.responseData), findsOneWidget);
      expect(crumb(NetworkJsonKeys.requestData), findsNothing);
    });

    testWidgets('offers edit and resend when a client is registered', (
      tester,
    ) async {
      final sender = _Sender();
      ISpect.registerSender(sender);
      addTearDown(() => ISpect.unregisterSender(sender.id));
      await _pumpDetail(tester, _httpResponse());

      await tester.tap(
        find.byKey(const ValueKey('log-detail-edit-and-resend')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HttpComposerScreen), findsOneWidget);
      expect(find.text(_url), findsWidgets);
    });

    testWidgets('hides edit and resend without a registered client', (
      tester,
    ) async {
      await _pumpDetail(tester, _httpResponse());

      expect(
        find.byKey(const ValueKey('log-detail-edit-and-resend')),
        findsNothing,
      );
    });
  });

  testWidgets('a non-network log keeps the plain, fully expanded tree', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      ISpectLogData(
        'create CounterBloc',
        key: 'bloc-create',
        additionalData: const {
          TraceKeys.meta: {
            NetworkJsonKeys.headers: {'bloc-type': 'CounterBloc'},
          },
        },
      ),
    );

    expect(_value('CounterBloc'), findsOneWidget);
    expect(find.byType(DetailChip), findsNothing);
  });
}
