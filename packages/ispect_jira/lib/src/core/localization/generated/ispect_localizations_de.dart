// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ISpectJiraLocalizationDe extends ISpectJiraLocalization {
  ISpectJiraLocalizationDe([String locale = 'de']) : super(locale);

  @override
  String get successfullyAuthorized => 'Sie haben sich erfolgreich autorisiert';

  @override
  String get pleaseCheckAuthCred => 'Ein Fehler ist aufgetreten. Bitte überprüfen Sie Ihre Autorisierungsdaten erneut.';

  @override
  String get pickedImages => 'Ausgewählte Bilder';

  @override
  String get pleaseAuthToJira => 'Bitte autorisieren Sie sich bei Jira';

  @override
  String get pleaseSelectYourProject => 'Bitte wählen Sie jetzt Ihr Projekt aus';

  @override
  String get addingAttachmentsToIssue => 'Hinzufügen von Anhängen zum Problem';

  @override
  String get addingStatusToIssue => 'Hinzufügen eines Status zum Problem';

  @override
  String get apiToken => 'API-Token';

  @override
  String get attachmentsAdded => 'Anhänge erfolgreich hinzugefügt';

  @override
  String get authorize => 'Autorisieren';

  @override
  String get backToHome => 'Zurück zur Startseite';

  @override
  String get changeProject => 'Projekt ändern';

  @override
  String get createIssue => 'Problem erstellen';

  @override
  String get createJiraIssue => 'Jira-Problem erstellen';

  @override
  String get creatingIssue => 'Problem wird erstellt';

  @override
  String get finished => 'Abgeschlossen';

  @override
  String get fix => 'Melden';

  @override
  String get retry => 'Wiederholen';

  @override
  String get selectAssignee => 'Zuständigen auswählen';

  @override
  String get selectBoard => 'Board auswählen';

  @override
  String get selectIssueType => 'Problemtyp auswählen';

  @override
  String get selectLabel => 'Label auswählen';

  @override
  String get selectPriority => 'Priorität auswählen';

  @override
  String get selectSprint => 'Sprint auswählen';

  @override
  String get selectStatus => 'Status auswählen';

  @override
  String get sendIssue => 'Problem senden';

  @override
  String get settings => 'Einstellungen';

  @override
  String get share => 'Teilen';

  @override
  String get submitButtonText => 'Absenden';

  @override
  String get summary => 'Zusammenfassung';

  @override
  String totalFilesCount(Object number) {
    return 'Gesamtzahl der Dateien: $number';
  }

  @override
  String get uploadImages => 'Bilder hochladen';

  @override
  String get noData => 'Keine Daten';

  @override
  String get fieldIsRequired => 'Dieses Feld ist erforderlich';

  @override
  String get jiraInstruction => '1. Gehen Sie auf Ihre Jira-Website.\n2. Klicken Sie auf Ihr Profil-Avatar in der unteren linken Ecke.\n3. Klicken Sie auf Profil.\n4. Klicken Sie auf Ihr Konto verwalten.\n5. Wählen Sie Sicherheit.\n6. Scrollen Sie nach unten zu API-Token-Verwaltung und klicken Sie darauf.\n7. Generieren Sie ein Token, dann kopieren und fügen Sie es ein.';

  @override
  String get projectDomain => 'Projektdomäne';

  @override
  String get userEmail => 'E-Mail';

  @override
  String get projectWasSelected => 'Projekt ausgewählt';

  @override
  String get issueCreated => 'Problem erstellt';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get description => 'Beschreibung';
}
