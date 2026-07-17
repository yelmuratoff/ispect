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
  'passwd',
  'pwd',
  'secret',
  'client-secret',
  'client_secret',
  'private-key',
  'private_key',
  'signature',
  'hmac',
  'set-cookie',
  'cookie',
  'bearer_token',
  'session_id',
  'session_token',
  'session-id',
  'session-token',
  'csrf',
  'csrf_token',
  'csrf-token',
  'x-csrf-token',
  'xsrf',
  'xsrf_token',
  'xsrf-token',
  'x-xsrf-token',
  'mfa_code',
  'mfa-code',
  'totp',
  'otp',
  'one_time_password',
  'verification_code',
  'verification-code',
  'pin_code',
  'pin-code',

  // User Identity (context-dependent)
  'email',
  'e-mail',
  'email_address',
  'username',
  'user_name',
  'login',

  // Device & Push Tokens
  'device_token',
  'device-token',
  'fcm_token',
  'fcm-token',
  'apns_token',
  'apns-token',
  'push_token',
  'push-token',

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
  'dob',
  'date_of_birth',
  'dateofbirth',
  'date-of-birth',

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
  'pan',

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

  // Personal Names (PII)
  'first_name',
  'firstname',
  'first-name',
  'last_name',
  'lastname',
  'last-name',
  'middle_name',
  'middlename',
  'middle-name',
  'full_name',
  'fullname',
  'full-name',
  'given_name',
  'givenname',
  'given-name',
  'family_name',
  'familyname',
  'family-name',
  'maiden_name',
  'maidenname',
  'maiden-name',
  'surname',

  // Demographics & Special-Category PII
  'gender',
  'sex',
  'nationality',
  'ethnicity',
  'religion',
  'sexual_orientation',
  'sexualorientation',
  'sexual-orientation',
  'blood_type',
  'bloodtype',
  'blood-type',

  // Birth Date & Place
  'birthday',
  'birth_date',
  'birthdate',
  'birth-date',
  'place_of_birth',
  'placeofbirth',
  'place-of-birth',
  'birth_place',
  'birthplace',
  'birth-place',

  // Postal Addresses (qualified)
  'home_address',
  'homeaddress',
  'home-address',
  'mailing_address',
  'mailingaddress',
  'mailing-address',
  'billing_address',
  'billingaddress',
  'billing-address',
  'shipping_address',
  'shippingaddress',
  'shipping-address',

  // Tax Identifiers
  'tax_id',
  'taxid',
  'tax-id',
  'taxpayer_id',
  'taxpayerid',
  'taxpayer-id',
  'vat_number',
  'vatnumber',
  'vat-number',
};

/// Backward-compatible alias for [defaultSensitiveKeys].
@Deprecated('Use defaultSensitiveKeys instead. Will be removed in 7.0.0.')
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
  RegExp(
    r'(?:^|[_\-])(?:pass(?:word)?|passwd|pwd)(?:$|[_\-])',
    caseSensitive: false,
  ),
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

  // MFA / OTP / session / device token patterns
  RegExp(
    r'(?:^|[_\-])(?:e[-_]?mail|otp|device[-_]?token|push[-_]?token|session[-_]?(?:id|token)|csrf[-_]?token|mfa[-_]?code)',
    caseSensitive: false,
  ),

  // Cryptocurrency patterns
  RegExp(r'(?:^|[_\-])wallet(?:$|[_\-])', caseSensitive: false),

  // Contact information patterns
  RegExp(r'(?:^|[_\-])phone(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])mobile[_\-](?:num|phone)', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cell[_\-]?(?:phone|num)', caseSensitive: false),
];

/// Keys whose values are always fully replaced with the placeholder (no
/// partial/edge masking), regardless of whether the key is also in
/// [defaultSensitiveKeys].
///
/// Covers credentials, financial account numbers, security codes, government
/// identifiers, personal names, demographics, birth and postal details, and
/// tax identifiers — values where even the first/last characters leak
/// meaningful information. `authorization`/`cookie` are intentionally absent:
/// their structure-aware masking preserves the (non-sensitive) auth scheme and
/// cookie names while masking the secret. Context-dependent contact fields
/// (email, phone, username) also keep edge masking to aid debugging.
const Set<String> defaultFullyMaskedKeys = <String>{
  'filename',

  // Credentials & secrets
  'x-api-key',
  'api-key',
  'apikey',
  'token',
  'access_token',
  'refresh_token',
  'id_token',
  'bearer_token',
  'session_token',
  'session-token',
  'session_id',
  'session-id',
  'password',
  'passwd',
  'pwd',
  'secret',
  'client-secret',
  'client_secret',
  'private-key',
  'private_key',
  'signature',
  'hmac',
  'csrf',
  'csrf_token',
  'csrf-token',
  'x-csrf-token',
  'xsrf',
  'xsrf_token',
  'xsrf-token',
  'x-xsrf-token',
  'mfa_code',
  'mfa-code',
  'totp',
  'otp',
  'one_time_password',
  'verification_code',
  'verification-code',
  'pin_code',
  'pin-code',

  // Device & push tokens
  'device_token',
  'device-token',
  'fcm_token',
  'fcm-token',
  'apns_token',
  'apns-token',
  'push_token',
  'push-token',

  // Government identifiers
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
  'dob',
  'date_of_birth',
  'dateofbirth',
  'date-of-birth',

  // Financial accounts & security codes
  'credit_card',
  'creditcard',
  'credit-card',
  'card_number',
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
  'pan',

  // Cryptocurrency
  'wallet',
  'wallet_address',
  'walletaddress',
  'wallet-address',

  // Personal Names (PII)
  'first_name',
  'firstname',
  'first-name',
  'last_name',
  'lastname',
  'last-name',
  'middle_name',
  'middlename',
  'middle-name',
  'full_name',
  'fullname',
  'full-name',
  'given_name',
  'givenname',
  'given-name',
  'family_name',
  'familyname',
  'family-name',
  'maiden_name',
  'maidenname',
  'maiden-name',
  'surname',

  // Demographics & Special-Category PII
  'gender',
  'sex',
  'nationality',
  'ethnicity',
  'religion',
  'sexual_orientation',
  'sexualorientation',
  'sexual-orientation',
  'blood_type',
  'bloodtype',
  'blood-type',

  // Birth Date & Place
  'birthday',
  'birth_date',
  'birthdate',
  'birth-date',
  'place_of_birth',
  'placeofbirth',
  'place-of-birth',
  'birth_place',
  'birthplace',
  'birth-place',

  // Postal Addresses (qualified)
  'home_address',
  'homeaddress',
  'home-address',
  'mailing_address',
  'mailingaddress',
  'mailing-address',
  'billing_address',
  'billingaddress',
  'billing-address',
  'shipping_address',
  'shippingaddress',
  'shipping-address',

  // Tax Identifiers
  'tax_id',
  'taxid',
  'tax-id',
  'taxpayer_id',
  'taxpayerid',
  'taxpayer-id',
  'vat_number',
  'vatnumber',
  'vat-number',
};

/// Lowercased form of [defaultSensitiveKeys], computed once so callers that
/// build a [RedactionService] with the defaults do not re-lowercase and
/// re-allocate the set on every construction.
final Set<String> defaultSensitiveKeysLower =
    defaultSensitiveKeys.map((e) => e.toLowerCase()).toSet();

/// Lowercased form of [defaultFullyMaskedKeys], computed once. See
/// [defaultSensitiveKeysLower].
final Set<String> defaultFullyMaskedKeysLower =
    defaultFullyMaskedKeys.map((e) => e.toLowerCase()).toSet();
