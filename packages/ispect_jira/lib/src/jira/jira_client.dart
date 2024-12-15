// ignore_for_file: avoid_print

import 'dart:io';

import 'package:atlassian_apis/jira_platform.dart';
import 'package:atlassian_apis/jira_software.dart' as jira_software;
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/src/jira/models/board.dart';
import 'package:ispect_jira/src/jira/models/sprint.dart';

final class ISpectJiraClient {
  factory ISpectJiraClient() => _instance;

  ISpectJiraClient._();

  static final ISpectJiraClient _instance = ISpectJiraClient._();

  // <-- Fields -->

  bool _isInitialized = false;
  bool _isClientInitialized = false;

  late ApiClient? _client;
  late String _projectDomain;
  late String _userEmail;
  late String _apiToken;
  late String _projectId;
  late String _projectKey;

  // <-- Getters -->

  static ISpectJiraClient get instance => _instance;

  static ApiClient get client => _instance._client!;

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

  static void restart() {
    _instance._client = null;
    _instance._projectDomain = '';
    _instance._userEmail = '';
    _instance._apiToken = '';
    _instance._projectId = '';
    _instance._projectKey = '';
    _instance._isInitialized = false;
    _instance._isClientInitialized = false;
  }

  static void initialize({
    required String projectDomain,
    required String userEmail,
    required String apiToken,
    required String projectId,
    required String projectKey,
  }) {
    _instance._projectDomain = projectDomain;
    _instance._userEmail = userEmail;
    _instance._apiToken = apiToken;
    _instance._projectId = projectId;
    _instance._projectKey = projectKey;

    initClient(
      projectDomain: projectDomain,
      userEmail: userEmail,
      apiToken: apiToken,
    );

    _instance._isInitialized = true;
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

      _instance._isClientInitialized = true;
    } catch (e, st) {
      ISpect.handle(
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

  static Future<User> getCurrentUser() async {
    final jira = JiraPlatformApi(client);

    final user = await jira.myself.getCurrentUser();

    return user;
  }

  static Future<CreatedIssue> createIssue({
    required String assigneeId,
    required String description,
    required String issueTypeId,
    required String label,
    required String summary,
    required String priorityId,
  }) async {
    try {
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
            'priority': {
              'id': priorityId,
            },
            'labels': [
              label,
            ],
            // 'reporter': {
            //   'id': reporterId,
            // },
          },
        ),
      );

      return response;
    } catch (e, st) {
      ISpect.handle(
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> addStatusToIssue({
    required CreatedIssue issue,
    required String statusId,
  }) async {
    try {
      final jira = JiraPlatformApi(client);
      if (issue.id != null) {
        final transitions = await jira.issues.getTransitions(
          issueIdOrKey: issue.id!,
        );

        final transition = transitions.transitions.firstWhere(
          (element) => element.to?.id == statusId,
          orElse: () => transitions.transitions.first,
        );

        return jira.issues.doTransition(
          issueIdOrKey: issue.id!,
          body: IssueUpdateDetails(
            transition: IssueTransition(
              id: transition.id,
            ),
          ),
        );
      }
    } catch (e, st) {
      ISpect.handle(
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<dynamic> addAttachmentsToIssue({
    required CreatedIssue issue,
    required List<File> attachments,
  }) async {
    try {
      final jira = JiraPlatformApi(client);

      for (final attachment in attachments) {
        final multipartFile = await MultipartFile.fromPath(
          'file',
          attachment.path,
        );
        await jira.issueAttachments.addAttachment(
          issueIdOrKey: issue.id!,
          file: multipartFile,
        );
      }
    } catch (e, st) {
      ISpect.handle(
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<List<IssueTypeWithStatus>> getStatuses() async {
    final jira = JiraPlatformApi(client);

    final statuses =
        await jira.projects.getAllStatuses(ISpectJiraClient.projectKey);

    return statuses;
  }

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

  static Future<List<Priority>> getPriorities() async {
    final jira = JiraPlatformApi(client);

    final priorities = await jira.issuePriorities.searchPriorities(
      projectId: [
        ISpectJiraClient.projectId,
      ],
    );

    return priorities.values;
  }

  static Future<List<JiraBoard>> getBoards() async {
    final jira = jira_software.JiraSoftwareApi(client);

    final response = await jira.board.getAllBoards(
      projectKeyOrId: ISpectJiraClient.projectKey,
    );

    final list = response['values'] as List<Object?>;

    final boards = list
        .map((e) => JiraBoard.fromJson(e! as Map<String, Object?>))
        .toList();

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

    final sprints = list
        .map((e) => JiraSprint.fromJson(e! as Map<String, Object?>))
        .toList();

    return sprints.where((sprint) => sprint.state == 'active').toList();
  }
}
