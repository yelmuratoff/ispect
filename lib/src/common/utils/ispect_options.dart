// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/talker_action_item.dart';
import 'package:ispect/src/features/inspector/src/widgets/panel/panel_item.dart';

final class ISpectOptions {
  const ISpectOptions({
    required this.locale,
    this.googleAiToken,
    this.actionItems = const [],
    this.panelItems = const [],
    this.panelButtons = const [],
  });

  final Locale locale;
  final String? googleAiToken;
  final List<TalkerActionItem> actionItems;
  final List<ISpectPanelItem> panelItems;
  final List<ISpectPanelButton> panelButtons;

  ISpectOptions copyWith({
    Locale? locale,
    String? googleAiToken,
    List<TalkerActionItem>? actionItems,
    List<ISpectPanelItem>? panelItems,
    List<ISpectPanelButton>? panelButtons,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        googleAiToken: googleAiToken ?? this.googleAiToken,
        actionItems: actionItems ?? this.actionItems,
        panelItems: panelItems ?? this.panelItems,
        panelButtons: panelButtons ?? this.panelButtons,
      );
}
