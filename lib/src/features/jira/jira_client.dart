import 'package:atlassian_apis/jira_platform.dart';
import 'package:ispect/ispect.dart';

final class JiraClient {
  factory JiraClient() => _instance;
  // ignore: prefer_const_constructor_declarations
  JiraClient._();

  static final JiraClient _instance = JiraClient._();

  late final ApiClient _client;

  static JiraClient get instance => _instance;

  static ApiClient get client => _instance._client;

  bool _isInitialized = false;

  static bool get isInitialized => _instance._isInitialized;

  static set isInitialized(bool value) => _instance._isInitialized = value;

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
      isInitialized = true;
    } catch (e, st) {
      ISpectTalker.handle(
        exception: e,
        stackTrace: st,
      );
    }
  }

  // final client = ApiClient.basicAuthentication(
  //   Uri.https('anydevkz.atlassian.net'),
  //   user: 'y.yelmuratov@astanahub.com',
  //   apiToken:
  //       'ATATT3xFfGF0GhreJejfCCDui1NPa1wcS7Y2xdk_rj5VuuAGSIIc7RM-TDeMSFLPBfrcJEUHdtgXZVJ5zb6fSgwG19UtqyuT7eaxxTW30WW1rjRIPrNSu4gjm01rMPNZcX4FuWCwV4XJmrGwkaq-lxzF7M3ZHTil4TSuCKlmzy9pHh6P9WrkRh4=38065B90',
  // );

  static Future<List<Project>> getProjects() async {
    // Create the API wrapper from the http client
    final jira = JiraPlatformApi(client);

    // Communicate with the APIs..
    final projects = await jira.projects.searchProjects();

    return projects.values;
  }

  static Future<void> createIssue() async {
    // Create the API wrapper from the http client
    final jira = JiraPlatformApi(client);

    // Communicate with the APIs..
    await jira.issues.createIssue(
      body: IssueUpdateDetails(
        fields: {},
      ),
    );
  }

  // static Future<List<Avatar>> getAvatars(String projectKey) async {
  //   // Create the API wrapper from the http client
  //   final jira = JiraPlatformApi(client);

  //   // Communicate with the APIs..
  //   final issues = await jira.issues.searchIssues(
  //     jql: 'project = $projectKey',
  //   );

  //   return issues.values;
  // }
}
