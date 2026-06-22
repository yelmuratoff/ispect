import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_details.dart';
import 'package:ispectify/ispectify.dart';

import '../../../../../helpers/pump_ispect.dart';

ISpectLogData _request({String? contentType}) => ISpectLogData(
      'request',
      additionalData: {
        TraceKeys.meta: {
          NetworkJsonKeys.requestData: {
            if (contentType != null) NetworkJsonKeys.contentType: contentType,
          },
        },
      },
    );

ISpectLogData _response({int? contentLength}) => ISpectLogData(
      'response',
      additionalData: {
        TraceKeys.meta: {
          NetworkJsonKeys.statusCode: 200,
          NetworkJsonKeys.responseData: {
            NetworkJsonKeys.statusCode: 200,
            NetworkJsonKeys.statusMessage: 'OK',
            if (contentLength != null)
              NetworkJsonKeys.contentLength: contentLength,
          },
        },
      },
    );

void main() {
  group('TransactionDetails', () {
    testWidgets(
      'Given a successful response with no summary, '
      'When rendered, '
      'Then neither the request nor the response row is shown',
      (tester) async {
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
      },
    );

    testWidgets(
      'Given a response that reports a size, '
      'When rendered, '
      'Then the request row joins the response row',
      (tester) async {
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
      },
    );
  });
}
