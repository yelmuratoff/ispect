import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'create_issue_state.dart';

class CreateIssueCubit extends Cubit<CreateIssueState> {
  CreateIssueCubit() : super(const CreateIssueState.initial());

  Future<void> createIssue({
    required String assigneeId,
    required String description,
    required String issueTypeId,
    required String statusId,
    required String label,
    required String reporterId,
    required String priorityId,
    required String summary,
    required List<File> attachments,
  }) async {
    emit(
      const CreateIssueState.loading(
        type: CreateIssueEnum.initial,
        message: 'Creating issue',
      ),
    );

    try {
      final issue = await JiraClient.createIssue(
        assigneeId: assigneeId,
        description: description,
        issueTypeId: issueTypeId,
        label: label,
        summary: summary,
        priorityId: priorityId,
      );
      emit(const CreateIssueState.loading(type: CreateIssueEnum.issue, message: 'Adding status to issue'));
      await JiraClient.addStatusToIssue(
        issue: issue,
        statusId: statusId,
      );
      emit(const CreateIssueState.loading(type: CreateIssueEnum.transition, message: 'Adding attachments to issue'));
      if (attachments.isNotEmpty) {
        await JiraClient.addAttachmentsToIssue(
          issue: issue,
          attachments: attachments,
        );
        emit(const CreateIssueState.loading(type: CreateIssueEnum.attachment, message: 'Attachments added'));
      }
      emit(
        CreateIssueState.loaded(
          url: issue.self ?? '',
        ),
      );
    } catch (error, stackTrace) {
      emit(
        CreateIssueState.error(
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
