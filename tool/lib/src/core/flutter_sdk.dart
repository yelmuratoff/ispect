import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';
import 'publish.dart';

/// The FVM config file that pins the repository's Flutter SDK.
const String flutterPinFile = '.fvmrc';

/// Reads the Flutter release that [flutterPinFile] in [repoRoot] pins.
///
/// Returns `null` when the repository has no [flutterPinFile]. Throws
/// [FlutterPinException] when the file is not a JSON object whose `flutter`
/// field names an exact release.
Version? readFlutterPin(String repoRoot) {
  final file = File(p.join(repoRoot, flutterPinFile));
  if (!file.existsSync()) {
    return null;
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw FlutterPinException(
        '$flutterPinFile is not valid JSON: ${e.message}');
  }
  if (decoded case {'flutter': final String pinned}) {
    try {
      return Version.parse(pinned);
    } on FormatException {
      throw FlutterPinException(
        "$flutterPinFile pins '$pinned'; pin an exact Flutter release such "
        'as 3.47.5',
      );
    }
  }
  throw const FlutterPinException(
    '$flutterPinFile has no "flutter" release',
  );
}

/// [ProcessRunner] that starts `flutter` and `dart` from the Flutter SDK
/// pinned in [flutterPinFile], and every other executable through a delegate.
///
/// FVM links the pinned SDK at `.fvm/versions/<release>` when `fvm install` or
/// `fvm use` runs in the repository. Until it does, and in a repository with
/// no pin, both names resolve on PATH, as on CI, where the setup step installs
/// the pinned release.
final class PinnedFlutterRunner implements ProcessRunner {
  const PinnedFlutterRunner._(this._sdkBin, this._delegate);

  /// Resolves the SDK pinned in [repoRoot].
  ///
  /// Throws [FlutterPinException] when [flutterPinFile] is malformed.
  factory PinnedFlutterRunner.forRepo(
    String repoRoot, {
    ProcessRunner delegate = const SystemProcessRunner(),
  }) {
    final pin = readFlutterPin(repoRoot);
    final bin = pin == null
        ? null
        : p.join(repoRoot, '.fvm', 'versions', '$pin', 'bin');
    final linked = bin != null && File(p.join(bin, 'flutter')).existsSync();
    return PinnedFlutterRunner._(linked ? bin : null, delegate);
  }

  static const Set<String> _sdkExecutables = {'flutter', 'dart'};

  final String? _sdkBin;
  final ProcessRunner _delegate;

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    final bin = _sdkBin;
    final resolved = bin != null && _sdkExecutables.contains(executable)
        ? p.join(bin, executable)
        : executable;
    return _delegate.run(
      resolved,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}
