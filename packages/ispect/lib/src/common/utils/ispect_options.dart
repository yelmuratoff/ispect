// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/talker_action_item.dart';

final class ISpectOptions {
  const ISpectOptions({
    this.locale = const Locale('en'),
    this.actionItems = const [],
    this.panelItems = const [],
    this.panelButtons = const [],
  });

  final Locale locale;
  final List<TalkerActionItem> actionItems;

  final List<
      ({
        IconData icon,
        bool enableBadge,
        void Function(BuildContext context) onTap,
      })> panelItems;

  final List<
      ({
        IconData icon,
        String label,
        void Function(BuildContext context) onTap,
      })> panelButtons;

  ISpectOptions copyWith({
    Locale? locale,
    String? googleAiToken,
    List<TalkerActionItem>? actionItems,
    List<
            ({
              IconData icon,
              bool enableBadge,
              void Function(BuildContext context) onTap,
            })>?
        panelItems,
    List<
            ({
              IconData icon,
              String label,
              void Function(BuildContext context) onTap,
            })>?
        panelButtons,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        actionItems: actionItems ?? this.actionItems,
        panelItems: panelItems ?? this.panelItems,
        panelButtons: panelButtons ?? this.panelButtons,
      );
}
