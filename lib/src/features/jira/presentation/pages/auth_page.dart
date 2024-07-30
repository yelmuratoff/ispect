// ignore_for_file: avoid_empty_blocks
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/textfields/ispect_textfield.dart';
import 'package:ispect/src/features/jira/bloc/projects/projects_bloc.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:ispect/src/features/jira/presentation/widgets/error_widget.dart';

class JiraAuthPage extends StatefulWidget {
  const JiraAuthPage({required this.onAuthorized, super.key});

  @override
  State<JiraAuthPage> createState() => _JiraAuthPageState();

  final void Function(
    String domain,
    String email,
    String apiToken,
    String projectId,
  ) onAuthorized;
}

class _JiraAuthPageState extends State<JiraAuthPage> {
  final _projectDomainController = TextEditingController(text: 'example');
  final _userEmailController = TextEditingController(text: 'name.surname@example.com');
  final _apiTokenController = TextEditingController(
    text:
        'ATATT3xFfGF0N50mZgLu8Y5soB3KWORbJNJy74n5YnPHvcCy5534xp9X4yj0vzA-gY-WOwhiSSl3tssTt2IAcrw_gWoW2aED_b-0CRCaG_S5iZnryjmZmnvgmJYSr82UcYDgJmNKWnESLz4B4bzOomWw4-odAGR225VZMx7s-qknsQex-EVdWfs=67D1BA81',
  );

  ProjectsCubit? _bloc;

  @override
  void initState() {
    super.initState();
    if (JiraClient.isInitialized) {
      _getProjects();
    } else if (JiraClient.isClientInitialized && _bloc == null) {
      _bloc = ProjectsCubit();
      _getProjects();
    }
  }

  void _getProjects() {
    _bloc?.getProjects();
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    _userEmailController.dispose();
    _projectDomainController.dispose();
    _bloc?.close();
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
              if (!JiraClient.isClientInitialized) ...[
                const Text(
                  'Please authorize to Jira',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(14),
                const Text(
                  '''1. Go to your Jira website.
                  \n2. Click on your Profile avatar in the bottom left corner.
                  \n3. Click on Profile.
                  \n4. Click Manage your account.
                  \n5. Select Security.
                  \n6. Scroll down to Create and manage API tokens and click on it.
                  \n7. Create a token, then copy and paste it.''',
                ),
                const Gap(24),
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
                    JiraClient.initClient(
                      projectDomain: _projectDomainController.text,
                      userEmail: _userEmailController.text,
                      apiToken: _apiTokenController.text,
                    );
                    _bloc = ProjectsCubit();
                    _getProjects();
                    setState(() {});
                  },
                  child: const Text('Authorize'),
                ),
              ],
              if (JiraClient.isClientInitialized) ...[
                const Text(
                  'Now, please select a project:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(14),
                BlocConsumer<ProjectsCubit, ProjectsState>(
                  bloc: _bloc,
                  listener: (_, __) {},
                  builder: (_, state) => switch (state) {
                    ProjectsInitial() => const SizedBox.shrink(),
                    ProjectsLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ProjectsLoaded() => ColumnBuilder(
                        itemCount: state.projects.length,
                        itemBuilder: (_, index) => ListTile(
                          leading: const Icon(Icons.folder_copy_rounded),
                          title: Text(state.projects[index].name ?? ''),
                          subtitle: Text(state.projects[index].key ?? ''),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          onTap: () {
                            JiraClient.projectKey = state.projects[index].key ?? '';
                            JiraClient.projectId = state.projects[index].id ?? '';
                            widget.onAuthorized(
                              JiraClient.projectDomain,
                              JiraClient.userEmail,
                              JiraClient.apiToken,
                              JiraClient.projectId,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ProjectsError() => JiraErrorWidget(
                        error: state.error,
                        stackTrace: state.stackTrace,
                      ),
                  },
                ),
              ],
            ],
          ),
        ),
      );
}
