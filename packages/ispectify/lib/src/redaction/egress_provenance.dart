import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:meta/meta.dart';

@immutable
final class _EgressRedaction {
  const _EgressRedaction(this.service, this.resourceLimits);

  final RedactionService service;
  final DiagnosticResourceLimits resourceLimits;
}

final Expando<_EgressRedaction> _egressRedaction =
    Expando<_EgressRedaction>('ISpectLogData.egressRedaction');

@internal
void markExportRedacted(
  ISpectLogData data,
  RedactionService service,
  DiagnosticResourceLimits resourceLimits,
) {
  _egressRedaction[data] = _EgressRedaction(service, resourceLimits);
}

// Compares the service by identity, not equality: RedactionService has no
// value equality, so a reconfigured policy must re-redact.
@internal
bool isExportRedacted(
  ISpectLogData data, {
  required RedactionService service,
  required DiagnosticResourceLimits resourceLimits,
}) {
  final recorded = _egressRedaction[data];
  if (recorded == null) return false;
  return identical(recorded.service, service) &&
      recorded.resourceLimits == resourceLimits;
}
