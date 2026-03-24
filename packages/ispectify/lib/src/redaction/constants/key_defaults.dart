/// The canonical set of sensitive key names used for redaction across all
/// ispect packages. This is the **single source of truth** — other packages
/// (e.g. `ispectify_db`) reference this constant instead of maintaining
/// their own lists.
const Set<String> defaultSensitiveKeys = <String>{
  // Authentication & Authorization
  'authorization',
  'proxy-authorization',
  'x-api-key',
  'api-key',
  'apikey',
  'token',
  'access_token',
  'refresh_token',
  'id_token',
  'password',
  'secret',
  'client-secret',
  'client_secret',
  'private-key',
  'private_key',
  'set-cookie',
  'cookie',

  // Personal Identification Numbers
  'ssn',
  'social_security',
  'social-security',
  'social_security_number',
  'socialsecuritynumber',
  'national_id',
  'nationalid',
  'national-id',
  'passport',
  'passport_number',
  'passportnumber',
  'passport-number',
  'drivers_license',
  'driverslicense',
  'drivers-license',
  'driver_license',
  'driverlicense',
  'driver-license',
  'license_number',
  'licensenumber',
  'license-number',

  // Financial Information
  'credit_card',
  'creditcard',
  'credit-card',
  'card_number',
  'card_expire',
  'cardexpire',
  'cardnumber',
  'card-number',
  'cc_number',
  'ccnumber',
  'cc-number',
  'cvv',
  'cvc',
  'cvv2',
  'card_cvv',
  'cardcvv',
  'security_code',
  'securitycode',
  'security-code',
  'bank_account',
  'bankaccount',
  'bank-account',
  'account_number',
  'accountnumber',
  'account-number',
  'routing_number',
  'routingnumber',
  'routing-number',
  'iban',
  'swift',
  'swift_code',
  'swiftcode',
  'swift-code',
  'bic',

  // Cryptocurrency
  'wallet',
  'wallet_address',
  'walletaddress',
  'wallet-address',

  // Personal Contact Information (context-dependent)
  'phone',
  'phone_number',
  'phonenumber',
  'phone-number',
  'mobile_number',
  'mobilenumber',
  'mobile-number',
  'mobile_phone',
  'mobilephone',
  'mobile-phone',
  'cell_phone',
  'cellphone',
  'cell-phone',
  'cell_number',
  'cellnumber',
  'cell-number',

  // Location / Address (specific fields, not generic 'address')
  'postal_code',
  'postalcode',
  'postal-code',
  'zip_code',
  'zipcode',
  'zip-code',
  'street_address',
  'streetaddress',
  'street-address',
};

/// Backward-compatible alias for [defaultSensitiveKeys].
@Deprecated('Use defaultSensitiveKeys instead')
const Set<String> kDefaultSensitiveKeys = defaultSensitiveKeys;

/// Regex patterns that match sensitive key name fragments.
///
/// Used alongside [defaultSensitiveKeys] for fuzzy matching — the Set provides
/// O(1) exact matches while these patterns catch variations like
/// `user_token_v2` or `auth-token-key`.
final List<RegExp> defaultSensitiveKeyPatterns = <RegExp>[
  // Authentication patterns
  RegExp(r'(?:^|[_\-])token(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])secret(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])pass(?:word)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])key(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])auth(?:$|[_\-])', caseSensitive: false),

  // Personal identification patterns
  RegExp(r'(?:^|[_\-])ssn(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])social[_\-]?security(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])passport(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])drivers?[_\-]?license(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])national[_\-]?id(?:$|[_\-])', caseSensitive: false),

  // Financial patterns
  RegExp(r'(?:^|[_\-])credit[_\-]?card(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])card[_\-]?num(?:ber)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cvv[0-9]?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cvc(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])bank[_\-]?account(?:$|[_\-])', caseSensitive: false),
  RegExp(
    r'(?:^|[_\-])routing[_\-]?num(?:ber)?(?:$|[_\-])',
    caseSensitive: false,
  ),
  RegExp(
    r'(?:^|[_\-])account[_\-]?num(?:ber)?(?:$|[_\-])',
    caseSensitive: false,
  ),
  RegExp(r'(?:^|[_\-])iban(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])swift(?:$|[_\-])', caseSensitive: false),

  // Cryptocurrency patterns
  RegExp(r'(?:^|[_\-])wallet(?:$|[_\-])', caseSensitive: false),

  // Contact information patterns
  RegExp(r'(?:^|[_\-])phone(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])mobile[_\-](?:num|phone)', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cell[_\-]?(?:phone|num)', caseSensitive: false),
];

/// Keys whose values are always fully replaced with placeholder (no partial
/// masking), regardless of whether the key is also in [defaultSensitiveKeys].
const Set<String> defaultFullyMaskedKeys = <String>{
  'filename',
};
