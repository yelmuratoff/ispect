import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

/// Localization helper for ISpect.
///
/// The canonical API is [delegate], which returns ISpect's own localization
/// delegate (used by the debug-only screens, panels, log viewer) merged with
/// the host app's delegates. Material/Cupertino/Widgets globals are owned by
/// the host app and must not be mutated by an ISpect helper, especially in
/// release builds where ISpect is otherwise inert.
///
/// Typical usage:
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: [
///     GlobalMaterialLocalizations.delegate,
///     GlobalCupertinoLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///     ...ISpectLocalizations.delegate(),
///   ],
/// )
/// ```
final class ISpectLocalizations {
  /// Returns ISpect's localization delegate concatenated with [delegates].
  ///
  /// When `kISpectEnabled` is `false`, returns [delegates] unchanged so the
  /// helper is a true no-op in release builds.
  static List<LocalizationsDelegate<Object>> delegate({
    List<LocalizationsDelegate<Object>> delegates = const [],
  }) {
    if (!kISpectEnabled) return delegates;
    return [ISpectGeneratedLocalization.delegate, ...delegates];
  }

  /// Legacy helper that injects `GlobalMaterialLocalizations`,
  /// `GlobalCupertinoLocalizations`, and `GlobalWidgetsLocalizations` along
  /// with ISpect's delegate.
  ///
  /// Kept for compatibility with the pre-`5.0.0-dev44` quick-start. Migrate to
  /// [delegate] and add the three Globals to your own
  /// `localizationsDelegates` list.
  @Deprecated(
    "Use ISpectLocalizations.delegate(). Owning the host app's "
    "Material/Cupertino/Widgets globals is the host's responsibility — the "
    'helper should not mutate the localization stack, especially in release '
    'builds. Add the three Global*Localizations.delegate entries to your own '
    'localizationsDelegates list and spread ...ISpectLocalizations.delegate() '
    'after them. Will be removed in 6.0.0.',
  )
  static List<LocalizationsDelegate<Object>> delegates({
    List<LocalizationsDelegate<Object>> delegates = const [],
  }) {
    if (!kISpectEnabled) {
      return [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...delegates,
      ];
    }
    return [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      ISpectGeneratedLocalization.delegate,
      ...delegates,
    ];
  }
}
