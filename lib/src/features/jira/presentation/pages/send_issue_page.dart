import 'dart:io';

import 'package:atlassian_apis/jira_platform.dart' as jira;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/textfields/ispect_textfield.dart';
import 'package:ispect/src/features/jira/bloc/boards/boards_cubit.dart';
import 'package:ispect/src/features/jira/bloc/labels/labels_bloc.dart';
import 'package:ispect/src/features/jira/bloc/sprint/sprint_cubit.dart';
import 'package:ispect/src/features/jira/bloc/status/status_bloc.dart';
import 'package:ispect/src/features/jira/bloc/users/users_cubit.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:ispect/src/features/jira/models/board.dart';
import 'package:ispect/src/features/jira/models/sprint.dart';
import 'package:ispect/src/features/jira/presentation/widgets/error_widget.dart';

class JiraSendIssuePage extends StatefulWidget {
  const JiraSendIssuePage({
    super.key,
    this.initialDescription,
    this.initialAttachmentPath,
  });

  final String? initialDescription;
  final String? initialAttachmentPath;

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

  // <-- Fields -->

  jira.StatusDetails? _selectedStatus;
  jira.IssueTypeWithStatus? _selectedIssueType;
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedLabel;
  jira.User? _selectedAssignee;
  JiraBoard? _selectedBoard;
  JiraSprint? _selectedSprint;
  final List<File> _attachments = [];

  @override
  void initState() {
    super.initState();
    _statusCubit.getStatuses();
    _labelsCubit.getLabels();
    _usersCubit.getUsers();
    _boardsCubit.getBoards();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Send issue'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
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
                          hintText: 'Select issue type',
                          isRequired: true,
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
                          hintText: 'Select status',
                          isRequired: true,
                          items: list.first.statuses
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '${e.name} ${e.id}',
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
                  hintText: 'Summary',
                  isRequired: true,
                ),
                const Gap(16),
                ISpectTextfield(
                  controller: _descriptionController,
                  hintText: 'Description',
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
                          hintText: 'Select label',
                          isRequired: true,
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
                BlocBuilder<UsersCubit, UsersState>(
                  bloc: _usersCubit,
                  builder: (_, state) => state.maybeWhen(
                    orElse: () => const SizedBox(),
                    loaded: (list) => Column(
                      children: [
                        ISpectDropDown(
                          value: _selectedAssignee,
                          hintText: 'Select assignee',
                          isRequired: true,
                          items: list
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Row(
                                    children: [
                                      if (e.avatarUrls != null) ...[
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(e.avatarUrls!.$24X24 ?? ''),
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
                    loaded: (list) => Column(
                      children: [
                        ISpectDropDown(
                          value: _selectedBoard,
                          hintText: 'Select board',
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
                            if (value != null) {
                              _sprintCubit.getSprints(boardId: value.id);
                            }
                            setState(() {
                              _selectedBoard = value;
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
                BlocBuilder<SprintCubit, SprintState>(
                  bloc: _sprintCubit,
                  builder: (_, state) => state.maybeWhen(
                    orElse: () => const SizedBox(),
                    loaded: (list) => Column(
                      children: [
                        ISpectDropDown(
                          value: _selectedSprint,
                          hintText: 'Select sprint',
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
                const Gap(16),
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
                          _attachments.addAll(filePicker.paths.map((e) => File(e!)));
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: const Text('Upload images'),
                  ),
                ),
                const Gap(16),
                if (_attachments.isNotEmpty) ...[
                  const Text('Picked images'),
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
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      JiraClient.createIssue(
                        assigneeId: _selectedAssignee?.accountId ?? '',
                        description: _descriptionController.text,
                        issueTypeId: _selectedIssueType?.id ?? '',
                        label: _selectedLabel ?? '',
                        reporterId: _selectedAssignee?.accountId ?? '',
                        summary: _summaryController.text,
                        statusId: _selectedStatus?.id ?? '',
                        attachments: _attachments,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: const Text('Send issue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ISpectDropDown<T> extends StatelessWidget {
  const ISpectDropDown({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.isRequired = false,
    super.key,
  });

  final String hintText;
  final T value;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T? value)? onChanged;
  final bool isExpanded;
  final bool isRequired;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.fromBorderSide(
            BorderSide(
              color: context.ispectTheme.dividerColor,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButton<T>(
            hint: Text.rich(
              TextSpan(
                text: hintText,
                children: [
                  if (isRequired) ...[
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            elevation: 0,
            selectedItemBuilder: (_) => items!
                .map(
                  (e) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                      ),
                      child: e.child,
                    ),
                  ),
                )
                .toList(),
            isExpanded: isExpanded,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            dropdownColor: context.ispectTheme.colorScheme.surfaceContainer,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            value: value,
            // decoration: InputDecoration(
            //   contentPadding: const EdgeInsets.all(12),
            //   hintStyle: TextStyle(
            //     color: context.ispectTheme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            //     fontSize: 14,
            //   ),
            //   border: const OutlineInputBorder(
            //     borderRadius: BorderRadius.all(Radius.circular(8)),
            //   ),
            // ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}
