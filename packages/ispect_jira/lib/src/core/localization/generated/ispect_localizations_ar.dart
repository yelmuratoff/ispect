// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class ISpectJiraLocalizationAr extends ISpectJiraLocalization {
  ISpectJiraLocalizationAr([String locale = 'ar']) : super(locale);

  @override
  String get successfullyAuthorized => 'لقد تم تفويضك بنجاح';

  @override
  String get pleaseCheckAuthCred =>
      'حدث خطأ. يرجى التحقق مرة أخرى من بيانات التفويض الخاصة بك.';

  @override
  String get pickedImages => 'الصور المختارة';

  @override
  String get pleaseAuthToJira => 'يرجى التفويض في Jira';

  @override
  String get pleaseSelectYourProject => 'الآن، يرجى اختيار مشروعك';

  @override
  String get addingAttachmentsToIssue => 'إضافة مرفقات إلى المشكلة';

  @override
  String get addingStatusToIssue => 'إضافة حالة إلى المشكلة';

  @override
  String get apiToken => 'رمز API';

  @override
  String get attachmentsAdded => 'تمت إضافة المرفقات بنجاح';

  @override
  String get authorize => 'تفويض';

  @override
  String get backToHome => 'العودة إلى الصفحة الرئيسية';

  @override
  String get changeProject => 'تغيير المشروع';

  @override
  String get createIssue => 'إنشاء مشكلة';

  @override
  String get createJiraIssue => 'إنشاء مشكلة في Jira';

  @override
  String get creatingIssue => 'جارٍ إنشاء المشكلة';

  @override
  String get finished => 'منتهي';

  @override
  String get fix => 'الإبلاغ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get selectAssignee => 'اختر المُكلف';

  @override
  String get selectBoard => 'اختر اللوحة';

  @override
  String get selectIssueType => 'اختر نوع المشكلة';

  @override
  String get selectLabel => 'اختر التسمية';

  @override
  String get selectPriority => 'اختر الأولوية';

  @override
  String get selectSprint => 'اختر السباق';

  @override
  String get selectStatus => 'اختر الحالة';

  @override
  String get sendIssue => 'إرسال المشكلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get share => 'مشاركة';

  @override
  String get submitButtonText => 'إرسال';

  @override
  String get summary => 'ملخص';

  @override
  String totalFilesCount(Object number) {
    return 'إجمالي عدد الملفات: $number';
  }

  @override
  String get uploadImages => 'رفع الصور';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get fieldIsRequired => 'هذا الحقل مطلوب';

  @override
  String get jiraInstruction =>
      '1. اذهب إلى موقع Jira الخاص بك.\n2. انقر على صورة ملفك الشخصي في الزاوية السفلية اليسرى.\n3. انقر على الملف الشخصي.\n4. انقر على إدارة حسابك.\n5. اختر الأمان.\n6. قم بالتمرير لأسفل إلى إدارة رموز API وانقر عليه.\n7. أنشئ رمزًا، ثم انسخه والصقه.';

  @override
  String get projectDomain => 'نطاق المشروع';

  @override
  String get userEmail => 'البريد الإلكتروني';

  @override
  String get projectWasSelected => 'تم اختيار المشروع';

  @override
  String get issueCreated => 'تم إنشاء المشكلة';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get description => 'الوصف';
}
