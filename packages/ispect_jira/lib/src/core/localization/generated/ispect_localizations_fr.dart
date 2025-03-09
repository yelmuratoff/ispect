// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ISpectJiraLocalizationFr extends ISpectJiraLocalization {
  ISpectJiraLocalizationFr([String locale = 'fr']) : super(locale);

  @override
  String get successfullyAuthorized => 'Vous avez été autorisé avec succès';

  @override
  String get pleaseCheckAuthCred =>
      'Une erreur s\'est produite. Veuillez revérifier vos identifiants d\'autorisation.';

  @override
  String get pickedImages => 'Images sélectionnées';

  @override
  String get pleaseAuthToJira => 'Veuillez vous authentifier sur Jira';

  @override
  String get pleaseSelectYourProject =>
      'Maintenant, veuillez sélectionner votre projet';

  @override
  String get addingAttachmentsToIssue => 'Ajout de pièces jointes au problème';

  @override
  String get addingStatusToIssue => 'Ajout d\'un statut au problème';

  @override
  String get apiToken => 'Jeton API';

  @override
  String get attachmentsAdded => 'Pièces jointes ajoutées avec succès';

  @override
  String get authorize => 'Autoriser';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get changeProject => 'Changer de projet';

  @override
  String get createIssue => 'Créer un problème';

  @override
  String get createJiraIssue => 'Créer un problème Jira';

  @override
  String get creatingIssue => 'Création d\'un problème';

  @override
  String get finished => 'Terminé';

  @override
  String get fix => 'Signaler';

  @override
  String get retry => 'Réessayer';

  @override
  String get selectAssignee => 'Sélectionner un assigné';

  @override
  String get selectBoard => 'Sélectionner un tableau';

  @override
  String get selectIssueType => 'Sélectionner un type de problème';

  @override
  String get selectLabel => 'Sélectionner une étiquette';

  @override
  String get selectPriority => 'Sélectionner une priorité';

  @override
  String get selectSprint => 'Sélectionner un sprint';

  @override
  String get selectStatus => 'Sélectionner un statut';

  @override
  String get sendIssue => 'Envoyer le problème';

  @override
  String get settings => 'Paramètres';

  @override
  String get share => 'Partager';

  @override
  String get submitButtonText => 'Soumettre';

  @override
  String get summary => 'Résumé';

  @override
  String totalFilesCount(Object number) {
    return 'Nombre total de fichiers : $number';
  }

  @override
  String get uploadImages => 'Télécharger des images';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get fieldIsRequired => 'Ce champ est requis';

  @override
  String get jiraInstruction =>
      '1. Rendez-vous sur votre site Jira.\n2. Cliquez sur votre avatar de profil dans le coin inférieur gauche.\n3. Cliquez sur Profil.\n4. Cliquez sur Gérer votre compte.\n5. Sélectionnez Sécurité.\n6. Faites défiler jusqu\'à la gestion des jetons API et cliquez dessus.\n7. Générez un jeton, puis copiez-le et collez-le.';

  @override
  String get projectDomain => 'Domaine du projet';

  @override
  String get userEmail => 'Email';

  @override
  String get projectWasSelected => 'Projet sélectionné';

  @override
  String get issueCreated => 'Problème créé';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get description => 'Description';
}
