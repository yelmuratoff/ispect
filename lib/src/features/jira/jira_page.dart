// ignore_for_file: avoid_empty_blocks
import 'package:atlassian_apis/jira_platform.dart' as jira;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/ispect_textfield.dart';
import 'package:ispect/src/features/jira/jira_client.dart';

class JiraPage extends StatefulWidget {
  const JiraPage({required this.onAuthorized, super.key});

  @override
  State<JiraPage> createState() => _JiraPageState();

  final void Function(
    String domain,
    String email,
    String apiToken,
  ) onAuthorized;
}

class _JiraPageState extends State<JiraPage> {
  final _projectDomainController = TextEditingController(text: 'anydevkz');
  final _userEmailController =
      TextEditingController(text: 'y.yelmuratov@astanahub.com');
  final _apiTokenController = TextEditingController(
    text: '',
  );

  List<jira.Project> _projects = <jira.Project>[];

  @override
  void initState() {
    super.initState();
    _getProjects();
  }

  Future<void> _getProjects() async {
    final projects = await JiraClient.getProjects();
    setState(() {
      _projects = projects;
    });
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    _userEmailController.dispose();
    _projectDomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Jira'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!JiraClient.isInitialized) ...[
                const Text(
                  'Please authorize to Jira',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(14),
                ISpectTextfield(
                  controller: _projectDomainController,
                  hintText: 'Project domain',
                ),
                const Gap(12),
                ISpectTextfield(
                  controller: _userEmailController,
                  hintText: 'User email',
                ),
                const Gap(12),
                ISpectTextfield(
                  controller: _apiTokenController,
                  hintText: 'API token',
                ),
                const Gap(12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.onAuthorized(
                        _projectDomainController.text,
                        _userEmailController.text,
                        _apiTokenController.text,
                      );
                    });
                  },
                  child: const Text('Authorize'),
                ),
              ],
              if (JiraClient.isInitialized) ...[
                ElevatedButton(
                  onPressed: () async {
                    // final issues = await JiraClient.getIssues();
                    // print(issues.sections.first.issues.first.summary);
                  },
                  child: const Text(
                    'Get issues',
                  ),
                ),
                ColumnBuilder(
                  itemCount: _projects.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.folder_copy_rounded),
                    title: Text(_projects[index].name ?? ''),
                    subtitle: Text(_projects[index].key ?? ''),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
