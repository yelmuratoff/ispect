// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class ISpectJiraLocalizationPt extends ISpectJiraLocalization {
  ISpectJiraLocalizationPt([String locale = 'pt']) : super(locale);

  @override
  String get successfullyAuthorized => 'Você foi autorizado com sucesso';

  @override
  String get pleaseCheckAuthCred => 'Ocorreu um erro. Por favor, verifique novamente suas credenciais de autorização.';

  @override
  String get pickedImages => 'Imagens selecionadas';

  @override
  String get pleaseAuthToJira => 'Por favor, autorize no Jira';

  @override
  String get pleaseSelectYourProject => 'Agora, por favor, selecione seu projeto';

  @override
  String get addingAttachmentsToIssue => 'Adicionando anexos ao problema';

  @override
  String get addingStatusToIssue => 'Adicionando status ao problema';

  @override
  String get apiToken => 'Token de API';

  @override
  String get attachmentsAdded => 'Anexos adicionados com sucesso';

  @override
  String get authorize => 'Autorizar';

  @override
  String get backToHome => 'Voltar ao início';

  @override
  String get changeProject => 'Mudar de projeto';

  @override
  String get createIssue => 'Criar problema';

  @override
  String get createJiraIssue => 'Criar problema no Jira';

  @override
  String get creatingIssue => 'Criando problema';

  @override
  String get finished => 'Concluído';

  @override
  String get fix => 'Relatar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get selectAssignee => 'Selecionar responsável';

  @override
  String get selectBoard => 'Selecionar quadro';

  @override
  String get selectIssueType => 'Selecionar tipo de problema';

  @override
  String get selectLabel => 'Selecionar rótulo';

  @override
  String get selectPriority => 'Selecionar prioridade';

  @override
  String get selectSprint => 'Selecionar sprint';

  @override
  String get selectStatus => 'Selecionar status';

  @override
  String get sendIssue => 'Enviar problema';

  @override
  String get settings => 'Configurações';

  @override
  String get share => 'Compartilhar';

  @override
  String get submitButtonText => 'Enviar';

  @override
  String get summary => 'Resumo';

  @override
  String totalFilesCount(Object number) {
    return 'Contagem total de arquivos: $number';
  }

  @override
  String get uploadImages => 'Carregar imagens';

  @override
  String get noData => 'Sem dados';

  @override
  String get fieldIsRequired => 'Este campo é obrigatório';

  @override
  String get jiraInstruction => '1. Acesse o site do Jira.\n2. Clique no seu avatar de perfil no canto inferior esquerdo.\n3. Clique em Perfil.\n4. Clique em Gerenciar sua conta.\n5. Selecione Segurança.\n6. Role para baixo até a gestão de tokens de API e clique nisso.\n7. Gere um token, depois copie e cole-o.';

  @override
  String get projectDomain => 'Domínio do projeto';

  @override
  String get userEmail => 'E-mail';

  @override
  String get projectWasSelected => 'Projeto selecionado';

  @override
  String get issueCreated => 'Problema criado';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get description => 'Descrição';
}
