/// HTTP authentication scheme prefixes (Bearer, Basic, Digest, etc.).
final RegExp schemeRegex = RegExp(
  r'^(Bearer|Basic|Digest|NTLM|Negotiate|OAuth|HOBA|Mutual|SCRAM-SHA-\d+)\s+',
  caseSensitive: false,
);

/// JSON Web Token (three dot-separated Base64URL segments).
final RegExp jwtRegex = RegExp(
  r'^[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}$',
);

/// Well-known token prefixes from popular services.
///
/// Covers: GitHub PATs (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`),
/// Slack (`xox[baprs]-`), GitLab (`glpat-`), OpenAI (`sk-`),
/// Groq (`gsk_`), AWS access keys (`AKIA`), Stripe (`sk_live_`, `pk_live_`,
/// `sk_test_`, `pk_test_`, `rk_live_`, `rk_test_`),
/// Anthropic (`sk-ant-`), Google AI (`AIza`), Supabase (`sbp_`),
/// npm (`npm_`), PyPI (`pypi-`), and generic `pat_` prefixes.
final RegExp tokenPrefixRegex = RegExp(
  '^('
  'gh[pousr]_|'
  'xox[baprs]-|'
  'glpat-|'
  'sk-ant-|'
  'sk-|'
  'gsk_|'
  'AKIA[A-Z0-9]|'
  '(?:sk|pk|rk)_(?:live|test)_|'
  'AIza|'
  'sbp_|'
  'npm_|'
  'pypi-|'
  'pat_'
  ')',
);

/// Characters valid in standard or URL-safe Base64.
final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=_-]+$');

/// Any whitespace character (used to sanitize before Base64 checks).
final RegExp whitespaceRegex = RegExp(r'\s');

/// HTTP(S) URLs embedded in free-form text (error messages, logs, etc.).
final RegExp urlPattern = RegExp(r'https?://[^\s,\]}>)]+');

/// Header key name requiring special cookie-aware masking (case-insensitive
/// comparison by caller).
const String cookieHeaderKey = 'cookie';
