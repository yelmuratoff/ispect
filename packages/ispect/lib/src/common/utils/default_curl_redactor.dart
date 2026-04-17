import 'package:ispectify/ispectify.dart';

/// Lazy singleton [RedactionService] used by UI copy-as-curl actions to
/// strip sensitive headers (Authorization, Cookie, X-API-Key, …) and
/// payload values before the cURL string lands in the clipboard or a bug
/// report.
///
/// The instance is configured with the package defaults
/// ([defaultSensitiveKeys] / [defaultFullyMaskedKeys]). UI call sites that
/// already own a project-specific [RedactionService] should pass it
/// directly instead of going through this helper.
RedactionService get defaultCurlRedactor =>
    _defaultCurlRedactor ??= RedactionService();

RedactionService? _defaultCurlRedactor;
