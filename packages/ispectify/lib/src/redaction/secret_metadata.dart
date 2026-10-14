import 'package:ispectify/src/redaction/constants/credential_markers.dart';
import 'package:ispectify/src/redaction/constants/detection_patterns.dart';

enum SecretMetadataQualifier { flag, quantity, descriptor, version, instant }

const Map<String, SecretMetadataQualifier> _metadataQualifiers =
    <String, SecretMetadataQualifier>{
  'algorithm': SecretMetadataQualifier.descriptor,
  'count': SecretMetadataQualifier.quantity,
  'enabled': SecretMetadataQualifier.flag,
  'format': SecretMetadataQualifier.descriptor,
  'length': SecretMetadataQualifier.quantity,
  'method': SecretMetadataQualifier.descriptor,
  'required': SecretMetadataQualifier.flag,
  'scheme': SecretMetadataQualifier.descriptor,
  'set': SecretMetadataQualifier.flag,
  'size': SecretMetadataQualifier.quantity,
  'ttl': SecretMetadataQualifier.quantity,
  'type': SecretMetadataQualifier.descriptor,
  'verified': SecretMetadataQualifier.flag,
  'version': SecretMetadataQualifier.version,
};

const String _presenceQualifier = 'has_';

const Map<String, SecretMetadataQualifier> _metadataQualifierPairs =
    <String, SecretMetadataQualifier>{
  'expires_at': SecretMetadataQualifier.instant,
  'expires_in': SecretMetadataQualifier.quantity,
};

const int _maxMetadataTextLength = 32;

final RegExp _booleanValuePattern = RegExp(
  r'^(?:true|false)$',
  caseSensitive: false,
);

final RegExp _numberValuePattern = RegExp(r'^-?\d+(?:\.\d+)?$');

final Set<String> _descriptorWords = <String>{
  for (final scheme in httpAuthSchemes) scheme.toLowerCase(),
  'hmac',
  'jwt',
  'mac',
  'none',
  'pkce',
  'plain',
};

final RegExp _uppercaseDescriptorPattern = RegExp(
  r'^[A-Z][A-Z0-9]{0,15}(?:[._-][A-Z0-9]{1,16})*$',
);

final RegExp _mediaTypePattern = RegExp(
  '^(?:application|audio|font|image|message|model|multipart|text|video)'
  r'/[a-z0-9][a-z0-9.+-]{0,24}$',
  caseSensitive: false,
);

final RegExp _versionValuePattern = RegExp(
  r'^[A-Za-z]{0,3}\d+(?:[A-Za-z]{1,3}\d+)*(?:[._+-][A-Za-z0-9]{1,16})*$',
);

final RegExp _instantValuePattern = RegExp(
  r'^\d{4}-\d{2}-\d{2}'
  r'(?:[Tt ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:[Zz]|[+-]\d{2}:?\d{2})?)?$',
);

/// The qualifier that marks the snake-case [canonicalKey] as describing a
/// secret rather than holding it, such as `token_type`, `email_verified`, or
/// `token_expires_in`, or a key starting with the presence qualifier `has_`.
SecretMetadataQualifier? secretMetadataQualifier(String canonicalKey) {
  final separator = canonicalKey.lastIndexOf('_');
  if (separator < 0) return null;
  if (canonicalKey.startsWith(_presenceQualifier)) {
    return SecretMetadataQualifier.flag;
  }
  final qualifier = _metadataQualifiers[canonicalKey.substring(separator + 1)];
  if (qualifier != null || separator == 0) return qualifier;
  final previous = canonicalKey.lastIndexOf('_', separator - 1);
  if (previous < 0) return null;
  return _metadataQualifierPairs[canonicalKey.substring(previous + 1)];
}

bool isSecretMetadataValue(SecretMetadataQualifier qualifier, Object? value) {
  if (value == null || value is bool) return true;
  if (value is num) {
    return qualifier != SecretMetadataQualifier.flag ||
        value == 0 ||
        value == 1;
  }
  if (value is! String) return false;
  final text = value.trim();
  if (text.length > _maxMetadataTextLength) return false;
  if (_booleanValuePattern.hasMatch(text)) return true;
  return switch (qualifier) {
    SecretMetadataQualifier.flag => false,
    SecretMetadataQualifier.quantity => _numberValuePattern.hasMatch(text),
    SecretMetadataQualifier.descriptor => _isDescriptorValue(text),
    SecretMetadataQualifier.version => _versionValuePattern.hasMatch(text),
    SecretMetadataQualifier.instant =>
      _numberValuePattern.hasMatch(text) || _instantValuePattern.hasMatch(text),
  };
}

bool _isDescriptorValue(String text) {
  if (_descriptorWords.contains(text.toLowerCase())) return true;
  if (_mediaTypePattern.hasMatch(text)) return true;
  return _uppercaseDescriptorPattern.hasMatch(text) &&
      !tokenPrefixRegex.hasMatch(text);
}
