/// HTTP authentication scheme prefixes (Bearer, Basic, Digest, etc.).
final RegExp schemeRegex = RegExp(
  r'^(Bearer|Basic|Digest|NTLM|Negotiate|OAuth|HOBA|Mutual|SCRAM-SHA-\d+)\s+',
  caseSensitive: false,
);

/// JSON Web Token (three dot-separated Base64URL segments).
final RegExp jwtRegex = RegExp(
  r'^[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}$',
);

/// Well-known token prefixes (GitHub PATs, Slack tokens, etc.).
final RegExp tokenPrefixRegex = RegExp('^(ghp_|pat_|xox[baprs]-)');

/// Characters valid in standard or URL-safe Base64.
final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=_-]+$');

/// Any whitespace character (used to sanitize before Base64 checks).
final RegExp whitespaceRegex = RegExp(r'\s');
