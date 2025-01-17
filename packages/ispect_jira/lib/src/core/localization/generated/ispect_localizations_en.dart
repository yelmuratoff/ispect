import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ISpectJiraLocalizationEn extends ISpectJiraLocalization {
  ISpectJiraLocalizationEn([String locale = 'en']) : super(locale);

  @override
  String get successfullyAuthorized => 'You have successfully authorized';

  @override
  String get pleaseCheckAuthCred => 'An error occurred. Please double-check your authorization credentials.';

  @override
  String get pickedImages => 'Selected images';

  @override
  String get pleaseAuthToJira => 'Please authorize in Jira';

  @override
  String get pleaseSelectYourProject => 'Now, please select your project';

  @override
  String get addingAttachmentsToIssue => 'Adding attachments to the issue';

  @override
  String get addingStatusToIssue => 'Adding status to the issue';

  @override
  String get apiToken => 'API token';

  @override
  String get attachmentsAdded => 'Attachments added successfully';

  @override
  String get authorize => 'Authorize';

  @override
  String get backToHome => 'Back to home';

  @override
  String get changeProject => 'Change project';

  @override
  String get createIssue => 'Create issue';

  @override
  String get createJiraIssue => 'Create Jira issue';

  @override
  String get creatingIssue => 'Creating issue';

  @override
  String get finished => 'Finished';

  @override
  String get fix => 'Report';

  @override
  String get retry => 'Retry';

  @override
  String get selectAssignee => 'Select assignee';

  @override
  String get selectBoard => 'Select board';

  @override
  String get selectIssueType => 'Select issue type';

  @override
  String get selectLabel => 'Select label';

  @override
  String get selectPriority => 'Select priority';

  @override
  String get selectSprint => 'Select sprint';

  @override
  String get selectStatus => 'Select status';

  @override
  String get sendIssue => 'Send issue';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get submitButtonText => 'Submit';

  @override
  String get summary => 'Summary';

  @override
  String totalFilesCount(Object number) {
    return 'Total files count: $number';
  }

  @override
  String get uploadImages => 'Upload images';

  @override
  String get noData => 'No data';

  @override
  String get fieldIsRequired => 'This field is required';

  @override
  String get jiraInstruction => '1. Go to your Jira site.\n2. Click your profile avatar in the bottom-left corner.\n3. Click on Profile.\n4. Click Manage your account.\n5. Select Security.\n6. Scroll down to API token management and click on it.\n7. Generate a token, then copy and paste it.';

  @override
  String get projectDomain => 'Project domain';

  @override
  String get userEmail => 'Email';

  @override
  String get projectWasSelected => 'Project selected';

  @override
  String get issueCreated => 'Issue created';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get description => 'Description';
}
