// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ISpectJiraLocalizationZh extends ISpectJiraLocalization {
  ISpectJiraLocalizationZh([String locale = 'zh']) : super(locale);

  @override
  String get successfullyAuthorized => '您已成功授权';

  @override
  String get pleaseCheckAuthCred => '发生错误。请仔细检查您的授权凭据。';

  @override
  String get pickedImages => '已选图片';

  @override
  String get pleaseAuthToJira => '请在Jira中授权';

  @override
  String get pleaseSelectYourProject => '现在，请选择您的项目';

  @override
  String get addingAttachmentsToIssue => '正在向问题添加附件';

  @override
  String get addingStatusToIssue => '正在向问题添加状态';

  @override
  String get apiToken => 'API令牌';

  @override
  String get attachmentsAdded => '附件添加成功';

  @override
  String get authorize => '授权';

  @override
  String get backToHome => '返回首页';

  @override
  String get changeProject => '更改项目';

  @override
  String get createIssue => '创建问题';

  @override
  String get createJiraIssue => '创建Jira问题';

  @override
  String get creatingIssue => '正在创建问题';

  @override
  String get finished => '已完成';

  @override
  String get fix => '报告';

  @override
  String get retry => '重试';

  @override
  String get selectAssignee => '选择指派人';

  @override
  String get selectBoard => '选择看板';

  @override
  String get selectIssueType => '选择问题类型';

  @override
  String get selectLabel => '选择标签';

  @override
  String get selectPriority => '选择优先级';

  @override
  String get selectSprint => '选择冲刺';

  @override
  String get selectStatus => '选择状态';

  @override
  String get sendIssue => '发送问题';

  @override
  String get settings => '设置';

  @override
  String get share => '分享';

  @override
  String get submitButtonText => '提交';

  @override
  String get summary => '概要';

  @override
  String totalFilesCount(Object number) {
    return '文件总数：$number';
  }

  @override
  String get uploadImages => '上传图片';

  @override
  String get noData => '无数据';

  @override
  String get fieldIsRequired => '此字段为必填项';

  @override
  String get jiraInstruction =>
      '1. 前往您的Jira站点。\n2. 点击左下角的个人资料头像。\n3. 点击“个人资料”。\n4. 点击“管理您的账户”。\n5. 选择“安全”。\n6. 向下滚动至API令牌管理并点击。\n7. 生成一个令牌，然后复制并粘贴。';

  @override
  String get projectDomain => '项目域名';

  @override
  String get userEmail => '电子邮件';

  @override
  String get projectWasSelected => '项目已选择';

  @override
  String get issueCreated => '问题已创建';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get description => '描述';
}
