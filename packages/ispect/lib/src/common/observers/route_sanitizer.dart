import 'package:ispectify/ispectify.dart';

/// Returns a bounded scalar route diagnostic without invoking caller code.
String sanitizeRouteDiagnosticText(
  String value, {
  bool enableRedaction = true,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) {
  resourceLimits.validate();
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final prepared = LogExportOutput.boundJsonValue(
    value,
    resourceLimits: resourceLimits,
    replaceOversizedStrings: redactionActive,
  );
  if (prepared is! String) return defaultPlaceholder;
  if (!redactionActive) return prepared;

  final redacted = ISpectRedaction.service.redactForExport(
    prepared,
    resourceLimits: resourceLimits,
  );
  final boundedRedacted = LogExportOutput.boundJsonValue(
    redacted,
    resourceLimits: resourceLimits,
    replaceOversizedStrings: true,
  );
  return boundedRedacted is String && boundedRedacted.isNotEmpty
      ? boundedRedacted
      : defaultPlaceholder;
}

/// Reduces a route label to its path, dropping query and fragment values.
///
/// The path is bounded but never content-redacted; everything after the first
/// `?` or `#` is replaced. Pass [enableRedaction] as false only for an
/// explicit controlled-debugging opt-out.
String sanitizeRouteDiagnosticName(
  String name, {
  bool enableRedaction = true,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) {
  resourceLimits.validate();
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final prepared = LogExportOutput.boundJsonValue(
    name,
    resourceLimits: resourceLimits,
    replaceOversizedStrings: redactionActive,
  );
  if (prepared is! String || prepared.isEmpty) return defaultPlaceholder;
  if (!redactionActive) return prepared;

  final queryIndex = prepared.indexOf('?');
  final fragmentIndex = prepared.indexOf('#');
  final boundaryCandidates = [
    if (queryIndex >= 0) queryIndex,
    if (fragmentIndex >= 0) fragmentIndex,
  ];
  if (boundaryCandidates.isEmpty) return prepared;

  final boundary = boundaryCandidates.reduce((a, b) => a < b ? a : b);
  return '${prepared.substring(0, boundary)}'
      '${prepared[boundary]}$defaultPlaceholder';
}

/// Returns bounded route arguments with sensitive fields and values masked.
///
/// Caller code is never invoked: the value is bounded structurally, then
/// `RedactionService` masks by field name and by content, so an argument map
/// keeps the shape a reader needs while a credential inside it does not
/// survive. Pass [enableRedaction] as false only for an explicit
/// controlled-debugging opt-out.
Object? sanitizeRouteDiagnosticArguments(
  Object? arguments, {
  bool enableRedaction = true,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) {
  if (arguments == null) return null;
  resourceLimits.validate();
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final prepared = LogExportOutput.boundJsonValue(
    arguments,
    resourceLimits: resourceLimits,
    replaceOversizedStrings: redactionActive,
  );
  if (!redactionActive) return prepared;

  final redacted = ISpectRedaction.service.redactForExport(
    prepared,
    resourceLimits: resourceLimits,
  );
  return LogExportOutput.boundJsonValue(
    redacted,
    resourceLimits: resourceLimits,
    replaceOversizedStrings: true,
  );
}
