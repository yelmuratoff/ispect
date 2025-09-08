// ignore_for_file: avoid_empty_blocks
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/src/jira/bloc/current_user/current_user_cubit.dart';
import 'package:ispect_jira/src/jira/bloc/projects/projects_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:ispect_jira/src/jira/presentation/widgets/error_widget.dart';
import 'package:ispect_jira/src/common/widgets/ispect_textfield.dart';
import 'package:ispect_jira/src/core/localization/generated/ispect_localizations.dart';

class JiraAuthScreen extends StatefulWidget {
  const JiraAuthScreen({required this.onAuthorized, super.key});

  @override
  State<JiraAuthScreen> createState() => _JiraAuthScreenState();

  final void Function(
    String domain,
    String email,
    String apiToken,
    String projectId,
    String projectKey,
  ) onAuthorized;
}

class _JiraAuthScreenState extends State<JiraAuthScreen> {
  final _projectDomainController = TextEditingController(text: 'example');
  final _userEmailController =
      TextEditingController(text: 'name.surname@example.com');
  final _apiTokenController = TextEditingController();

  ProjectsCubit? _bloc;
  final CurrentUserCubit _currentUserCubit = CurrentUserCubit();

  @override
  void initState() {
    super.initState();

    if (ISpectJiraClient.isClientInitialized) {
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
                if (ISpectJiraClient.isClientInitialized) {
                  ISpectToaster.showSuccessToast(
                    context,
                    title: ISpectJiraLocalization.of(context)!
                        .successfullyAuthorized,
                  );
                  _bloc = ProjectsCubit();
                  _getProjects();
                }
              },
              error: (value) {
                if (value.error.toString().contains('401')) {
                  ISpectToaster.showErrorToast(
                    context,
                    title:
                        ISpectJiraLocalization.of(context)!.pleaseCheckAuthCred,
                  );
                } else {
                  ISpectToaster.showErrorToast(
                    context,
                    title: value.error.toString(),
                  );
                }
                ISpectJiraClient.restart();
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
                  if (!ISpectJiraClient.isClientInitialized ||
                      state.isError) ...[
                    Text(
                      ISpectJiraLocalization.of(context)!.pleaseAuthToJira,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ISpectJiraLocalization.of(context)!.jiraInstruction,
                    ),
                    const SizedBox(height: 46),
                    ISpectTextfield(
                      controller: _projectDomainController,
                      hintText:
                          ISpectJiraLocalization.of(context)!.projectDomain,
                    ),
                    const SizedBox(height: 12),
                    ISpectTextfield(
                      controller: _userEmailController,
                      hintText: ISpectJiraLocalization.of(context)!.userEmail,
                    ),
                    const SizedBox(height: 12),
                    ISpectTextfield(
                      controller: _apiTokenController,
                      hintText: ISpectJiraLocalization.of(context)!.apiToken,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ISpectJiraClient.initClient(
                          projectDomain: _projectDomainController.text,
                          userEmail: _userEmailController.text,
                          apiToken: _apiTokenController.text,
                        );
                        _currentUserCubit.getCurrentUser();
                        setState(() {});
                      },
                      child:
                          Text(ISpectJiraLocalization.of(context)!.authorize),
                    ),
                  ],
                  if (state.isLoading) ...[
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                  if (ISpectJiraClient.isClientInitialized &&
                      state.isLoaded) ...[
                    state.maybeWhen(
                      loaded: (user) => Text(
                        '${user.displayName}, ${ISpectJiraLocalization.of(context)!.pleaseSelectYourProject.toLowerCase()}:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
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
                        ProjectsLoaded() => ISpectColumnBuilder(
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
                                ISpectJiraClient.projectKey =
                                    state.projects[index].key ?? '';
                                ISpectJiraClient.projectId =
                                    state.projects[index].id ?? '';
                                widget.onAuthorized(
                                  ISpectJiraClient.projectDomain,
                                  ISpectJiraClient.userEmail,
                                  ISpectJiraClient.apiToken,
                                  ISpectJiraClient.projectId,
                                  ISpectJiraClient.projectKey,
                                );
                                ISpectToaster.showSuccessToast(
                                  context,
                                  title:
                                      '${ISpectJiraLocalization.of(context)!.projectWasSelected}: ${state.projects[index].name}',
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
