/// Well-known provider token prefixes, matched case-sensitively at the start
/// of a token.
///
/// [awsAccessKeyIdPrefix] is kept apart because it is followed by an
/// uppercase alphanumeric body rather than a free-form suffix.
const List<String> knownTokenPrefixes = <String>[
  'github_pat_',
  'ghp_',
  'gho_',
  'ghu_',
  'ghs_',
  'ghr_',
  'xoxb-',
  'xoxa-',
  'xoxp-',
  'xoxr-',
  'xoxs-',
  'glpat-',
  'sk-ant-',
  'sk-',
  'gsk_',
  'sk_live_',
  'pk_live_',
  'rk_live_',
  'sk_test_',
  'pk_test_',
  'rk_test_',
  'AIza',
  'sbp_',
  'npm_',
  'pypi-',
  'pat_',
];

/// Prefix of AWS access key IDs.
const String awsAccessKeyIdPrefix = 'AKIA';

/// HTTP authentication scheme names that precede credentials.
const List<String> httpAuthSchemes = <String>[
  'Bearer',
  'Basic',
  'Token',
  'Digest',
  'NTLM',
  'Negotiate',
  'OAuth',
  'HOBA',
  'Mutual',
];

/// Prefix of the `SCRAM-SHA-<bits>` authentication schemes.
const String scramAuthSchemePrefix = 'SCRAM-SHA-';

/// Regex alternation matching any of [knownTokenPrefixes].
final String knownTokenPrefixAlternation =
    knownTokenPrefixes.map(RegExp.escape).join('|');

/// Regex alternation matching any of [httpAuthSchemes] or a SCRAM scheme.
final String httpAuthSchemeAlternation = [
  ...httpAuthSchemes.map(RegExp.escape),
  '${RegExp.escape(scramAuthSchemePrefix)}\\d+',
].join('|');

const Set<String> trailingSegmentOnlyKeys = <String>{'sig'};
