import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations.dart';

export 'generated/ispect_localizations.dart';

/// Localization class which is used to localize app.
/// This class provides handy methods and tools.
final class ISpectLocalization {
  const ISpectLocalization._({required this.locale});

  /// List of supported locales.
  static List<Locale> get supportedLocales =>
      ISpectGeneratedLocalization.supportedLocales;

  static const _delegate = ISpectGeneratedLocalization.delegate;

  /// List of localization delegates.
  static List<LocalizationsDelegate<void>> get localizationDelegates => [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        _delegate,
      ];

  static ISpectLocalization? get current => _current;

  static ISpectLocalization? _current;

  /// Locale which is currently used.
  final Locale locale;

  /// Computes the default locale.
  ///
  /// This is the locale that is used when no locale is specified.
  static Locale computeDefaultLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;

    if (_delegate.isSupported(locale)) return locale;

    return const Locale('en');
  }

  /// Obtain `ISpectAppLocalizations` instance from `BuildContext`.
  static ISpectGeneratedLocalization of(BuildContext context) {
    debugCheckHasISpectAppLocalizations(context);
    return Localizations.of<ISpectGeneratedLocalization>(
      context,
      ISpectGeneratedLocalization,
    )!;
  }
}

bool debugCheckHasISpectAppLocalizations(BuildContext context) {
  assert(() {
    if (Localizations.of<ISpectGeneratedLocalization>(
          context,
          ISpectGeneratedLocalization,
        ) ==
        null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No ISpectGeneratedLocalization found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require ISpectAppLocalizations '
          'to be provided by a Localizations widget ancestor.',
        ),
        ErrorDescription(
          'Localizations are used to generate many different messages, labels, '
          'and abbreviations which are used by the feedback library.',
        ),
        ...context.describeMissingAncestor(
          expectedAncestorType: ISpectGeneratedLocalization,
        ),
      ]);
    }
    return true;
  }());
  return true;
}
