import 'package:flutter/material.dart';

final class ISpectOptions {
  final Locale locale;

  const ISpectOptions({
    required this.locale,
  });

  ISpectOptions copyWith({
    Locale? locale,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
      );
}
