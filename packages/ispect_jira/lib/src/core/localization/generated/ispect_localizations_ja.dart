// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ISpectJiraLocalizationJa extends ISpectJiraLocalization {
  ISpectJiraLocalizationJa([String locale = 'ja']) : super(locale);

  @override
  String get successfullyAuthorized => '認証に成功しました';

  @override
  String get pleaseCheckAuthCred => 'エラーが発生しました。認証情報を再確認してください。';

  @override
  String get pickedImages => '選択した画像';

  @override
  String get pleaseAuthToJira => 'Jiraで認証してください';

  @override
  String get pleaseSelectYourProject => '次に、プロジェクトを選択してください';

  @override
  String get addingAttachmentsToIssue => '問題に添付ファイルを追加中';

  @override
  String get addingStatusToIssue => '問題にステータスを追加中';

  @override
  String get apiToken => 'APIトークン';

  @override
  String get attachmentsAdded => '添付ファイルが正常に追加されました';

  @override
  String get authorize => '認証';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String get changeProject => 'プロジェクトを変更';

  @override
  String get createIssue => '問題を作成';

  @override
  String get createJiraIssue => 'Jiraの問題を作成';

  @override
  String get creatingIssue => '問題を作成中';

  @override
  String get finished => '完了';

  @override
  String get fix => '報告';

  @override
  String get retry => '再試行';

  @override
  String get selectAssignee => '担当者を選択';

  @override
  String get selectBoard => 'ボードを選択';

  @override
  String get selectIssueType => '問題タイプを選択';

  @override
  String get selectLabel => 'ラベルを選択';

  @override
  String get selectPriority => '優先度を選択';

  @override
  String get selectSprint => 'スプリントを選択';

  @override
  String get selectStatus => 'ステータスを選択';

  @override
  String get sendIssue => '問題を送信';

  @override
  String get settings => '設定';

  @override
  String get share => '共有';

  @override
  String get submitButtonText => '送信';

  @override
  String get summary => '概要';

  @override
  String totalFilesCount(Object number) {
    return '総ファイル数: $number';
  }

  @override
  String get uploadImages => '画像をアップロード';

  @override
  String get noData => 'データなし';

  @override
  String get fieldIsRequired => 'このフィールドは必須です';

  @override
  String get jiraInstruction =>
      '1. Jiraサイトにアクセスしてください。\n2. 左下のプロフィールアバターをクリックしてください。\n3. プロフィールをクリックしてください。\n4. アカウントの管理をクリックしてください。\n5. セキュリティを選択してください。\n6. APIトークン管理までスクロールしてクリックしてください。\n7. トークンを生成し、コピーして貼り付けてください。';

  @override
  String get projectDomain => 'プロジェクトドメイン';

  @override
  String get userEmail => 'メール';

  @override
  String get projectWasSelected => 'プロジェクトが選択されました';

  @override
  String get issueCreated => '問題が作成されました';

  @override
  String get copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String get description => '説明';
}
