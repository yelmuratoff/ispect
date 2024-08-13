import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/talker_action_item.dart';
import 'package:ispect/src/features/inspector/src/widgets/panel/panel_item.dart';

final class ISpectOptions {
  const ISpectOptions({
    required this.locale,
    this.actionItems = const [],
    this.panelItems = const [],
  });
  final Locale locale;
  final List<TalkerActionItem> actionItems;
  final List<ISpectPanelItem> panelItems;

  ISpectOptions copyWith({
    Locale? locale,
    List<TalkerActionItem>? actionItems,
    List<ISpectPanelItem>? panelItems,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        actionItems: actionItems ?? this.actionItems,
        panelItems: panelItems ?? this.panelItems,
      );
}
