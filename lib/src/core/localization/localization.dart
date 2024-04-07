import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/src/core/localization/translations/app_localizations.dart';

/// Localization class which is used to localize app.
/// This class provides handy methods and tools.
final class Localization {
  const Localization._({required this.locale});

  /// List of supported locales.
  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  static const _delegate = AppLocalizations.delegate;

  /// List of localization delegates.
  static List<LocalizationsDelegate<void>> get localizationDelegates => [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        _delegate,
      ];

  static Localization? get current => _current;

  static Localization? _current;

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

  /// Obtain [AppLocalizations] instance from [BuildContext].
  static AppLocalizations of(BuildContext context) {
    debugCheckHasFeedbackLocalizations(context);
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    )!;
  }
}

bool debugCheckHasFeedbackLocalizations(BuildContext context) {
  assert(() {
    if (Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        ) ==
        null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No AppLocalizations found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require AppLocalizations '
          'to be provided by a Localizations widget ancestor.',
        ),
        ErrorDescription(
          'Localizations are used to generate many different messages, labels, '
          'and abbreviations which are used by the feedback library.',
        ),
        ...context.describeMissingAncestor(
          expectedAncestorType: AppLocalizations,
        )
      ]);
    }
    return true;
  }());
  return true;
}
