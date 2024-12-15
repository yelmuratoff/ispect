// ignore_for_file: avoid_empty_blocks
import 'dart:io';

import 'package:atlassian_apis/jira_platform.dart' as jira;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
import 'package:ispect/src/common/widgets/textfields/ispect_textfield.dart';
import 'package:ispect/src/features/jira/bloc/boards/boards_cubit.dart';
import 'package:ispect/src/features/jira/bloc/create_issue/create_issue_cubit.dart';
import 'package:ispect/src/features/jira/bloc/labels/labels_bloc.dart';
import 'package:ispect/src/features/jira/bloc/priority/priority_cubit.dart';
import 'package:ispect/src/features/jira/bloc/sprint/sprint_cubit.dart';
import 'package:ispect/src/features/jira/bloc/status/status_bloc.dart';
import 'package:ispect/src/features/jira/bloc/users/users_cubit.dart';
import 'package:ispect/src/features/jira/models/board.dart';
import 'package:ispect/src/features/jira/models/sprint.dart';
import 'package:ispect/src/features/jira/presentation/pages/auth_page.dart';
import 'package:ispect/src/features/jira/presentation/widgets/error_widget.dart';

class JiraSendIssuePage extends StatefulWidget {
  const JiraSendIssuePage({
    super.key,
    this.initialDescription,
    this.initialAttachmentPath,
    this.onJiraAuthorized,
  });

  final String? initialDescription;
  final String? initialAttachmentPath;
  final void Function(
    String domain,
    String email,
    String apiToken,
    String projectId,
    String projectKey,
  )? onJiraAuthorized;

  @override
  State<JiraSendIssuePage> createState() => _JiraSendIssuePageState();
}

class _JiraSendIssuePageState extends State<JiraSendIssuePage> {
  // <-- BLoCs -->

  final StatusCubit _statusCubit = StatusCubit();
  final LabelsCubit _labelsCubit = LabelsCubit();
  final UsersCubit _usersCubit = UsersCubit();
  final BoardsCubit _boardsCubit = BoardsCubit();
  final SprintCubit _sprintCubit = SprintCubit();
  final PriorityCubit _priorityCubit = PriorityCubit();
  final CreateIssueCubit _createIssueCubit = CreateIssueCubit();

  // <-- Fields -->

  jira.StatusDetails? _selectedStatus;
  jira.IssueTypeWithStatus? _selectedIssueType;
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedLabel;
  jira.User? _selectedAssignee;
  JiraBoard? _selectedBoard;
  JiraSprint? _selectedSprint;
  jira.Priority? _selectedPriority;
  final List<File> _attachments = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _statusCubit.getStatuses();
    _labelsCubit.getLabels();
    _usersCubit.getUsers();
    _boardsCubit.getBoards();
    _priorityCubit.getPriorities();
    _descriptionController.text = widget.initialDescription ?? '';
    if (widget.initialAttachmentPath != null) {
      _attachments.add(File(widget.initialAttachmentPath ?? ''));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _summaryController.dispose();
    _statusCubit.close();
    _labelsCubit.close();
    _usersCubit.close();
    _boardsCubit.close();
    _priorityCubit.close();
    _createIssueCubit.close();
    super.dispose();
  }

  void _createOverlay({
    required String message,
  }) {
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: () {
          _overlayEntry?.remove();
        },
        behavior: HitTestBehavior.translucent,
        child: ColoredBox(
          color: context.ispectTheme.colorScheme.surface.withValues(alpha: 0.8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const Gap(16),
                Text(
                  message,
                  style: TextStyle(
                    color: context.ispectTheme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.ispectL10n.createIssue),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (_) => JiraAuthPage(
                      onAuthorized: (domain, email, apiToken, projectId, projectKey) {
                        widget.onJiraAuthorized?.call(
                          domain,
                          email,
                          apiToken,
                          projectId,
                          projectKey,
                        );

                        // <-- Clear selected data -->

                        setState(() {
                          _selectedStatus = null;
                          _selectedIssueType = null;
                          _summaryController.clear();
                          _descriptionController.clear();
                          _selectedLabel = null;
                          _selectedAssignee = null;
                          _selectedBoard = null;
                          _selectedSprint = null;
                          _selectedPriority = null;
                          _attachments.clear();
                        });

                        // <-- Refresh data -->

                        _statusCubit.getStatuses();
                        _labelsCubit.getLabels();
                        _usersCubit.getUsers();
                        _boardsCubit.getBoards();
                        _sprintCubit.toInitial();
                        _priorityCubit.getPriorities();
                        _descriptionController.text = widget.initialDescription ?? '';
                        if (widget.initialAttachmentPath != null) {
                          _attachments.add(File(widget.initialAttachmentPath ?? ''));
                        }
                      },
                    ),
                    settings: const RouteSettings(
                      name: 'JiraAuthPage',
                    ),
                  ),
                );
              },
              color: context.ispectTheme.colorScheme.primaryContainer,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(context.ispectL10n.changeProject),
            ),
            const Gap(8),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MaterialButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _createIssueCubit.createIssue(
                    assigneeId: _selectedAssignee?.accountId ?? '',
                    description: _descriptionController.text,
                    issueTypeId: _selectedIssueType?.id ?? '',
                    label: _selectedLabel ?? '',
                    summary: _summaryController.text,
                    statusId: _selectedStatus?.id ?? '',
                    attachments: _attachments,
                    priorityId: _selectedPriority?.id ?? '',
                  );
                }
              },
              color: context.ispectTheme.colorScheme.primaryContainer,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    context.ispectL10n.sendIssue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),
                  const Icon(Icons.send),
                ],
              ),
            ),
          ],
        ),
        body: BlocListener<CreateIssueCubit, CreateIssueState>(
          bloc: _createIssueCubit,
          listener: (_, state) {
            state.maybeWhen(
              loading: (type, _) {
                _overlayEntry?.remove();
                _overlayEntry = null;

                _createOverlay(message: _getMessageFromType(type));
              },
              loaded: (issueUrl) async {
                _overlayEntry?.remove();
                _overlayEntry = null;

                await ISpectToaster.hideToast(context);
                if (context.mounted) {
                  await ISpectToaster.showSuccessToast(
                    context,
                    title: context.ispectL10n.issueCreated,
                  );
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  await Clipboard.setData(ClipboardData(text: issueUrl));
                  if (context.mounted) {
                    await ISpectToaster.showCopiedToast(
                      context,
                      title: context.ispectL10n.copiedToClipboard,
                      value: 'Issue key: $issueUrl',
                    );
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              orElse: () {},
            );
          },
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<StatusCubit, StatusState>(
                      bloc: _statusCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ISpectDropDown(
                              value: _selectedIssueType,
                              hintText: context.ispectL10n.selectIssueType,
                              isRequired: true,
                              maxWidth: 280,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedIssueType = value;
                                });
                              },
                            ),
                            const Gap(16),
                            ISpectDropDown(
                              value: _selectedStatus,
                              hintText: context.ispectL10n.selectStatus,
                              isRequired: true,
                              maxWidth: 300,
                              items: list.first.statuses
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        '${e.name}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ],
                        ),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    const Gap(16),
                    ISpectTextfield(
                      controller: _summaryController,
                      hintText: context.ispectL10n.summary,
                      isRequired: true,
                    ),
                    const Gap(16),
                    ISpectTextfield(
                      controller: _descriptionController,
                      hintText: context.ispectL10n.description,
                      minLines: 5,
                    ),
                    const Gap(16),
                    BlocBuilder<LabelsCubit, LabelsState>(
                      bloc: _labelsCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => Column(
                          children: [
                            ISpectDropDown(
                              value: _selectedLabel,
                              hintText: context.ispectL10n.selectLabel,
                              isRequired: true,
                              maxWidth: 300,
                              items: list.values
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLabel = value;
                                });
                              },
                            ),
                          ],
                        ),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    const Gap(16),
                    BlocBuilder<PriorityCubit, PriorityState>(
                      bloc: _priorityCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => Column(
                          children: [
                            ISpectDropDown(
                              value: _selectedPriority,
                              hintText: context.ispectL10n.selectPriority,
                              isRequired: true,
                              maxWidth: 300,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e.name ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              },
                            ),
                          ],
                        ),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    const Gap(16),
                    BlocBuilder<UsersCubit, UsersState>(
                      bloc: _usersCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => Column(
                          children: [
                            ISpectDropDown(
                              value: _selectedAssignee,
                              hintText: context.ispectL10n.selectAssignee,
                              isRequired: true,
                              maxWidth: 360,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          if (e.avatarUrls != null) ...[
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                e.avatarUrls!.$24X24 ?? '',
                                              ),
                                              minRadius: 14,
                                            ),
                                            const Gap(12),
                                          ],
                                          Expanded(
                                            child: Text(
                                              e.displayName ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAssignee = value;
                                });
                              },
                            ),
                          ],
                        ),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    const Gap(16),
                    BlocBuilder<BoardsCubit, BoardsState>(
                      bloc: _boardsCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => list.isNotEmpty
                            ? Column(
                                children: [
                                  ISpectDropDown(
                                    value: _selectedBoard,
                                    hintText: context.ispectL10n.selectBoard,
                                    maxWidth: 360,
                                    items: list
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    e.name,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _sprintCubit.getSprints(
                                          boardId: value.id,
                                        );
                                      }
                                      setState(() {
                                        _selectedBoard = value;
                                      });
                                    },
                                  ),
                                  const Gap(16),
                                ],
                              )
                            : const SizedBox(),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    BlocBuilder<SprintCubit, SprintState>(
                      bloc: _sprintCubit,
                      builder: (_, state) => state.maybeWhen(
                        orElse: () => const SizedBox(),
                        loaded: (list) => Column(
                          children: [
                            ISpectDropDown(
                              value: _selectedSprint,
                              hintText: context.ispectL10n.selectSprint,
                              maxWidth: 360,
                              isRequired: true,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              e.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSprint = value;
                                });
                              },
                            ),
                            const Gap(16),
                          ],
                        ),
                        error: (error, stackTrace) => JiraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () async {
                          final filePicker = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.image,
                          );
                          if (filePicker != null) {
                            setState(() {
                              _attachments.addAll(
                                filePicker.paths.map((e) => File(e!)),
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined),
                            const Gap(16),
                            Text(context.ispectL10n.uploadImages),
                          ],
                        ),
                      ),
                    ),
                    const Gap(16),
                    if (_attachments.isNotEmpty) ...[
                      Text(context.ispectL10n.pickedImages),
                      const Gap(16),
                      ColumnBuilder(
                        itemCount: _attachments.length,
                        itemBuilder: (_, index) {
                          final file = _attachments[index];
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      file.path.split('/').last,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const Gap(8),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _attachments.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Gap(8),
                              ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                child: Image.file(
                                  file,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  String _getMessageFromType(CreateIssueEnum type) => switch (type) {
        CreateIssueEnum.initial => context.ispectL10n.creatingIssue,
        CreateIssueEnum.issue => context.ispectL10n.addingStatusToIssue,
        CreateIssueEnum.attachment => context.ispectL10n.attachmentsAdded,
        CreateIssueEnum.transition => context.ispectL10n.addingAttachmentsToIssue,
        CreateIssueEnum.finished => context.ispectL10n.finished,
      };
}

class ISpectDropDown<T> extends StatelessWidget {
  const ISpectDropDown({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.isRequired = false,
    this.maxWidth = 350,
    super.key,
  });

  final String hintText;
  final T value;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T? value)? onChanged;
  final bool isExpanded;
  final bool isRequired;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DropdownButtonFormField<T>(
            hint: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth - 80,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: hintText,
                      ),
                      style: const TextStyle(
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Gap(8),
                  if (isRequired) ...[
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            elevation: 0,
            validator: (value) {
              if (isRequired && value == null) {
                return context.ispectL10n.fieldIsRequired;
              }
              return null;
            },
            icon: const Icon(Icons.arrow_drop_down),
            selectedItemBuilder: (_) => items!
                .map(
                  (e) => ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth - 80,
                      minWidth: 100,
                    ),
                    child: e.child,
                  ),
                )
                .toList(),
            isExpanded: isExpanded,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: context.ispectTheme.dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: context.ispectTheme.dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: context.ispectTheme.dividerColor,
                ),
              ),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            dropdownColor: context.ispectTheme.colorScheme.surfaceContainer,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}
