import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/talker_action_item.dart';

final class ISpectOptions {
  const ISpectOptions({
    required this.locale,
    this.actionItems = const [],
  });
  final Locale locale;
  final List<TalkerActionItem> actionItems;

  ISpectOptions copyWith({
    Locale? locale,
    List<TalkerActionItem>? actionItems,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        actionItems: actionItems ?? this.actionItems,
      );
}
