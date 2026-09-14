import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_details.dart';
import 'package:ispectify/ispectify.dart';

import '../../../../../helpers/pump_ispect.dart';

ISpectLogData _request({
  String? contentType,
  Object? body,
  Map<String, Object?> headers = const {},
}) => ISpectLogData(
  'request',
  additionalData: {
    TraceKeys.meta: {
      NetworkJsonKeys.requestData: {
        if (contentType != null) NetworkJsonKeys.contentType: contentType,
        if (body != null) NetworkJsonKeys.data: body,
        if (headers.isNotEmpty) NetworkJsonKeys.headers: headers,
      },
    },
  },
);

ISpectLogData _response({
  int? contentLength,
  Object? body,
  Map<String, Object?> headers = const {},
}) => ISpectLogData(
  'response',
  additionalData: {
    TraceKeys.meta: {
      NetworkJsonKeys.statusCode: 200,
      NetworkJsonKeys.responseData: {
        NetworkJsonKeys.statusCode: 200,
        NetworkJsonKeys.statusMessage: 'OK',
        if (contentLength != null) NetworkJsonKeys.contentLength: contentLength,
        if (body != null) NetworkJsonKeys.data: body,
        if (headers.isNotEmpty) NetworkJsonKeys.headers: headers,
      },
    },
  },
);

ISpectLogData _error({Object? body, Map<String, Object?> headers = const {}}) =>
    ISpectLogData(
      'FAILED\n→ POST /users',
      key: ISpectLogType.httpError.key,
      additionalData: {
        TraceKeys.meta: {
          NetworkJsonKeys.errorData: {
            NetworkJsonKeys.response: {
              NetworkJsonKeys.statusCode: 422,
              if (body != null) NetworkJsonKeys.data: body,
              if (headers.isNotEmpty) NetworkJsonKeys.headers: headers,
            },
          },
        },
      },
    );

void main() {
  group('TransactionDetails', () {
    testWidgets('Given a successful response with no summary, '
        'When rendered, '
        'Then neither the request nor the response row is shown', (
      tester,
    ) async {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(contentType: 'application/json'),
        response: _response(),
      );

      await tester.pumpWidget(
        appShell(TransactionDetails(tx: tx, color: Colors.blue)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    });

    testWidgets('Given a response that reports a size, '
        'When rendered, '
        'Then the request row joins the response row', (tester) async {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(contentType: 'application/json'),
        response: _response(contentLength: 1024),
      );

      await tester.pumpWidget(
        appShell(TransactionDetails(tx: tx, color: Colors.blue)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets(
      'shows body previews and keeps headers collapsed until requested',
      (tester) async {
        final tx = NetworkTransaction(
          requestId: 'r',
          request: _request(
            contentType: 'application/json',
            body: const {'name': 'Ada'},
            headers: const {
              'Authorization': '[REDACTED]',
              'Set-Cookie': 'session=[REDACTED]',
              'X-XSS-Protection': '1; mode=block',
            },
          ),
          response: _response(
            body: const {'created': true},
            headers: const {'content-type': 'application/json'},
          ),
        );

        await tester.pumpWidget(
          appShell(
            SingleChildScrollView(
              child: TransactionDetails(tx: tx, color: Colors.blue),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('"name": "Ada"'), findsOneWidget);
        expect(find.textContaining('"created": true'), findsOneWidget);
        expect(find.text('Preview truncated'), findsNothing);
        expect(find.byType(ShaderMask), findsNothing);
        expect(find.textContaining('[REDACTED]'), findsNothing);
        expect(find.textContaining('Headers (1)'), findsOneWidget);
        expect(find.textContaining('Headers (3)'), findsOneWidget);

        await tester.tap(find.textContaining('Headers (3)'));
        await tester.pumpAndSettle();

        expect(find.textContaining('[REDACTED]'), findsOneWidget);
        expect(find.textContaining('"Authorization"'), findsOneWidget);
        expect(find.textContaining('"Set-Cookie"'), findsOneWidget);
        expect(find.textContaining('"X-XSS-Protection"'), findsOneWidget);
        expect(find.textContaining('"[REDACTED]":'), findsNothing);
      },
    );

    testWidgets('marks a response body preview only when it overflows', (
      tester,
    ) async {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(),
        response: _response(
          body: {
            'products': [
              for (var index = 0; index < 12; index++)
                {
                  'id': index,
                  'description':
                      'A deliberately long product description for item $index',
                },
            ],
          },
        ),
      );

      await tester.pumpWidget(
        appShell(
          SingleChildScrollView(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: TransactionDetails(tx: tx, color: Colors.green),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preview truncated'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets(
      'keeps an eighteen-line response body visible without truncation',
      (tester) async {
        final tx = NetworkTransaction(
          requestId: 'r',
          request: _request(),
          response: _response(
            body: {
              for (var index = 0; index < 16; index++) 'item$index': index,
            },
          ),
        );

        await tester.pumpWidget(
          appShell(TransactionDetails(tx: tx, color: Colors.green)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Preview truncated'), findsNothing);
        expect(find.byType(ShaderMask), findsNothing);
      },
    );

    testWidgets('shows an error response body preview', (tester) async {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(body: const {'name': 'Ada'}),
        error: _error(body: const {'message': 'Name already exists'}),
      );

      await tester.pumpWidget(
        appShell(TransactionDetails(tx: tx, color: Colors.red)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('"message": "Name already exists"'),
        findsOneWidget,
      );
    });
  });
}
