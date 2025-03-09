// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ISpectJiraLocalizationEs extends ISpectJiraLocalization {
  ISpectJiraLocalizationEs([String locale = 'es']) : super(locale);

  @override
  String get successfullyAuthorized => 'Has autorizado exitosamente';

  @override
  String get pleaseCheckAuthCred => 'Ocurrió un error. Por favor, verifica nuevamente tus credenciales de autorización.';

  @override
  String get pickedImages => 'Imágenes seleccionadas';

  @override
  String get pleaseAuthToJira => 'Por favor, autoriza en Jira';

  @override
  String get pleaseSelectYourProject => 'Ahora, por favor, selecciona tu proyecto';

  @override
  String get addingAttachmentsToIssue => 'Añadiendo adjuntos al problema';

  @override
  String get addingStatusToIssue => 'Añadiendo estado al problema';

  @override
  String get apiToken => 'Token de API';

  @override
  String get attachmentsAdded => 'Adjuntos añadidos exitosamente';

  @override
  String get authorize => 'Autorizar';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get changeProject => 'Cambiar proyecto';

  @override
  String get createIssue => 'Crear problema';

  @override
  String get createJiraIssue => 'Crear problema en Jira';

  @override
  String get creatingIssue => 'Creando problema';

  @override
  String get finished => 'Finalizado';

  @override
  String get fix => 'Reportar';

  @override
  String get retry => 'Reintentar';

  @override
  String get selectAssignee => 'Seleccionar asignado';

  @override
  String get selectBoard => 'Seleccionar tablero';

  @override
  String get selectIssueType => 'Seleccionar tipo de problema';

  @override
  String get selectLabel => 'Seleccionar etiqueta';

  @override
  String get selectPriority => 'Seleccionar prioridad';

  @override
  String get selectSprint => 'Seleccionar sprint';

  @override
  String get selectStatus => 'Seleccionar estado';

  @override
  String get sendIssue => 'Enviar problema';

  @override
  String get settings => 'Configuraciones';

  @override
  String get share => 'Compartir';

  @override
  String get submitButtonText => 'Enviar';

  @override
  String get summary => 'Resumen';

  @override
  String totalFilesCount(Object number) {
    return 'Cantidad total de archivos: $number';
  }

  @override
  String get uploadImages => 'Subir imágenes';

  @override
  String get noData => 'Sin datos';

  @override
  String get fieldIsRequired => 'Este campo es obligatorio';

  @override
  String get jiraInstruction => '1. Ve a tu sitio de Jira.\n2. Haz clic en tu avatar de perfil en la esquina inferior izquierda.\n3. Haz clic en Perfil.\n4. Haz clic en Administrar tu cuenta.\n5. Selecciona Seguridad.\n6. Desplázate hacia abajo hasta la gestión de tokens de API y haz clic en ello.\n7. Genera un token, luego cópialo y pégalo.';

  @override
  String get projectDomain => 'Dominio del proyecto';

  @override
  String get userEmail => 'Correo electrónico';

  @override
  String get projectWasSelected => 'Proyecto seleccionado';

  @override
  String get issueCreated => 'Problema creado';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get description => 'Descripción';
}
