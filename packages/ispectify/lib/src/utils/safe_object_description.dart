import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Returns a non-dispatching descriptor for an arbitrary diagnostic object.
///
/// Diagnostics can implement SDK interfaces and override `runtimeType`,
/// `toString`, and detail getters. Type tests are safe, while reading those
/// members is not. The descriptor therefore retains only a coarse type family
/// and never caller-supplied diagnostic text.
String safeDiagnosticDescriptor(Object value) =>
    JsonValueNormalizer.diagnosticDescriptor(value);

/// Converts only closed, non-dispatching scalar families to text.
///
/// Unknown objects deliberately become an opaque marker instead of invoking a
/// caller-controlled formatter.
String? safeScalarText(Object? value) => switch (value) {
      null => null,
      final String text => text,
      final bool primitive => primitive ? 'true' : 'false',
      final num primitive => primitive.toString(),
      final Enum primitive => primitive.name,
      _ => JsonValueNormalizer.unprintableValue,
    };
