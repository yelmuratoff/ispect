// ignore_for_file: public_member_api_docs

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/src/features/snapshot/src/l18n/translation.dart';

/// Provides localizations for this library
class FeedbackLocalization extends StatelessWidget {
  /// Creates a [FeedbackLocalization].
  const FeedbackLocalization({
    required this.child,
    super.key,
    this.delegates,
    this.localeOverride,
  });

  final Widget child;
  final List<LocalizationsDelegate<dynamic>>? delegates;
  final Locale? localeOverride;

  List<LocalizationsDelegate<dynamic>> get _localizationsDelegates => [
        ...GlobalMaterialLocalizations.delegates,
        GlobalFeedbackLocalizationsDelegate(),
      ];
  @override
  Widget build(BuildContext context) {
    final mergedDelegates = _localizationsDelegates.toList(growable: true);
    if (delegates != null) {
      mergedDelegates.insertAll(0, delegates!);
    }

    return Localizations(
      delegates: mergedDelegates,
      locale: localeOverride ?? View.maybeOf(context)?.platformDispatcher.locale ?? const Locale('en'),
      child: child,
    );
  }
}
