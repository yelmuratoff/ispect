import 'package:riverpod/riverpod.dart';

/// Returns a coarse provider label without dispatching through
/// `Object.runtimeType`.
String safeRiverpodProviderTypeLabel(ProviderBase<Object?> _) => 'Provider';

/// Returns a coarse value label using type checks only.
///
/// Unknown caller-owned objects deliberately collapse to `Object`; obtaining
/// their concrete class name would execute the overridable `runtimeType`
/// getter.
String safeRiverpodValueTypeLabel(Object? value) {
  if (value == null) return 'null';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is num) return 'num';
  if (value is Enum) return 'Enum';
  if (value is Map) return 'Map';
  if (value is List) return 'List';
  if (value is Set) return 'Set';
  if (value is Iterable) return 'Iterable';
  if (value is Error) return 'Error';
  if (value is Exception) return 'Exception';
  if (value is StackTrace) return 'StackTrace';
  if (value is Type) return 'Type';
  if (value is Record) return 'Record';
  return 'Object';
}
