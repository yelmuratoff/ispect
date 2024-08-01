// ignore_for_file: avoid_empty_blocks
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
import 'package:ispect/src/common/widgets/textfields/ispect_textfield.dart';
import 'package:ispect/src/features/jira/bloc/current_user/current_user_cubit.dart';
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
    String projectKey,
  ) onAuthorized;
}

class _JiraAuthPageState extends State<JiraAuthPage> {
  final _projectDomainController = TextEditingController(text: 'example');
  final _userEmailController =
      TextEditingController(text: 'name.surname@example.com');
  final _apiTokenController = TextEditingController();

  ProjectsCubit? _bloc;
  final CurrentUserCubit _currentUserCubit = CurrentUserCubit();

  @override
  void initState() {
    super.initState();

    if (JiraClient.isClientInitialized) {
      _currentUserCubit.getCurrentUser();
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
    _currentUserCubit.close();
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
        body: BlocConsumer<CurrentUserCubit, CurrentUserState>(
          bloc: _currentUserCubit,
          listenWhen: (previous, current) => current != previous,
          listener: (context, state) {
            state.mapOrNull(
              loaded: (_) {
                if (JiraClient.isClientInitialized) {
                  ISpectToaster.showSuccessToast(
                    context,
                    title: context.ispectL10n.successfullyAuthorized,
                  );
                  _bloc = ProjectsCubit();
                  _getProjects();
                }
              },
              error: (value) {
                if (value.error.toString().contains('401')) {
                  ISpectToaster.showErrorToast(
                    context,
                    title: context.ispectL10n.pleaseCheckAuthCred,
                  );
                } else {
                  ISpectToaster.showErrorToast(
                    context,
                    title: value.error.toString(),
                  );
                }
                JiraClient.restart();
                setState(() {});
              },
            );
          },
          buildWhen: (previous, current) => current != previous,
          builder: (context, state) => Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!JiraClient.isClientInitialized || state.isError) ...[
                    Text(
                      context.ispectL10n.pleaseAuthToJira,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(14),
                    Text(
                      context.ispectL10n.jiraInstruction,
                    ),
                    const Gap(46),
                    ISpectTextfield(
                      controller: _projectDomainController,
                      hintText: context.ispectL10n.projectDomain,
                    ),
                    const Gap(12),
                    ISpectTextfield(
                      controller: _userEmailController,
                      hintText: context.ispectL10n.userEmail,
                    ),
                    const Gap(12),
                    ISpectTextfield(
                      controller: _apiTokenController,
                      hintText: context.ispectL10n.apiToken,
                    ),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: () {
                        JiraClient.initClient(
                          projectDomain: _projectDomainController.text,
                          userEmail: _userEmailController.text,
                          apiToken: _apiTokenController.text,
                        );
                        _currentUserCubit.getCurrentUser();
                        // _bloc = ProjectsCubit();
                        // _getProjects();
                        setState(() {});
                      },
                      child: Text(context.ispectL10n.authorize),
                    ),
                  ],
                  if (state.isLoading) ...[
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                  if (JiraClient.isClientInitialized && state.isLoaded) ...[
                    state.maybeWhen(
                      loaded: (user) => Text(
                        '${user.displayName}, ${context.ispectL10n.pleaseSelectYourProject.toLowerCase()}:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const Gap(24),
                    BlocConsumer<ProjectsCubit, ProjectsState>(
                      bloc: _bloc,
                      listener: (_, state) {
                        if (state is ProjectsError) {
                          ISpectToaster.showErrorToast(
                            context,
                            title: state.error.toString(),
                          );
                        }
                      },
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
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              onTap: () {
                                JiraClient.projectKey =
                                    state.projects[index].key ?? '';
                                JiraClient.projectId =
                                    state.projects[index].id ?? '';
                                widget.onAuthorized(
                                  JiraClient.projectDomain,
                                  JiraClient.userEmail,
                                  JiraClient.apiToken,
                                  JiraClient.projectId,
                                  JiraClient.projectKey,
                                );
                                ISpectToaster.showSuccessToast(
                                  context,
                                  title:
                                      '${context.ispectL10n.projectWasSelected}: ${state.projects[index].name}',
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
          ),
        ),
      );
}
