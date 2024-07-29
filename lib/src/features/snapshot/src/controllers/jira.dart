// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:ispect/src/features/snapshot/feedback_plus.dart';

// /// This is an extension to make it easier to call
// /// [showAndUploadToJira].
// extension BetterFeedbackX on FeedbackController {
//   /// Example usage:
//   /// ```dart
//   /// import 'package:feedback_jira/feedback_jira.dart';
//   ///
//   /// RaisedButton(
//   ///   child: Text('Click me'),
//   ///   onPressed: (){
//   ///     BetterFeedback.of(context).showAndUploadToJira
//   ///       domainName: 'jira-project',
//   ///       apiToken: 'jira-api-token',
//   ///     );
//   ///   }
//   /// )
//   /// ```
//   /// The API token needs access to:
//   ///   - read_api
//   ///   - write_repository
//   /// See https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html#limiting-scopes-of-a-project-access-token
//   void showAndUploadToJira({
//     required String domainName,
//     required String apiToken,
//     Dio? client,
//   }) {
//     show(
//       uploadToJira(
//         domainName: domainName,
//         apiToken: apiToken,
//         client: client,
//       ),
//     );
//   }
// }

// /// See [BetterFeedbackX.showAndUploadToJira].
// /// This is just [visibleForTesting].
// @visibleForTesting
// OnFeedbackCallback uploadToJira({
//   required String domainName,
//   required String apiToken,
//   Map<String, dynamic>? customBody,
//   Dio? client,
// }) {
//   final httpClient = client ?? Dio();
//   httpClient.interceptors.add(LogInterceptor(responseBody: true));
//   final baseUrl = 'https://$domainName.atlassian.net';

//   return (feedback) async {
//     final body = customBody ??
//         {
//           'fields': {
//             'description': feedback.text,
//             'issuetype': {
//               'id': '10001',
//             },
//             // ignore: inference_failure_on_collection_literal
//             'parent': {},
//             'project': {
//               'id': '10000',
//             },
//             'summary': feedback.text,
//           },
//           // ignore: inference_failure_on_collection_literal
//           'update': {},
//         };

//     try {
//       final response = await httpClient.fetch<Object?>(
//         RequestOptions(
//           baseUrl: baseUrl,
//           path: '/rest/api/2/issue',
//           method: 'POST',
//           data: body,
//           headers: {
//             HttpHeaders.contentTypeHeader: 'application/json',
//             HttpHeaders.authorizationHeader: 'Basic $apiToken',
//           },
//         ),
//       );
//       final statusCode = response.statusCode ?? 0;
//       if (statusCode >= 200 && statusCode < 400) {
//         final resp = response.data! as Map<String, dynamic>;
//         final ticketId = resp['key'] as String;

//         try {
//           // Загрузка вложений
//           final attachmentsUrl = '$baseUrl/rest/api/2/issue/$ticketId/attachments';

//           final formData = FormData.fromMap({
//             'file': MultipartFile.fromBytes(
//               feedback.screenshot,
//               filename: 'screenshot.png',
//               contentType: MediaType('image', 'png'),
//             ),
//           });

//           await httpClient.post<Object?>(
//             attachmentsUrl,
//             data: formData,
//             options: Options(
//               headers: {
//                 'X-Atlassian-Token': 'no-check',
//                 'Accept': 'application/json',
//                 HttpHeaders.authorizationHeader: 'Basic $apiToken',
//               },
//             ),
//           );
//         } catch (e) {
//           rethrow;
//         }
//       } else {
//         throw HttpException('Error $statusCode');
//       }
//     } catch (e) {
//       rethrow;
//     }
//   };
// }
