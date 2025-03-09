// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class ISpectJiraLocalizationKo extends ISpectJiraLocalization {
  ISpectJiraLocalizationKo([String locale = 'ko']) : super(locale);

  @override
  String get successfullyAuthorized => '성공적으로 인증되었습니다';

  @override
  String get pleaseCheckAuthCred => '오류가 발생했습니다. 인증 정보를 다시 확인해 주세요.';

  @override
  String get pickedImages => '선택된 이미지';

  @override
  String get pleaseAuthToJira => 'Jira에서 인증해 주세요';

  @override
  String get pleaseSelectYourProject => '이제 프로젝트를 선택해 주세요';

  @override
  String get addingAttachmentsToIssue => '문제에 첨부 파일 추가 중';

  @override
  String get addingStatusToIssue => '문제에 상태 추가 중';

  @override
  String get apiToken => 'API 토큰';

  @override
  String get attachmentsAdded => '첨부 파일이 성공적으로 추가됨';

  @override
  String get authorize => '인증';

  @override
  String get backToHome => '홈으로 돌아가기';

  @override
  String get changeProject => '프로젝트 변경';

  @override
  String get createIssue => '문제 생성';

  @override
  String get createJiraIssue => 'Jira 문제 생성';

  @override
  String get creatingIssue => '문제 생성 중';

  @override
  String get finished => '완료';

  @override
  String get fix => '보고';

  @override
  String get retry => '재시도';

  @override
  String get selectAssignee => '담당자 선택';

  @override
  String get selectBoard => '보드 선택';

  @override
  String get selectIssueType => '문제 유형 선택';

  @override
  String get selectLabel => '라벨 선택';

  @override
  String get selectPriority => '우선순위 선택';

  @override
  String get selectSprint => '스프린트 선택';

  @override
  String get selectStatus => '상태 선택';

  @override
  String get sendIssue => '문제 보내기';

  @override
  String get settings => '설정';

  @override
  String get share => '공유';

  @override
  String get submitButtonText => '제출';

  @override
  String get summary => '요약';

  @override
  String totalFilesCount(Object number) {
    return '총 파일 수: $number';
  }

  @override
  String get uploadImages => '이미지 업로드';

  @override
  String get noData => '데이터 없음';

  @override
  String get fieldIsRequired => '이 필드는 필수입니다';

  @override
  String get jiraInstruction => '1. Jira 사이트로 이동하세요.\n2. 좌측 하단의 프로필 아바타를 클릭하세요.\n3. 프로필을 클릭하세요.\n4. 계정 관리를 클릭하세요.\n5. 보안을 선택하세요.\n6. API 토큰 관리로 스크롤한 후 클릭하세요.\n7. 토큰을 생성한 다음 복사하여 붙여넣으세요.';

  @override
  String get projectDomain => '프로젝트 도메인';

  @override
  String get userEmail => '이메일';

  @override
  String get projectWasSelected => '프로젝트가 선택됨';

  @override
  String get issueCreated => '문제가 생성됨';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get description => '설명';
}
