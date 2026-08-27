/// Rewrites `--option=value` into `--option value`.
///
/// The core entry points parse argv themselves so they stay usable without
/// `package:args`, and they accept only the separated form. `CommandRunner`
/// advertises both, so the CLI layer normalizes before delegating.
///
/// Everything after a bare `--` is passed through untouched.
List<String> normalizeOptionValues(List<String> arguments) {
  final normalized = <String>[];
  var passThrough = false;

  for (final argument in arguments) {
    if (passThrough) {
      normalized.add(argument);
      continue;
    }
    if (argument == '--') {
      passThrough = true;
      normalized.add(argument);
      continue;
    }

    final separator = argument.indexOf('=');
    if (argument.startsWith('--') && separator > 2) {
      normalized
        ..add(argument.substring(0, separator))
        ..add(argument.substring(separator + 1));
      continue;
    }
    normalized.add(argument);
  }

  return normalized;
}
