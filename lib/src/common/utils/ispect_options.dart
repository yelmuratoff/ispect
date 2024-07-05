import 'package:flutter/material.dart';

final class ISpectOptions {
  const ISpectOptions({
    required this.locale,
  });
  final Locale locale;

  ISpectOptions copyWith({
    Locale? locale,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
      );
}
