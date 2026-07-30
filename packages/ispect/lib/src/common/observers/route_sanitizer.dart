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

/// Reduces a route label to a non-content shape.
///
/// Literal segments and query/fragment values are replaced. Declared path
/// parameters retain only their syntactic shape. Pass [enableRedaction] as
/// false only for an explicit controlled-debugging opt-out.
String sanitizeRouteDiagnosticName(
  String name, {
  bool enableRedaction = true,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) {
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final scrubbed = sanitizeRouteDiagnosticText(
    name,
    enableRedaction: enableRedaction,
    resourceLimits: resourceLimits,
  );
  if (!redactionActive) return scrubbed;

  final queryIndex = scrubbed.indexOf('?');
  final fragmentIndex = scrubbed.indexOf('#');
  final boundaryCandidates = [
    if (queryIndex >= 0) queryIndex,
    if (fragmentIndex >= 0) fragmentIndex,
  ];
  final boundary = boundaryCandidates.isEmpty
      ? scrubbed.length
      : boundaryCandidates.reduce((a, b) => a < b ? a : b);
  final path = scrubbed.substring(0, boundary);
  final hasSuffix = boundary < scrubbed.length;

  final safePath = path.split('/').map((segment) {
    if (segment.isEmpty) return segment;
    if (segment.startsWith(':')) return ':param';
    if (segment.startsWith('{') && segment.endsWith('}')) return '{param}';
    return defaultPlaceholder;
  }).join('/');

  return hasSuffix
      ? '$safePath${scrubbed[boundary]}$defaultPlaceholder'
      : safePath;
}

/// Describes route arguments without traversing or stringifying their content.
String summarizeRouteDiagnosticArguments(Object arguments) {
  if (arguments is Map<Object?, Object?>) return 'Map';
  if (arguments is List<Object?>) return 'List';
  if (arguments is Set<Object?>) return 'Set';
  if (arguments is String) return '(String)';
  if (arguments is num || arguments is bool) return '(scalar)';
  return '(Object)';
}
