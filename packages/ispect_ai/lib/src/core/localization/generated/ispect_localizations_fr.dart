// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ISpectAILocalizationFr extends ISpectAILocalization {
  ISpectAILocalizationFr([String locale = 'fr']) : super(locale);

  @override
  String get aiChat => 'Chat IA';

  @override
  String get aiWelcomeMessage => 'Bonjour ! Comment puis-je vous aider ?';

  @override
  String get allLogsCopied =>
      'Tous les journaux ont été copiés dans le presse-papiers';

  @override
  String get analyticsLogDesc =>
      'Journal des soumissions d\'événements au service d\'analyse';

  @override
  String get apiToken => 'Jeton API';

  @override
  String get copy => 'Copier';

  @override
  String get data => 'Données';

  @override
  String get statusMessage => 'Statut';

  @override
  String get submitButtonText => 'Soumettre';

  @override
  String get summary => 'Résumé';

  @override
  String get typeMessage => 'Entrez votre demande';

  @override
  String get you => 'Vous';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get retry => 'Réessayer';
}
