import 'dart:developer' as developer;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/service_extensions/service_extension_handler.dart';

/// Read-only Dart VM service extensions over the ISpect log history.
///
/// Debugging tools and AI agents connected to the VM service (DevTools, an
/// MCP server, a custom script) call these methods to inspect captured
/// diagnostics. Every log record leaves through [LogExporter.toJsonLines], so
/// responses carry the same redaction and size limits as a JSON Lines export.
///
/// Methods:
/// - [getSummary]: entry and level counts, top log keys, recent errors.
/// - [getLogs]: compact entries filtered by `minLevel`, `keys` (comma
///   separated), and `query`; `limit` caps the page (default [defaultLimit],
///   max [maxLimit]). Without a cursor it returns the newest matches and
///   `hasMore` reports older ones; pass the first returned `id` as
///   `beforeId` to page back. With `afterId` it returns the matches logged
///   after that entry and `hasMore` reports newer ones, so polling with the
///   returned `cursor` streams new logs. `query` matches captured values
///   before export redaction, so a hit can come from a value the response
///   masks.
/// - [getLog]: the `level` and the full redacted JSON Lines record of `id`.
/// - [getTrace]: every entry whose correlation or transaction ID equals `id`,
///   such as the request, response, and error of one HTTP call.
///
/// Invalid parameters answer with an `invalidParams` error whose message
/// says how to correct the call.
///
/// Registration is a no-op unless `ISPECT_ENABLED` is set at compile time.
abstract final class ISpectServiceExtensions {
  static const protocolVersion = 1;

  static const getSummary = 'ext.ispect.getSummary';
  static const getLogs = 'ext.ispect.getLogs';
  static const getLog = 'ext.ispect.getLog';
  static const getTrace = 'ext.ispect.getTrace';

  static const defaultLimit = 50;
  static const maxLimit = 200;

  static ISpectLogger? Function()? _resolveLogger;

  /// Registers the extensions in the current isolate.
  ///
  /// [resolveLogger] is read on every call, so a replaced or disposed logger
  /// is picked up without re-registering; returning `null` answers with a
  /// "not initialized" error. A later call replaces [resolveLogger].
  static void register(ISpectLogger? Function() resolveLogger) {
    if (!kISpectEnabled) return;
    final alreadyRegistered = _resolveLogger != null;
    _resolveLogger = resolveLogger;
    if (alreadyRegistered) return;
    for (final method in ServiceExtensionHandler.methods) {
      developer.registerExtension(
        method,
        (method, parameters) async => ServiceExtensionHandler.handle(
          method,
          parameters,
          logger: _resolveLogger?.call(),
        ),
      );
    }
  }
}
