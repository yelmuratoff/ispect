import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/request.dart';
import 'package:ispectify_dio/src/data/response.dart';
import 'package:test/test.dart';

void main() {
  test('DioResponseData.toJson handles null response safely', () {
    final req = RequestOptions(path: '/null');
    final data = DioResponseData(
      response: null,
      requestData: DioRequestData(req),
    );

    var json = <String, dynamic>{};
    expect(
      () => json = data.toJson(redactor: RedactionService()),
      returnsNormally,
    );

    expect(json['status-code'], isNull);
    expect(json['headers'], isNull);
    expect(json['redirects'], isNull);
  });
}
