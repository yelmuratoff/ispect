/// HTTP authentication scheme prefixes (Bearer, Basic, Digest, etc.).
final RegExp schemeRegex = RegExp(
  '^(Bearer|Basic|Token|Digest|NTLM|Negotiate|OAuth|HOBA|Mutual|'
  r'SCRAM-SHA-\d+)\s+',
  caseSensitive: false,
);

/// Any syntactically valid HTTP authentication scheme followed by credentials.
///
/// This broader expression is only used for structurally identified
/// Authorization headers. Applying it to arbitrary strings would classify
/// ordinary prose such as `hello world` as credentials.
final RegExp authorizationSchemeRegex = RegExp(
  r"^([!#$%&'*+\-.^_`|~0-9A-Za-z]+)([ \t]+)\S[^\r\n]*$",
);

/// JSON Web Token (three dot-separated Base64URL segments).
final RegExp jwtRegex = RegExp(
  r'^[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}$',
);

/// Well-known token prefixes from popular services.
///
/// Covers: GitHub PATs (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`,
/// `github_pat_`), Slack (`xox[baprs]-`), GitLab (`glpat-`), OpenAI (`sk-`),
/// Groq (`gsk_`), AWS access keys (`AKIA`), Stripe (`sk_live_`, `pk_live_`,
/// `sk_test_`, `pk_test_`, `rk_live_`, `rk_test_`),
/// Anthropic (`sk-ant-`), Google AI (`AIza`), Supabase (`sbp_`),
/// npm (`npm_`), PyPI (`pypi-`), and generic `pat_` prefixes.
final RegExp tokenPrefixRegex = RegExp(
  '^('
  'github_pat_|'
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

/// Any whitespace character.
final RegExp whitespaceRegex = RegExp(r'\s');

/// Line terminators MIME and PEM use to wrap Base64 payloads.
final RegExp base64LineBreakRegex = RegExp(r'[\r\n]');

/// HTTP(S) and protocol-relative URLs embedded in free-form diagnostic text.
final RegExp urlPattern = RegExp(
  r'''(?:(?:https?:)?//)[^\s<>"']+''',
  caseSensitive: false,
);

/// Header key name requiring special cookie-aware masking (case-insensitive
/// comparison by caller).
const String cookieHeaderKey = 'cookie';
