// ignore_for_file: avoid_print

import 'dart:io';

import 'package:atlassian_apis/jira_platform.dart';
import 'package:atlassian_apis/jira_software.dart' as jira_software;
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/jira/models/board.dart';
import 'package:ispect/src/features/jira/models/sprint.dart';

final class JiraClient {
  factory JiraClient() => _instance;

  JiraClient._();

  static final JiraClient _instance = JiraClient._();

  // <-- Fields -->

  bool _isInitialized = false;
  bool _isClientInitialized = false;

  late final ApiClient _client;
  late final String _projectDomain;
  late final String _userEmail;
  late final String _apiToken;
  late final String _projectId;
  late final String _projectKey;

  // <-- Getters -->

  static JiraClient get instance => _instance;

  static ApiClient get client => _instance._client;

  static bool get isInitialized => _instance._isInitialized;

  static bool get isClientInitialized => _instance._isClientInitialized;

  static String get projectDomain => _instance._projectDomain;

  static String get userEmail => _instance._userEmail;

  static String get apiToken => _instance._apiToken;

  static String get projectId => _instance._projectId;

  static String get projectKey => _instance._projectKey;

  // <-- Setters -->

  static set isInitialized(bool value) => _instance._isInitialized = value;

  static set projectDomain(String value) => _instance._projectDomain = value;

  static set userEmail(String value) => _instance._userEmail = value;

  static set apiToken(String value) => _instance._apiToken = value;

  static set projectKey(String value) => _instance._projectKey = value;

  static set projectId(String value) {
    if (value.isNotEmpty) {
      _instance._projectId = value;
      isInitialized = true;
    }
  }

  static void initClient({
    required String projectDomain,
    required String userEmail,
    required String apiToken,
  }) {
    try {
      _instance._client = ApiClient.basicAuthentication(
        Uri.https('$projectDomain.atlassian.net'),
        user: userEmail,
        apiToken: apiToken,
      );

      _instance._projectDomain = projectDomain;
      _instance._userEmail = userEmail;
      _instance._apiToken = apiToken;

      // final authToken = base64Encode(ascii.encode('$userEmail:$apiToken'));

      // _instance._dioClient = Dio(
      //   BaseOptions(
      //     baseUrl: 'https://$projectDomain.atlassian.net',
      //     headers: {
      //       'Authorization': 'Basic $authToken',
      //     },
      //   ),
      // )..interceptors.add(
      //     TalkerDioLogger(
      //       talker: ISpectTalker.talker,
      //     ),
      //   );

      _instance._isClientInitialized = true;
    } catch (e, st) {
      ISpectTalker.handle(
        exception: e,
        stackTrace: st,
      );
    }
  }

  static Future<List<Project>> getProjects() async {
    final jira = JiraPlatformApi(client);

    final projects = await jira.projects.searchProjects(
      maxResults: 100,
    );

    return projects.values;
  }

  // static Future<dynamic> getTransitions() async {
  //   final authToken = base64Encode(ascii.encode('$userEmail:$apiToken'));

  //   final dio = Dio(
  //     BaseOptions(
  //       baseUrl: 'https://$projectDomain.atlassian.net',
  //       headers: {
  //         'Authorization': 'Basic $authToken',
  //       },
  //     ),
  //   )..interceptors.add(
  //       TalkerDioLogger(
  //         talker: ISpectTalker.talker,
  //       ),
  //     );

  //   final response = await dio.post<dynamic>(
  //     '/gateway/api/jira/project-configuration/query/999a5f5c-de8f-4c23-ad2c-fcc63811ff46/2/transition/initial',
  //     data: {
  //       'projectId': '10005',
  //       'issueTypeId': '10014',
  //     },
  //   );

  //   print(response.data);
  // }

  static Future<void> createIssue({
    required String assigneeId,
    required String description,
    required String issueTypeId,
    required String statusId,
    required String label,
    required String reporterId,
    required String summary,
    required List<File> attachments,
  }) async {
    final jira = JiraPlatformApi(client);

    final response = await jira.issues.createIssue(
      body: IssueUpdateDetails(
        fields: {
          'project': {
            'id': projectId,
          },
          'assignee': {
            'id': assigneeId,
          },
          'summary': summary,
          'description': {
            'content': [
              {
                'content': [
                  {'text': description, 'type': 'text'},
                ],
                'type': 'paragraph',
              }
            ],
            'type': 'doc',
            'version': 1,
          },
          'issuetype': {
            'id': issueTypeId,
          },
          'labels': [
            label,
          ],
          'reporter': {
            'id': reporterId,
          },
        },
      ),
    );

    if (response.id != null) {
      print('Issue created: need to add transition');

      final transitions = await jira.issues.getTransitions(
        issueIdOrKey: response.id!,
      );

      final transition = transitions.transitions.firstWhere(
        (element) => element.to?.id == statusId,
        orElse: () => transitions.transitions.first,
      );

      await jira.issues.doTransition(
        issueIdOrKey: response.id!,
        body: IssueUpdateDetails(
          transition: IssueTransition(
            id: transition.id,
          ),
        ),
      );

      print('Issue transitioned. Now need to add attachments');

      for (final attachment in attachments) {
        final multipartFile = await MultipartFile.fromPath(
          'file',
          attachment.path,
        );
        final attachmentResponse = await jira.issueAttachments.addAttachment(
          issueIdOrKey: response.id!,
          file: multipartFile,
        );

        print('Attachment added: ${attachmentResponse.first.filename}');
      }
    }

    // print(response.toJson());
    // final authToken = base64Encode(ascii.encode('$userEmail:$apiToken'));

    // final dio = Dio(
    //   BaseOptions(
    //     baseUrl: 'https://$projectDomain.atlassian.net',
    //     headers: {
    //       'Authorization': 'Basic $authToken',
    //     },
    //   ),
    // )..interceptors.add(
    //     TalkerDioLogger(
    //       talker: ISpectTalker.talker,
    //     ),
    //   );

    // final response = await dio.post<dynamic>(
    //   '/rest/api/3/issue',
    // );
  }

  static Future<List<IssueTypeWithStatus>> getStatuses() async {
    final jira = JiraPlatformApi(client);

    final statuses = await jira.projects.getAllStatuses(JiraClient.projectKey);

    return statuses;
  }

  // static Future<List<IssueTypeWithStatus>> getStatuses() async {
  //   final jira = JiraPlatformApi(client);

  //   final statuses = await jira.projects.

  //   return statuses;
  // }

  static Future<PageBeanString> getLabels() async {
    final jira = JiraPlatformApi(client);

    final labels = await jira.labels.getAllLabels(
      maxResults: 100,
    );

    return labels;
  }

  static Future<List<User>> getUsers() async {
    final jira = JiraPlatformApi(client);

    final users = await jira.users.getAllUsers(
      maxResults: 300,
    );

    return users;
  }

  static Future<List<JiraBoard>> getBoards() async {
    final jira = jira_software.JiraSoftwareApi(client);

    final response = await jira.board.getAllBoards(
      projectKeyOrId: JiraClient.projectKey,
    );

    final list = response['values'] as List<Object?>;

    final boards = list.map((e) => JiraBoard.fromJson(e! as Map<String, Object?>)).toList();

    return boards;
  }

  static Future<List<JiraSprint>> getSprints({
    required int boardId,
  }) async {
    final jira = jira_software.JiraSoftwareApi(client);

    final response = await jira.board.getAllSprints(
      boardId: boardId,
      maxResults: 100,
    );

    // ignore: avoid_dynamic_calls
    final list = response['values'] as List<Object?>;

    final sprints = list.map((e) => JiraSprint.fromJson(e! as Map<String, Object?>)).toList();

    return sprints.where((sprint) => sprint.state == 'active').toList();
  }
}
