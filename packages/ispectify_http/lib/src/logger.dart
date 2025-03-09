import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/models/_models.dart';

class ISpectifyHttpLogger extends InterceptorContract {
  ISpectifyHttpLogger({ISpectify? iSpectify}) {
    _iSpectify = iSpectify ?? ISpectify();
  }

  late ISpectify _iSpectify;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final message = '${request.url}';
    _iSpectify.logCustom(
      HttpRequestLog(
        message,
        method: request.method,
        url: request.url.toString(),
        path: request.url.path,
        headers: request.headers,
        body: (request is Request) ? request.body : null,
      ),
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final message = '${response.request?.url}';
    Map<String, dynamic>? body;

    if (response is Response) {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.request is MultipartRequest) {
      final request = response.request! as MultipartRequest;
      body = {
        'fields': request.fields,
        'files': request.files
            .map(
              (file) => {
                'filename': file.filename,
                'length': file.length,
                'contentType': file.contentType,
                'field': file.field,
              },
            )
            .toList(),
      };
    }

    if (response.statusCode >= 400 && response.statusCode < 600) {
      _iSpectify.logCustom(
        HttpErrorLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          requestHeaders: response.request?.headers,
          headers: response.headers,
          body: body ?? {},
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
        ),
      );
    } else {
      _iSpectify.logCustom(
        HttpResponseLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          requestHeaders: response.request?.headers,
          headers: response.headers,
          requestBody: body ?? {},
          responseBody: response,
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
        ),
      );
    }

    return response;
  }
}
